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
  final formatSeparator = options.formatSeparator ?? ',';
  final keySeparator = options.keySeparator ?? '.';

  return string.splitMapJoin(pattern, onMatch: (match) {
    var variable = match[1]!.trim();
    String? format;
    if (variable.contains(formatSeparator)) {
      final variableParts = variable.split(formatSeparator);
      variable = variableParts.first.trim();
      format = variableParts.skip(1).join(formatSeparator).trim();
    }

    if (variable.isEmpty) {
      throw InterpolationException('Missing variable', match);
    }
    final path = variable.split(keySeparator);
    final value = evaluate(path, variables);
    if (value == null) {
      throw InterpolationException('Could not evaluate variable', match);
    }
    return options.formatter?.call(value, format, locale) ?? value.toString();
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
  final optionsSeparator = options.nestingOptionsSeparator ?? ',';

  return string.splitMapJoin(pattern, onMatch: (match) {
    var key = match[1]!.trim();

    final newVariables = {...variables};
    if (key.contains(optionsSeparator)) {
      final index = key.indexOf(optionsSeparator);
      final nestedOptionsString =
          key.substring(index + optionsSeparator.length).trim();
      newVariables.addAll(jsonDecode(nestedOptionsString));
      key = key.substring(0, index).trim(); // after options
    }

    if (key.isEmpty) {
      throw NestingException('Key not found', match);
    }

    return translate(key, locale, newVariables, options) ??
        (throw NestingException('Translation not found', match));
  });
}

RegExp interpolationPattern(I18NextOptions options) {
  final prefix = RegExp.escape(options.interpolationPrefix ?? '{{');
  final suffix = RegExp.escape(options.interpolationSuffix ?? '}}');
  return RegExp('$prefix(.*?)$suffix', dotAll: true);
}

RegExp nestingPattern(I18NextOptions options) {
  final prefix = RegExp.escape(options.nestingPrefix ?? r'$t(');
  final suffix = RegExp.escape(options.nestingSuffix ?? ')');
  return RegExp('$prefix(.*?)$suffix', dotAll: true);
}
