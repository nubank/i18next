import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'localization_data_source.dart';

/// A [LocalizationDataSource] that retrieves assets from an [AssetBundle].
class AssetBundleLocalizationDataSource implements LocalizationDataSource {
  AssetBundleLocalizationDataSource({
    this.bundlePath = 'localizations',
    AssetBundle? bundle,
  })  : bundle = bundle ?? rootBundle,
        super();

  /// The path prefixed to the asset when retrieving from the [bundle].
  ///
  /// Defaults to 'localizations'.
  final String bundlePath;

  /// The [AssetBundle] where it retrieves the assets from.
  ///
  /// Defaults no [rootBundle].
  final AssetBundle bundle;

  /// Loads all '.json' localization files declared in [manifest] with
  /// [bundlePath] given a [locale]. The assets themselves must have been
  /// previously declared in `pubspec.yaml`.
  ///
  /// For example, if your project structure is as follows:
  ///
  /// ```
  /// /app
  ///   - l10n
  ///     - en-US/localizations.json
  ///     - pt-BR/localizations.json
  /// ```
  ///
  /// Then the desired [bundlePath] should be `l10n`.
  ///
  /// - [manifest] determines from where the namespaced files will be loaded
  /// from. This file should contain a [Map] where the keys represent the
  /// asset's path. Defaults to 'AssetManifest.json'.
  ///
  /// The end result is a [Map] that contains all the namespaces which are
  /// the file names themselves (case sensitive).
  @override
  Future<Map<String, dynamic>> load(
    Locale locale, {
    String manifest = 'AssetManifest.json',
  }) async {
    assert(manifest.isNotEmpty);

    final assetFiles = await bundle
        .loadString(manifest)
        .then<Map<String, dynamic>>((string) => json.decode(string))
        .then((map) => map.keys);

    /// On every platform you never should try to get the `path.separator`,
    /// because Flutter is fetching all assets in `/` style.
    /// `path.separator` should only be used to handle OS files.
    final bundleLocalePath = '$bundlePath/${locale.toLanguageTag()}';

    final files = assetFiles
        // trailing slash is to guarantee the whole dir matches, otherwise
        // it might allow undesired files
        .where((key) => key.contains('$bundleLocalePath'))
        .where((key) => path.extension(key) == '.json');

    return await loadFromFiles(files);
  }

  Future<Map<String, dynamic>> loadFromFiles(
    Iterable<String> files,
  ) async {
    // TODO: make it case insensitive?
    final namespaces = HashMap<String, dynamic>();
    for (final file in files) {
      // TODO: make this a lazy eval and let loading be handed concurrently?
      final namespace = path.basenameWithoutExtension(file);
      final string = await bundle.loadString(file);
      namespaces[namespace] = jsonDecode(string);
    }
    return namespaces;
  }
}
