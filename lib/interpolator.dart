import 'dart:convert';
import 'dart:ui';

import 'src/options.dart';
import 'utils.dart';

typedef Translate = String? Function(
  String,
  Locale,
  Map<String, dynamic>,
  I18NextOptions,
);

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

  return string.splitMapJoin(
    pattern,
    onMatch: (match) {
      final regExpMatch = match as RegExpMatch;
      final variable = regExpMatch.namedGroup('variable');

      String? result;
      if (variable != null) {
        final path = variable.split(keySeparator);
        final value = evaluate(path, variables);
        // TODO: throw error or fallback behavior on options here?
        if (value != null) {
          final formatter = options.formatter;
          if (formatter != null) {
            final format = regExpMatch.namedGroup('format');
            result = formatter(value, format, locale);
          }
        }
      }
      return result ?? regExpMatch.group(0)!;
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
  Map<String, dynamic> variables,
  I18NextOptions options,
) {
  final pattern = nestingPattern(options);
  return string.splitMapJoin(pattern, onMatch: (match) {
    final regExpMatch = match as RegExpMatch;
    final key = regExpMatch.namedGroup('key');

    String? result;
    if (key != null && key.isNotEmpty) {
      final newVariables = Map<String, dynamic>.of(variables);
      final varsString = regExpMatch.namedGroup('variables');
      if (varsString != null && varsString.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(varsString);
          newVariables.addAll(decoded);
        } catch (error) {
          // TODO: throw/fallback nesting failure(s)?
          assert(true, error);
        }
      }

      result = translate(key, locale, newVariables, options);
    }
    return result ?? regExpMatch.group(0)!;
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
