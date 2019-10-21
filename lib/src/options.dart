import 'dart:ui';

import 'utils.dart';

/// Contains all options for [I18Next] to work properly.
class I18NextOptions {
  I18NextOptions({
    this.namespaceSeparator = ':',
    String interpolationPrefix = '{{',
    String interpolationSuffix = '}}',
    String interpolationSeparator = ',',
    this.pluralSuffix = '_plural',
    ArgumentFormatter formatter,
  })  : assert(interpolationPrefix != null),
        assert(interpolationSuffix != null),
        assert(interpolationSeparator != null &&
            interpolationSeparator.isNotEmpty),
        interpolationPrefix = RegExp.escape(interpolationPrefix),
        interpolationSuffix = RegExp.escape(interpolationSuffix),
        interpolationSeparator = RegExp.escape(interpolationSeparator),
        formatter = formatter ?? defaultFormatter;

  final String namespaceSeparator;

  /// [interpolationPrefix] and [interpolationSuffix] are the deliminators
  /// for the variable interpolation and formatting mechanism.
  /// By default they are '{{' and '}}' respectively and can't be null but
  /// can be empty.
  ///
  /// [interpolationSeparator] is used to separate the variable's
  /// name from the format (if any). Defaults to ',' and cannot be null nor
  /// empty (otherwise it'll match every char in the interpolation).
  ///
  /// They are all used to build the [interpolationPattern].
  /// e.g.
  /// - '{{title}}' name = 'title, format = null
  /// - '{{title, uppercase}}' name = 'title', format = 'uppercase'
  final String interpolationPrefix, interpolationSuffix, interpolationSeparator;

  final String pluralSuffix;

  /// [formatter] is called when an interpolation has been found and is ready
  /// for substitution.
  ///
  /// Defaults to [defaultFormatter], which simply returns the value itself in
  /// String form ([Object.toString]).
  final ArgumentFormatter formatter;

  /// The matching pattern for interpolations.
  ///
  /// Default lazily catches the contents between a prefix `{{` and
  /// suffix '}}'.
  RegExp get interpolationPattern => RegExp('$interpolationPrefix'
      '(?<variable>.*?)($interpolationSeparator\\s*(?<format>.*?)\\s*)?'
      '$interpolationSuffix');

  /// Simply returns [value] in string form. Ignores [format] and [locale].
  static String defaultFormatter(Object value, String format, Locale locale) =>
      value.toString();
}
