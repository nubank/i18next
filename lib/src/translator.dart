import 'dart:ui';

import 'interpolator.dart';
import 'options.dart';
import 'plural_resolver.dart';
import 'utils.dart';

class Translator {
  Translator(this.locale, this.dataSource)
      : interpolator = Interpolator(locale),
        pluralResolver = PluralResolver();

  final Locale locale;
  final LocalizationDataSource dataSource;
  final Interpolator interpolator;
  final PluralResolver pluralResolver;

  String translate(String key, I18NextOptions options) {
    assert(key != null);
    assert(options != null);

    String namespace = '', keyPath = key;
    final match = RegExp(options.namespaceSeparator).firstMatch(key);
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }
    return translateKey(namespace, keyPath, options);
  }

  /// Order of key resolution:
  ///
  /// - context + pluralization:
  ///   ['key_ctx_plr', 'key_ctx', 'key_plr', 'key']
  /// - context only:
  ///   ['key_ctx', 'key']
  /// - pluralization only:
  ///   ['key_plr', 'key']
  /// - Otherwise:
  ///   ['key']
  String translateKey(String namespace, String key, I18NextOptions options) {
    final context = options.context;
    final count = options.count;
    final needsContext = context != null && context.isNotEmpty;
    final needsPlural = count != null;

    String pluralSuffix;
    if (needsPlural)
      pluralSuffix =
          pluralResolver.pluralize(options.pluralSuffix, count, locale);

    String tempKey = key;
    List<String> keys = [key];
    if (needsContext && needsPlural) {
      keys.add(tempKey + pluralSuffix);
    }
    if (needsContext) {
      keys.add(tempKey += '${options.contextSeparator}$context');
    }
    if (needsPlural) {
      keys.add(tempKey += pluralSuffix);
    }

    String result;
    while (keys.isNotEmpty) {
      final currentKey = keys.removeLast();
      final found = find(namespace, currentKey, options);
      if (found != null) {
        result = found;
        break;
      }
    }
    return result;
  }

  String find(String namespace, String key, I18NextOptions options) {
    Map<String, Object> data = dataSource(namespace, locale);
    final value = evaluate(key, data);
    if (value == null) {
      // TODO: fallback locales
      // TODO: fallback namespaces
      // TODO: fallback to default value
    }

    String result;
    if (value != null) {
      result = interpolator.interpolate(value, options);
      result = interpolator.nest(result, translate, options);
    }
    return result;
  }

  /// Given a key with multiple split points (`.`), this method navigates
  /// through the objects and returns the last node, expecting it to be a
  /// [String], null otherwise.
  static String evaluate(String path, Map<String, Object> data) {
    final keys = path.split('.');

    dynamic object = data;
    for (final key in keys) {
      if (object is Map && object.containsKey(key))
        object = object[key];
      else
        return null;
    }

    if (object is! String) return null;
    return object;
  }
}
