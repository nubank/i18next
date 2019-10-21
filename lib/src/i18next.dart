import 'dart:convert';
import 'dart:ui';

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

    return _Translation(
          locale ?? this.locale,
          dataSource,
          options,
        ).t(
          key,
          context: context,
          count: count,
          variables: variables,
        ) ??
        key;
  }
}

class _Translation {
  _Translation(this.locale, this.dataSource, this.options);

  final Locale locale;
  final LocalizationDataSource dataSource;
  final I18NextOptions options;

  String t(
    String key, {
    String context,
    int count,
    Map<String, Object> variables,
  }) {
    assert(key != null);

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
      final variablesWithCount = Map<String, Object>.from(variables ?? {});
      variablesWithCount['count'] ??= count;

      final pluralKey = pluralize(key, options.pluralSuffix, count, locale);
      final value =
          translateKey(namespace, pluralKey, variables: variablesWithCount);
      if (value != null) return value;
    }

    return find(namespace, key, variables: variables);
  }

  /// Returns the pluralized form for the [key] based on [locale] and [count].
  String pluralize(String key, String suffix, int count, Locale locale) {
    if (count != 1) {
      final number = _numberForLocale(count.abs(), locale);
      if (number >= 0)
        key = '$key${suffix}_$number';
      else
        key = '$key$suffix';
    }
    return key;
  }

  int _numberForLocale(int count, Locale locale) {
    // TODO: add locale based rules
    return -1;
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
      variables ??= {};
      result = interpolate(value, variables: variables);
      result = nest(result, variables: variables);
    }

    return result;
  }

  /// Replaces occurrences of matches in [string] for the named values
  /// in [variables] (if they exist), by first passing through the
  /// [I18NextOptions.formatter] before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [I18NextOptions.formatter] must be able to
  ///   properly format the date.
  String interpolate(
    String string, {
    Map<String, Object> variables,
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

  /// Replaces occurrences of nested key-values in [string] for other
  /// key-values. Essentially calls [I18Next.t] with the nested value.
  ///
  /// E.g.:
  /// ```json
  /// {
  ///   key1: "Hello $t(key2)!"
  ///   key2: "World"
  /// }
  /// i18Next.t('key1') // "Hello World!"
  /// ```
  String nest(String string, {Map<String, Object> variables}) {
    return string.splitMapJoin(options.nestingPattern, onMatch: (match) {
      RegExpMatch regExpMatch = match;
      final key = regExpMatch.namedGroup('key');

      String result;
      if (key != null) {
        final varsString = regExpMatch.namedGroup('variables');
        String context;
        int count;

        final copy = Map<String, Object>.from(variables);
        if (varsString != null && varsString.isNotEmpty) {
          try {
            final Map<String, Object> vars = jsonDecode(varsString);
            if (vars != null) {
              context = vars['context'];
              count = vars['count'];
              copy.addAll(vars);
            }
          } catch (error) {
            assert(true, error);
          }
        }

        result = t(key, context: context, count: count, variables: copy);
      }
      return result ?? regExpMatch.group(0);
    });
  }
}
