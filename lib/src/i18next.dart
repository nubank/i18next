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
    locale ??= this.locale;

    final analyzer = _KeyAnalyzer.fromKey(key);
    final data = dataSource(analyzer.namespace, locale);
    if (data == null) {
      assert(
        false,
        'Data source could not retrieve appropriate strings map for $locale'
        ' at $analyzer',
      );
      return key;
    }

    return _translate(
          analyzer.key,
          data,
          context: context,
          count: count,
          variables: variables,
          locale: locale,
          options: options,
        ) ??
        key;
  }

  static String _translate(
    String key,
    Map<String, Object> data, {
    String context,
    int count,
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
  }) {
    variables ??= {};
    String alteredKey = key;
    if (context != null && context.isNotEmpty) {
      alteredKey = _contextualize(alteredKey, context);
      variables['context'] ??= context;
    }
    if (count != null) {
      alteredKey = _pluralize(alteredKey, count, locale);
      variables['count'] ??= count;
    }

    String message = _evaluate(alteredKey, data);
    // trying fallbacks
    if (message == null) {
      if (count != null)
        message ??= _evaluate(_pluralize(key, count, locale), data);
      if (context != null && context.isNotEmpty)
        message ??= _evaluate(_contextualize(key, context), data);
      message ??= _evaluate(key, data);
    }

    if (message != null)
      message = _interpolate(message, variables, locale, options);
    return message;
  }

  /// Returns the contextualized form for the [key].
  static String _contextualize(String key, String context) {
    return '${key}_$context';
  }

  /// Returns the pluralized form for the [key] based on [locale] and [count].
  static String _pluralize(String key, int count, Locale locale) {
    // TODO: check locale's plural forms (zero, one, few, many, others)
    return count == 1 ? key : '${key}_plural';
  }

  /// Given a key with multiple split points (`.`), this method navigates
  /// through the objects and returns the last node, expecting it to be a
  /// [String], null otherwise.
  static String _evaluate(String path, Map<String, Object> data) {
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

  /// Replaces occurrences of matches in [target] for the named values
  /// in [variables] (if they exist), by first passing through the
  /// [InterpolationOptions.formatter] before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [InterpolationOptions.formatter] must be able to
  ///   properly format the date.
  static String _interpolate(
    String target,
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
  ) {
    return target.splitMapJoin(
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
}

class _KeyAnalyzer {
  _KeyAnalyzer(this.namespace, this.key);

  /// From [key], it extracts a [namespace] and a [key]:
  ///
  /// - 'ns:myKey' -> namespace: 'ns', key: 'myKey'
  /// - 'ns:my.key' -> namespace: 'ns', key: 'my.key'
  /// - 'myKey' -> namespace: '', key: 'myKey'
  factory _KeyAnalyzer.fromKey(String key) {
    final match = RegExp(':').firstMatch(key);
    String namespace, keyPath;
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }
    return _KeyAnalyzer(namespace ?? '', keyPath ?? key);
  }

  final String namespace, key;

  @override
  String toString() => '"$namespace" : "$key"';
}
