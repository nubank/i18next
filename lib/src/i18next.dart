import 'dart:ui';

import 'interpolation_options.dart';
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
  I18Next(this.locale, this.dataSource, {InterpolationOptions interpolation})
      : assert(dataSource != null),
        interpolation = interpolation ?? InterpolationOptions();

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
  final InterpolationOptions interpolation;

  /// Attempts to retrieve a translation at [key].
  ///
  /// - If [context] is given, then attempts to search for the key
  ///   at 'key_context', before defaulting to the [key] itself. It is useful
  ///   for selections like gender.
  /// - If [count] is given, then based on [locale] attempts to find the
  ///   appropriate pluralized key, before defaulting to the [key] itself.
  ///   Most languages like `en` have only `one` and `other` pluralization
  ///   forms but some like `ar` require a more complex system.
  /// - If [arguments] are given, they are used as a lookup table when a match
  ///   has been found (delimited by [prefix] and [suffix]). Before the result
  ///   is added to the final message, it first goes through [formatter].
  /// - If [locale] is given, it overrides the current locale value.
  /// - If [interpolation] is given, it overrides the current interpolation
  /// values.
  String t(
    String key, {
    String context,
    int count,
    Map<String, Object> arguments,
    Locale locale,
    InterpolationOptions interpolation,
  }) {
    assert(key != null);
    locale ??= this.locale;
    // TODO: add a way to merge instead of overriding everything?
    interpolation ??= this.interpolation;

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
          arguments: arguments,
          locale: locale,
          interpolation: interpolation,
        ) ??
        key;
  }

  static String _translate(
    String key,
    Map<String, Object> data, {
    String context,
    int count,
    Map<String, Object> arguments,
    Locale locale,
    InterpolationOptions interpolation,
  }) {
    arguments ??= {};
    String alteredKey = key;
    if (context != null && context.isNotEmpty) {
      alteredKey = _contextualize(alteredKey, context);
      arguments['context'] ??= context;
    }
    if (count != null) {
      alteredKey = _pluralize(alteredKey, count, locale);
      arguments['count'] ??= count;
    }

    String message = _evaluate(alteredKey, data);
    // trying fallbacks
    if (message == null && count != null)
      message = _evaluate(_pluralize(key, count, locale), data);
    if (message == null && context != null)
      message = _evaluate(_contextualize(key, context), data);
    if (message == null) message = _evaluate(key, data);

    if (message != null)
      message = _interpolate(message, arguments, locale, interpolation);
    return message;
  }

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
  /// in [arguments] (if they exist), by first passing through the
  /// [InterpolationOptions.formatter] before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [InterpolationOptions.formatter] must be able to
  ///   properly format the date.
  static String _interpolate(
    String target,
    Map<String, Object> arguments,
    Locale locale,
    InterpolationOptions interpolation,
  ) {
    final regex = interpolation.pattern;
    return target.splitMapJoin(
      regex,
      onMatch: (match) {
        final split = match.group(1).split(interpolation.separatorPattern);
        final name = split.first;
        if (arguments.containsKey(name)) {
          String format;
          if (split.length > 1) format = split[1];
          return interpolation.formatter(arguments[name], format, locale);
        }
        return match.group(0);
      },
    );
  }
}

class _KeyAnalyzer {
  _KeyAnalyzer(this.namespace, this.key);

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
