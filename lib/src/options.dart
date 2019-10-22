import 'dart:collection';
import 'dart:ui';

import 'utils.dart';

/// Contains all options for [I18Next] to work properly.
class I18NextOptions extends MapBase<String, Object> {
  I18NextOptions({
    this.namespaceSeparator,
    this.contextSeparator,
    this.interpolationPrefix,
    this.interpolationSuffix,
    this.interpolationSeparator,
    this.nestingPrefix,
    this.nestingSuffix,
    this.nestingSeparator,
    this.pluralSuffix,
    this.formatter,
    Map<String, Object> variables,
  })  : _variables = variables ?? {},
        super();

  /// Creates a new instance of [I18NextOptions] by making a copy of [other]'s
  /// values.
  I18NextOptions.from(I18NextOptions other)
      : this(
          namespaceSeparator: other.namespaceSeparator,
          contextSeparator: other.contextSeparator,
          interpolationPrefix: other.interpolationPrefix,
          interpolationSuffix: other.interpolationSuffix,
          interpolationSeparator: other.interpolationSeparator,
          nestingPrefix: other.nestingPrefix,
          nestingSuffix: other.nestingSuffix,
          nestingSeparator: other.nestingSeparator,
          pluralSuffix: other.pluralSuffix,
          formatter: other.formatter,
          variables: Map.of(other._variables),
        );

  /// Creates the base options
  static final base = I18NextOptions(
    namespaceSeparator: ':',
    contextSeparator: '_',
    interpolationPrefix: RegExp.escape('{{'),
    interpolationSuffix: RegExp.escape('}}'),
    interpolationSeparator: RegExp.escape(','),
    nestingPrefix: RegExp.escape(r'$t('),
    nestingSuffix: RegExp.escape(')'),
    nestingSeparator: RegExp.escape(','),
    pluralSuffix: '_plural',
    formatter: defaultFormatter,
    variables: const {},
  );

  /// The separator used when splitting the key.
  ///
  /// Defaults to ':'.
  final String namespaceSeparator;

  /// The separator for contexts, it is inserted between the key and the
  /// context value.
  ///
  /// Defaults to '_'.
  final String contextSeparator;

  /// [pluralSuffix] is used for the pluralization mechanism.
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

  /// [interpolationPrefix] and [interpolationSuffix] are the deliminators
  /// for the variable interpolation and formatting mechanism.
  /// By default they are '{{' and '}}' respectively and can't be null but
  /// can be empty.
  ///
  /// [interpolationSeparator] is used to separate the variable's
  /// name from the format (if any). Defaults to ',' and cannot be null nor
  /// empty (otherwise it'll match every char in the interpolation).
  ///
  /// ```
  /// - '{{title}}' name = 'title, format = null
  /// - '{{title, uppercase}}' name = 'title', format = 'uppercase'
  /// ```
  final String interpolationPrefix, interpolationSuffix, interpolationSeparator;

  /// [nestingPrefix] and [nestingSuffix] are the deliminators for nesting
  /// mechanism. By default they are '$t(' and ')' respectively and can't be
  /// null but can be empty.
  ///
  /// [nestingSeparator] is used to separate the key's name from the variables
  /// (if any) which must be JSON. Defaults to ',' and cannot be null nor empty
  /// (otherwise it'll match every char in the nesting).
  ///
  /// ```json
  /// {
  ///   key1: "Hello $t(key2)!"
  ///   key2: "World"
  /// }
  /// i18Next.t('key1') // "Hello World!"
  /// ```
  final String nestingPrefix, nestingSuffix, nestingSeparator;

  /// [formatter] is called when an interpolation has been found and is ready
  /// for substitution.
  ///
  /// Defaults to [defaultFormatter], which simply returns the value itself in
  /// String form ([Object.toString]).
  final ArgumentFormatter formatter;

  final Map<String, Object> _variables;

  String get context => _variables['context'];

  set context(String value) => _variables['context'] = value;

  int get count => _variables['count'];

  set count(int value) => _variables['count'] = value;

  /// Creates a new instance of [I18NextOptions] which overrides this
  /// instance's values for [other]'s values when they aren't null.
  ///
  /// If [other] is null, returns this instance.
  I18NextOptions apply(I18NextOptions other) {
    if (other == null) return this;

    return I18NextOptions(
      namespaceSeparator: other.namespaceSeparator ?? namespaceSeparator,
      contextSeparator: other.contextSeparator ?? contextSeparator,
      interpolationPrefix: other.interpolationPrefix ?? interpolationPrefix,
      interpolationSuffix: other.interpolationSuffix ?? interpolationSuffix,
      interpolationSeparator:
          other.interpolationSeparator ?? interpolationSeparator,
      nestingPrefix: other.nestingPrefix ?? nestingPrefix,
      nestingSuffix: other.nestingSuffix ?? nestingSuffix,
      nestingSeparator: other.nestingSeparator ?? nestingSeparator,
      pluralSuffix: other.pluralSuffix ?? pluralSuffix,
      formatter: other.formatter ?? formatter,
    )..addAll(other);
  }

  /// Simply returns [value] in string form. Ignores [format] and [locale].
  static String defaultFormatter(Object value, String format, Locale locale) =>
      value.toString();

  @override
  Object operator [](Object key) => _variables[key];

  @override
  void operator []=(String key, Object value) => _variables[key] = value;

  @override
  Object remove(Object key) => _variables.remove(key);

  @override
  void clear() => _variables.clear();

  @override
  Iterable<String> get keys => _variables.keys;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is I18NextOptions &&
      other._variables == _variables &&
      other.namespaceSeparator == namespaceSeparator &&
      other.contextSeparator == contextSeparator &&
      other.interpolationPrefix == interpolationPrefix &&
      other.interpolationSuffix == interpolationSuffix &&
      other.interpolationSeparator == interpolationSeparator &&
      other.nestingPrefix == nestingPrefix &&
      other.nestingSuffix == nestingSuffix &&
      other.nestingSeparator == nestingSeparator &&
      other.pluralSuffix == pluralSuffix &&
      other.formatter == formatter;

  @override
  int get hashCode => hashValues(
        super.hashCode,
        namespaceSeparator,
        contextSeparator,
        interpolationPrefix,
        interpolationSuffix,
        interpolationSeparator,
        nestingPrefix,
        nestingSuffix,
        nestingSeparator,
        pluralSuffix,
        formatter,
      );
}
