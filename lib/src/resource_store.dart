import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils.dart';
import 'options.dart';

/// This store handles the access to a specific resource (e.g. String) or a
/// bundle (e.g. namespaces) depending on the levels transversed.
///
/// The access is done by [Locale], Namespace, and key in that order.
class ResourceStore {
  ResourceStore({Map<Locale, Map<String, dynamic>>? data})
      : _data = data ?? {},
        super();

  final Map<Locale, Map<String, dynamic>> _data;

  /// Registers the [namespace] to the store for the given [locale].
  ///
  /// [locale], [namespace], and [data] cannot be null.
  void addNamespace(
    Locale locale,
    String namespace,
    Map<String, dynamic> data,
  ) {
    _data[locale] ??= {};
    _data[locale]?[namespace] = data;
  }

  /// Removes [namespace] given [locale] from the store.
  void removeNamespace(Locale locale, String namespace) {
    _data[locale]?.remove(namespace);
  }

  /// Unregisters the [locale] from the store and from the [cache].
  Future<void> removeLocale(Locale locale) async {
    _data.remove(locale);
  }

  /// Unregisters all locales from the store and from the [cache].
  Future<void> removeAll() async {
    _data.clear();
  }

  /// Whether [locale] and [namespace] are registered in this store.
  bool isNamespaceRegistered(Locale locale, String namespace) =>
      isLocaleRegistered(locale) && _data[locale]?[namespace] != null;

  /// Whether [locale] is registered in this store.
  bool isLocaleRegistered(Locale locale) => _data[locale] != null;

  /// Attempts to retrieve a value given [Locale] in [options], [namespace],
  /// and [key].
  ///
  /// - [key] cannot be null and it is split by [I18NextOptions.keySeparator]
  ///   when creating a navigation path.
  ///
  /// Returns null if not found.
  String? retrieve(
    Locale locale,
    String namespace,
    String key,
    I18NextOptions options,
  ) {
    final keySeparator = options.keySeparator ?? '.';
    final path = <Object>[
      locale,
      namespace,
      ...key.split(keySeparator),
    ];
    final value = evaluate(path, _data);
    return value is String ? value : null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceStore &&
          runtimeType == other.runtimeType &&
          mapEquals(_data, other._data);

  @override
  int get hashCode => _data.hashCode;
}
