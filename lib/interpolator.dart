import 'dart:convert';
import 'dart:ui';

import 'src/options.dart';
import 'utils.dart';

typedef Translate = String Function(
    String, Locale, Map<String, Object>, I18NextOptions);

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
  Map<String, Object> variables,
  I18NextOptions options,
) {
  assert(string != null);
  assert(options != null);
  variables ??= {};

  return string.splitMapJoin(
    interpolationPattern(options),
    onMatch: (match) {
      final RegExpMatch regExpMatch = match;
      final variable = regExpMatch.namedGroup('variable');

      String result;
      final path = variable.split(options.keySeparator);
      final value = evaluate(path, variables);
      if (value != null) {
        final format = regExpMatch.namedGroup('format');
        result = options.formatter(value, format, locale);
      }
      return result ?? regExpMatch.group(0);
    },
  );
}

/// Replaces occurrences of nested key-values in [string] for other
/// key-values. Essentially calls [I18Next.translate] with the nested value.
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
  Map<String, Object> variables,
  I18NextOptions options,
) {
  assert(string != null);
  assert(translate != null);
  assert(options != null);
  variables ??= {};

  return string.splitMapJoin(nestingPattern(options), onMatch: (match) {
    final RegExpMatch regExpMatch = match;
    final key = regExpMatch.namedGroup('key');

    String result;
    if (key != null && key.isNotEmpty) {
      final newVariables = Map<String, Object>.of(variables);
      final varsString = regExpMatch.namedGroup('variables');
      if (varsString != null && varsString.isNotEmpty) {
        try {
          newVariables.addAll(jsonDecode(varsString));
        } catch (error) {
          assert(true, error);
        }
      }

      result = translate(key, locale, newVariables, options);
    }
    return result ?? regExpMatch.group(0);
  });
}

RegExp interpolationPattern(I18NextOptions options) => RegExp(
      '${options.interpolationPrefix}'
      '(?<variable>.*?)'
      '(${options.interpolationSeparator}\\s*(?<format>.*?)\\s*)?'
      '${options.interpolationSuffix}',
    );

RegExp nestingPattern(I18NextOptions options) => RegExp(
      '${options.nestingPrefix}'
      '(?<key>.*?)'
      '(${options.nestingSeparator}\\s*(?<variables>.*?)\\s*)?'
      '${options.nestingSuffix}',
    );
