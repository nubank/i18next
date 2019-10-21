import 'dart:ui';

import 'utils.dart';

/// Contains all options for [I18Next] to work properly.
class I18NextOptions {
  I18NextOptions({
    this.namespaceSeparator = ':',
    String interpolationPrefix = '{{',
    String interpolationSuffix = '}}',
    String interpolationSeparator = ',',
    String nestingPrefix = r'$t(',
    String nestingSuffix = ')',
    String nestingSeparator = ',',
    this.pluralSuffix = '_plural',
    ArgumentFormatter formatter,
  })  : assert(interpolationPrefix != null),
        assert(interpolationSuffix != null),
        assert(interpolationSeparator != null &&
            interpolationSeparator.isNotEmpty),
        assert(nestingPrefix != null),
        assert(nestingSuffix != null),
        assert(nestingSeparator != null && nestingSeparator.isNotEmpty),
        interpolationPrefix = RegExp.escape(interpolationPrefix),
        interpolationSuffix = RegExp.escape(interpolationSuffix),
        interpolationSeparator = RegExp.escape(interpolationSeparator),
        nestingPrefix = RegExp.escape(nestingPrefix),
        nestingSuffix = RegExp.escape(nestingSuffix),
        nestingSeparator = RegExp.escape(nestingSeparator),
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
  ///
  /// e.g.
  /// - '{{title}}' name = 'title, format = null
  /// - '{{title, uppercase}}' name = 'title', format = 'uppercase'
  final String interpolationPrefix, interpolationSuffix, interpolationSeparator;

  /// [nestingPrefix] and [nestingSuffix] are the deliminators for nesting
  /// mechanism. By default they are '$t(' and ')' respectively and can't be
  /// null but can be empty.
  ///
  /// [nestingSeparator] is used to separate the key's name from the variables
  /// (if any) which must be JSON. Defaults to ',' and cannot be null nor empty
  /// (otherwise it'll match every char in the nesting).
  ///
  /// They are all used to build the [nestingPattern].
  ///
  /// e.g.
  /// ```json
  /// {
  ///   key1: "Hello $t(key2)!"
  ///   key2: "World"
  /// }
  /// i18Next.t('key1') // "Hello World!"
  /// ```
  final String nestingPrefix, nestingSuffix, nestingSeparator;

  /// This is the suffix used for the pluralization mechanism.
  ///
  /// Defaults to '_plural' and is used for both simple and complex
  /// pluralization rule cases.
  ///
  /// For example, in english where it only has singular or plural forms:
  ///
  /// ```
  /// "friend": "A friend"
  /// "friend_plural": "{{count}} friends"
  /// ```
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

  RegExp get nestingPattern => RegExp('$nestingPrefix'
      '(?<key>.*?)($nestingSeparator\\s*(?<variables>.*?)\\s*)?'
      '$nestingSuffix');

  /// Simply returns [value] in string form. Ignores [format] and [locale].
  static String defaultFormatter(Object value, String format, Locale locale) =>
      value.toString();
}
