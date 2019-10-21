import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'options.dart';
import 'utils.dart';

/// It translates the i18next localized format in your localization objects
/// (provided by [dataSource]) to the final translation.
///
/// Usually the most common usage:
///
/// ```dart
/// // {
/// //   "key": "My text",
/// //   "nested": { "key": "My nested text" }
/// // }
/// I18Next.localization('key') // -> 'My text'
/// I18Next.localization('nested.key') // -> 'My nested text'
/// ```
///
/// It also allows the usage of namespaces (as long as they are provided by
/// [dataSource]:
///
/// ```dart
/// // common.json
/// // { "continue": "Continue" }
/// // feature.json
/// // { "title": "My feature Title" }
/// I18Next.t('common:continue') // -> 'Continue'
/// I18Next.t('feature:title') // -> 'My feature title'
/// ```
class I18Next {
  I18Next(this.locale, this.dataSource, {I18NextOptions options})
      : assert(dataSource != null),
        options = options ?? I18NextOptions();

  /// The current [Locale] for this instance.
  ///
  /// It is used as the default locale for pluralization rules and [dataSource].
  final Locale locale;

  /// Called when a key and namespace were identified and requires the namespace
  /// object to retrieve the key.
  ///
  /// If null in debug mode throws an assertion error, in release mode  it'll
  /// just fallback to the key used.
  final LocalizationDataSource dataSource;

  /// The options used to find and format matching interpolations.
  final I18NextOptions options;

  /// Attempts to retrieve a translation at [key].
  ///
  /// - If [context] is given, then attempts to search for the key
  ///   at 'key_context', before defaulting to the [key] itself. It is useful
  ///   for selections like gender.
  /// - If [count] is given, then based on [locale] attempts to find the
  ///   appropriate pluralized key, before defaulting to the [key] itself.
  ///   Most languages like `en` have only `one` and `other` pluralization
  ///   forms but some like `ar` require a more complex system.
  /// - If [variables] are given, they are used as a lookup table when a match
  ///   has been found (delimited by [I18NextOptions.interpolationPrefix] and
  ///   [I18NextOptions.interpolationSuffix]). Before the result is added to
  ///   the final message, it first goes through [I18NextOptions.formatter].
  /// - If [locale] is given, it overrides the current locale value.
  ///
  /// Keys that allow both contextualization and pluralization must be declared
  /// in the order: `key_context_plural`
  String t(
    String key, {
    String context,
    int count,
    Map<String, Object> variables,
    Locale locale,
  }) {
    assert(key != null);
    locale ??= this.locale;

    String namespace = '', keyPath = key;
    final match = RegExp(':').firstMatch(key);
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }

    return translateKey(namespace, keyPath,
            context: context,
            count: count,
            variables: variables,
            locale: locale,
            options: options,
            dataSource: dataSource) ??
        key;
  }

  static String translateKey(
    String namespace,
    String key, {
    String context,
    int count,
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
    // TODO: remove this later
    @required LocalizationDataSource dataSource,
  }) {
    if (context != null && context.isNotEmpty) {
      final contextKey = '${key}_$context';
      final value = translateKey(namespace, contextKey,
          count: count,
          variables: variables,
          locale: locale,
          options: options,
          dataSource: dataSource);
      if (value != null) return value;
    }

    if (count != null) {
      final variablesWithCount = Map<String, Object>.from(variables ?? {});
      variablesWithCount['count'] ??= count;

      final pluralKey = pluralize(key, options.pluralSuffix, count, locale);
      final value = translateKey(namespace, pluralKey,
          variables: variablesWithCount,
          locale: locale,
          options: options,
          dataSource: dataSource);
      if (value != null) return value;
    }

    return find(namespace, key,
        variables: variables,
        locale: locale,
        options: options,
        dataSource: dataSource);
  }

  /// Returns the pluralized form for the [key] based on [locale] and [count].
  static String pluralize(String key, String suffix, int count, Locale locale) {
    if (count != 1) {
      final number = _numberForLocale(count.abs(), locale);
      if (number >= 0)
        key = '$key${suffix}_$number';
      else
        key = '$key$suffix';
    }
    return key;
  }

  static int _numberForLocale(int count, Locale locale) {
    // TODO: add locale based rules
    return -1;
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

  static String find(
    String namespace,
    String key, {
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
    // TODO: remove this later
    @required LocalizationDataSource dataSource,
  }) {
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
      result = interpolate(value,
          variables: variables, locale: locale, options: options);
      result =
          nest(result, variables: variables, locale: locale, options: options);
    }

    return result;
  }

  /// Replaces occurrences of matches in [target] for the named values
  /// in [variables] (if they exist), by first passing through the
  /// [InterpolationOptions.formatter] before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [InterpolationOptions.formatter] must be able to
  ///   properly format the date.
  static String interpolate(
    String string, {
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
  }) {
    return string.splitMapJoin(
      options.interpolationPattern,
      onMatch: (match) {
        RegExpMatch regExpMatch = match;
        final variable = regExpMatch.namedGroup('variable');

        String result;
        final value = variables[variable];
        if (value != null) {
          final format = regExpMatch.namedGroup('format');
          result = options.formatter(value, format, locale);
        }
        return result ?? regExpMatch.group(0);
      },
    );
  }

  static String nest(
    String string, {
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
  }) {
    // TODO: implement
    return string;
  }
}
