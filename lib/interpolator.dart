import 'dart:convert';
import 'dart:ui';

import 'src/options.dart';
import 'utils.dart';

typedef Translate = String? Function(
  String key,
  Locale locale,
  Map<String, dynamic> variables,
  I18NextOptions options,
);

/// Exception thrown when the [interpolate] fails while processing
/// for either not containing a variable or with malformed or
/// incoherent evaluations.
class InterpolationException implements Exception {
  InterpolationException(this.message, this.match);

  final String message;
  final Match match;

  @override
  String toString() => 'InterpolationException: $message in "${match[0]}"';
}

/// Exception thrown when the [nest] fails while processing
class NestingException implements Exception {
  NestingException(this.message, this.match);

  final String message;
  final Match match;

  @override
  String toString() => 'NestingException: $message in "${match[0]}"';
}

/// Replaces occurrences of matches in [string] for the named values
/// in [options] (if they exist), by first passing through the
/// [I18NextOptions.formatter] before joining the resulting string.
///
/// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
///   This example illustrates a simple interpolation.
/// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
///   In this example, [I18NextOptions.formatter] must be able to
///   properly format the date.
/// - 'A string with {{grouped.key}}' + {'grouped': {'key': "grouped keys}} ->
///   'A string with grouped keys'. In this example the variables are in the
///   grouped formation (denoted by the [I18NextOptions.keySeparator]).
String interpolate(
  Locale locale,
  String string,
  Map<String, dynamic> variables,
  I18NextOptions options,
) {
  final pattern = interpolationPattern(options);
  final keySeparator = options.keySeparator ?? '.';

  return string.splitMapJoin(pattern, onMatch: (match) {
    match = match as RegExpMatch;
    final variable = match.namedGroup('variable')?.trim();
    if (variable == null || variable.isEmpty) {
      throw InterpolationException('Missing variable', match);
    }

    final path = variable.split(keySeparator);
    final value = evaluate(path, variables);
    if (value == null) {
      throw InterpolationException('Could not evaluate variable', match);
    }

    final formatter = options.formatter;
    if (formatter != null) {
      final format = match.namedGroup('format');
      return formatter(value, format, locale);
    }
    return value.toString();
  });
}

/// Replaces occurrences of nested key-values in [string] for other
/// key-values. Essentially calls [I18Next.translate] with the nested value.
///
/// If nesting fails, returns null. (e.g. missing key, or variables malformed)
///
/// E.g.:
/// ```json
/// {
///   key1: "Hello $t(key2)!"
///   key2: "World"
/// }
/// i18Next.t('key1') // "Hello World!"
/// ```
String nest(
  Locale locale,
  String string,
  Translate translate,
  Map<String, dynamic> variables,
  I18NextOptions options,
) {
  final pattern = nestingPattern(options);

  return string.splitMapJoin(pattern, onMatch: (match) {
    match = match as RegExpMatch;
    final key = match.namedGroup('key');
    if (key == null || key.isEmpty) {
      throw NestingException('Key not found', match);
    }

    final newVariables = Map<String, dynamic>.of(variables);
    final varsString = match.namedGroup('variables');
    if (varsString != null && varsString.isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(varsString);
      newVariables.addAll(decoded);
    }

    final value = translate(key, locale, newVariables, options);
    if (value == null) {
      throw NestingException('Translation not found', match);
    }
    return value;
  });
}

RegExp interpolationPattern(I18NextOptions options) {
  final prefix = RegExp.escape(options.interpolationPrefix ?? '{{');
  final suffix = RegExp.escape(options.interpolationSuffix ?? '}}');
  final separator = RegExp.escape(options.interpolationSeparator ?? ',');
  return RegExp(
    '$prefix'
    '(?<variable>.*?)'
    '($separator\\s*(?<format>.*?)\\s*)?'
    '$suffix',
  );
}

RegExp nestingPattern(I18NextOptions options) {
  final prefix = RegExp.escape(options.nestingPrefix ?? r'$t(');
  final suffix = RegExp.escape(options.nestingSuffix ?? ')');
  final separator = RegExp.escape(options.nestingSeparator ?? ',');
  return RegExp(
    '$prefix'
    '(?<key>.*?)'
    '($separator\\s*(?<variables>.*?)\\s*)?'
    '$suffix',
  );
}
