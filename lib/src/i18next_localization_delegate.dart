import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data_sources/localization_data_source.dart';
import 'i18next.dart';
import 'options.dart';
import 'resource_store.dart';

/// A factory for the localized resource [I18Next] that is loaded by a
/// [Localizations] widget.
///
/// See [LocalizationsDelegate] for the base lifecycle calls.
class I18NextLocalizationDelegate extends LocalizationsDelegate<I18Next> {
  I18NextLocalizationDelegate({
    required this.locales,
    required this.dataSource,
    ResourceStore? resourceStore,
    this.options,
  })  : resourceStore = resourceStore ?? ResourceStore(),
        super();

  /// The list of supported locales by this delegate.
  ///
  /// A supported locale example:
  /// If `en_US` is given, then both `en` and `en_US` are supported by this
  /// delegate, and it will load the normalized locale accordingly.
  /// Same if `pt` is given, it will support both `pt` and `pt_BR` locales.
  ///
  /// Supported | Given | Loaded
  /// :--|:--|:--
  /// `en_US` | `en`    | `en_US`
  /// `en_US` | `en_US` | `en_US`
  /// `pt`    | `pt`    | `pt`
  /// `pt`    | `pt_BR` | `pt`
  /// 'jp'    | 'pt'    | errors
  final List<Locale> locales;

  /// The data source that provides the localization data to this delegate.
  final LocalizationDataSource dataSource;

  /// Where the resources are kept and managed.
  final ResourceStore resourceStore;

  /// The options given to the [I18Next] instance.
  final I18NextOptions? options;

  @override
  bool isSupported(Locale locale) =>
      locales.contains(locale) ||
      locales.any((l) => l.languageCode == locale.languageCode);

  @override
  bool shouldReload(I18NextLocalizationDelegate old) {
    return !listEquals(locales, old.locales) ||
        resourceStore != old.resourceStore ||
        dataSource != old.dataSource ||
        options != old.options;
  }

  /// Normalizes [locale] in case it is not fully supported, but a shorter
  /// or specific one might be.
  ///
  /// e.g. if this delegate supports ['en_US', 'pt']:
  ///
  /// - Both 'en_US' and 'en' => 'en_US'
  /// - Both 'pt_BR' and 'pt' => 'pt'
  Locale normalizeLocale(Locale locale) {
    if (!locales.contains(locale)) {
      locale = locales.firstWhere(
        (l) => l.languageCode == locale.languageCode,
        orElse: () => throw Exception('Unsupported locale $locale'),
      );
    }
    return locale;
  }

  @override
  Future<I18Next> load(Locale locale) async {
    locale = normalizeLocale(locale);

    final namespaces = await dataSource.load(locale);
    // TODO: should delete previous locales/namespaces from resource store?
    for (final entry in namespaces.entries) {
      resourceStore.addNamespace(locale, entry.key, entry.value);
    }
    return I18Next(locale, resourceStore, options: options);
  }
}
