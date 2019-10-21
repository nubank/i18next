import 'dart:ui';

import 'interpolator.dart';
import 'options.dart';
import 'plural_resolver.dart';
import 'utils.dart';

class Translator {
  Translator(this.locale, this.dataSource, this.options)
      : interpolator = Interpolator(locale, options),
        pluralResolver = PluralResolver();

  final Locale locale;
  final LocalizationDataSource dataSource;
  final I18NextOptions options;
  final Interpolator interpolator;
  final PluralResolver pluralResolver;

  String translate(
    String key, {
    String context,
    int count,
    Map<String, Object> variables,
  }) {
    assert(key != null);
    variables ??= {};

    String namespace = '', keyPath = key;
    final match = RegExp(':').firstMatch(key);
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }

    return translateKey(
          namespace,
          keyPath,
          context: context,
          count: count,
          variables: variables,
        ) ??
        key;
  }

  String translateKey(
    String namespace,
    String key, {
    String context,
    int count,
    Map<String, Object> variables,
  }) {
    if (context != null && context.isNotEmpty) {
      final contextKey = '${key}_$context';
      final value = translateKey(namespace, contextKey,
          count: count, variables: variables);
      if (value != null) return value;
    }

    if (count != null) {
      final variablesWithCount = Map<String, Object>.from(variables);
      variablesWithCount['count'] ??= count;

      final pluralKey =
          pluralResolver.pluralize(key, options.pluralSuffix, count, locale);
      final value =
          translateKey(namespace, pluralKey, variables: variablesWithCount);
      if (value != null) return value;
    }

    return find(namespace, key, variables: variables);
  }

  /// Given a key with multiple split points (`.`), this method navigates
  /// through the objects and returns the last node, expecting it to be a
  /// [String], null otherwise.
  String evaluate(String path, Map<String, Object> data) {
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

  String find(String namespace, String key, {Map<String, Object> variables}) {
    // TODO: find out if namespaces are loaded early
    Map<String, Object> data = dataSource(namespace, locale);
    final value = evaluate(key, data);
    if (value == null) {
      // TODO: fallback locales
      // TODO: fallback namespaces
      // TODO: fallback to default value
    }

    String result;
    if (value != null) {
      result = interpolator.interpolate(value, variables: variables);
      result = interpolator.nest(result, translate, variables: variables);
    }

    return result;
  }
}
