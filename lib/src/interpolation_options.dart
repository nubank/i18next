import 'dart:ui';

import 'utils.dart';

class InterpolationOptions {
  /// [prefix] and [suffix] are the deliminators for the variable
  /// interpolation and formatting mechanism.
  /// By default they are '{{' and '}}' respectively and can't be null but
  /// can be empty.
  ///
  /// [separatorPattern] is used to separate the variable's name from the
  /// format (if any). Defaults to ',' and cannot be null nor empty (otherwise
  /// it'll match every char in the interpolation).
  /// e.g. '{{title, uppercase}}' name = 'title', format = 'uppercase'
  InterpolationOptions({
    String prefix = '{{',
    String suffix = '}}',
    String formatSeparator = ',',
    ArgumentFormatter formatter,
  })  : assert(prefix != null),
        assert(suffix != null),
        assert(formatSeparator != null && formatSeparator.isNotEmpty),
        pattern = RegExp('$prefix(.*?)$suffix'),
        separatorPattern = RegExp(' *$formatSeparator *'),
        formatter = formatter ?? defaultFormatter;

  /// The matching pattern for interpolations.
  ///
  /// Default lazily catches the contents between a prefix `{{` and suffix '}}'.
  final Pattern pattern;

  /// The matching pattern for separating the contents in interpolations
  /// matched by [pattern].
  ///
  /// Default matches ',' removing leading and trailing whitespaces.
  final Pattern separatorPattern;

  /// Formats the variables before they are joined into the final result.
  ///
  /// Defaults to [defaultFormatter] which simply returns the value itself.
  final ArgumentFormatter formatter;

  /// Simply returns the [value], doesn't attempt to format it in any way.
  static String defaultFormatter(Object value, String format, Locale locale) =>
      value.toString();
}
