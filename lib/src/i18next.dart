import 'dart:ui';

typedef ArgumentFormatter = String Function(Object, String, Locale);

typedef LocalizationDataSource = Map<String, Object> Function(String, Locale);

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
/// I18Next.localization('common:continue') // -> 'Continue'
/// I18Next.localization('feature:title') // -> 'My feature title'
/// ```
class I18Next {
  const I18Next(
    this.locale,
    this.dataSource, {
    this.prefix = '{{',
    this.suffix = '}}',
    this.formatSeparator = ',',
    ArgumentFormatter formatter,
  })  : assert(prefix != null),
        assert(suffix != null),
        assert(dataSource != null),
        assert(formatSeparator != null && formatSeparator != ''),
        formatter = formatter ?? defaultFormatter;

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

  /// [prefix] and [suffix] are the deliminators for the variable
  /// interpolation and formatting mechanism.
  /// By default they are '{{' and '}}' respectively and ca't be null but
  /// can be empty.
  ///
  /// [formatSeparator] is used to separate the variable's name from the
  /// format (if any). Defaults to ',' and cannot be null.
  /// e.g. '{{title, uppercase}}' name = 'title', format = 'uppercase'
  final String prefix, suffix, formatSeparator;

  /// Formats the variables before they are joined into the final result.
  ///
  /// Defaults to [defaultFormatter] which simply returns the value itself.
  final ArgumentFormatter formatter;

  /// Simply returns the [value], doesn't attempt to format it in any way.
  static String defaultFormatter(Object value, String format, Locale locale) =>
      value.toString();

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
  // TODO: add individual level property overrides (prefix, suffix, locale, ...)
  String t(
    String key, {
    String context,
    int count,
    Map<String, Object> arguments,
  }) {
    assert(key != null);

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

    arguments ??= {};
    String alteredKey = analyzer.keyPath;
    if (context != null && context.isNotEmpty) {
      alteredKey = _contextualize(alteredKey, context);
      arguments['context'] ??= context;
    }
    if (count != null) {
      alteredKey = _pluralize(alteredKey, count);
      arguments['count'] ??= count;
    }

    // TODO: try all possibilities for fallbacks?
    String message = _evaluate(alteredKey, data);
    if (message == null && count != null)
      message = _evaluate(_pluralize(analyzer.keyPath, count), data);
    if (message == null && context != null)
      message = _evaluate(_contextualize(analyzer.keyPath, context), data);
    if (message == null) message = _evaluate(analyzer.keyPath, data);

    if (message != null) message = _replace(message, arguments);
    return message ?? key;
  }

  String _contextualize(String key, String context) {
    return '${key}_$context';
  }

  /// Returns the pluralized form for the [key] based on [locale] and [count].
  String _pluralize(String key, int count) {
    // TODO: check locale's plural forms (zero, one, few, many, others)
    return count == 1 ? key : '${key}_plural';
  }

  /// Given a key with multiple split points (`.`), this method navigates
  /// through the objects and returns the last node, expecting it to be a
  /// [String], null otherwise.
  String _evaluate(String path, Map<String, Object> data) {
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

  /// Replaces occurrences of matches ([prefix] and [suffix]) in [target] for
  /// the named values in [arguments], by first passing through the [formatter]
  /// before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [formatter] must be able to properly format the date.
  String _replace(String target, Map<String, Object> arguments) {
    if (arguments == null || arguments.isEmpty) return target;

    final regex = RegExp('$prefix(.*?)$suffix');
    return target.splitMapJoin(
      regex,
      onMatch: (match) {
        final split = match.group(1).split(RegExp(' *$formatSeparator *'));
        final name = split.first;
        if (arguments.containsKey(name)) {
          String format;
          if (split.length > 1) format = split[1];
          return formatter(arguments[name], format, locale);
        }
        return match.group(0);
      },
      onNonMatch: (nonMatch) => nonMatch,
    );
  }
}

class _KeyAnalyzer {
  _KeyAnalyzer(this.namespace, this.keyPath);

  factory _KeyAnalyzer.fromKey(String key) {
    final match = RegExp(':').firstMatch(key);
    String namespace, keyPath;
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }
    return _KeyAnalyzer(namespace ?? '', keyPath ?? key);
  }

  final String namespace, keyPath;

  @override
  String toString() => '"$namespace" : "$keyPath"';
}
