import 'dart:convert';
import 'dart:ui';

import 'options.dart';

class Interpolator {
  Interpolator(this.locale, this.options);

  final Locale locale;
  final I18NextOptions options;

  /// Replaces occurrences of matches in [string] for the named values
  /// in [variables] (if they exist), by first passing through the
  /// [I18NextOptions.formatter] before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [I18NextOptions.formatter] must be able to
  ///   properly format the date.
  String interpolate(String string, {Map<String, Object> variables}) {
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
  String nest(String string, Function translate,
      {Map<String, Object> variables}) {
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

        result =
            translate(key, context: context, count: count, variables: copy);
      }
      return result ?? regExpMatch.group(0);
    });
  }
}
