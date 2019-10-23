import 'dart:ui';

import 'options.dart';

/// This store handles the access to a specific resource (e.g. String) or a
/// bundle (e.g. namespaces) depending on the levels transversed.
///
/// The access is done by [Locale], Namespace, and key in that order.
class ResourceStore {
  ResourceStore([Map<Locale, Map<String, Map<String, Object>>> data])
      : data = data ?? {},
        super();

  final Map<Locale, Map<String, Map<String, Object>>> data;

  /// Attempts to retrieve a value given [Locale] in [options], [namespace],
  /// and [key].
  ///
  /// - [key] cannot be null and it is split by [I18NextOptions.keySeparator]
  ///   when creating a navigation path.
  ///
  /// May return null if not found.
  String retrieve(String namespace, String key, I18NextOptions options) {
    final path = <Object>[options.locale, namespace];
    if (key != null) path.addAll(key.split(options.keySeparator));

    final value = evaluate(path, data);
    return value is String ? value : null;
  }

  /// Given a [path] list, this method navigates through [data] and returns
  /// the last path, or null otherwise.
  static Object evaluate(Iterable<Object> path, Map<Object, Object> data) {
    dynamic object = data;
    for (final current in path) {
      if (object is Map && object.containsKey(current)) {
        object = object[current];
      } else {
        object = null;
        break;
      }
    }
    return object;
  }
}
