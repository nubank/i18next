import 'dart:convert';
import 'dart:ui';

import 'options.dart';

class Interpolator {
  Interpolator(this.locale);

  final Locale locale;

  /// Replaces occurrences of matches in [string] for the named values
  /// in [options] (if they exist), by first passing through the
  /// [I18NextOptions.formatter] before joining the resulting string.
  ///
  /// - 'Hello {{name}}' + {name: 'World'} -> 'Hello World'.
  ///   This example illustrates a simple interpolation.
  /// - 'Now is {{date, dd/MM}}' + {date: DateTime.now()} -> 'Now is 23/09'.
  ///   In this example, [I18NextOptions.formatter] must be able to
  ///   properly format the date.
  String interpolate(String string, I18NextOptions options) {
    assert(string != null);
    assert(options != null);

    return string.splitMapJoin(
      options.interpolationPattern,
      onMatch: (match) {
        RegExpMatch regExpMatch = match;
        final variable = regExpMatch.namedGroup('variable');

        String result;
        final value = options[variable];
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
    String string,
    String Function(String, I18NextOptions) translate,
    I18NextOptions options,
  ) {
    assert(string != null);
    assert(translate != null);
    assert(options != null);

    return string.splitMapJoin(options.nestingPattern, onMatch: (match) {
      RegExpMatch regExpMatch = match;
      final key = regExpMatch.namedGroup('key');

      String result;
      if (key != null) {
        final varsString = regExpMatch.namedGroup('variables');

        Map<String, Object> variables;
        if (varsString != null && varsString.isNotEmpty) {
          try {
            variables = jsonDecode(varsString);
          } catch (error) {
            assert(true, error);
          }
        }

        result = translate(key, options.apply(variables));
      }
      return result ?? regExpMatch.group(0);
    });
  }
}
