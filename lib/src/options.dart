import 'dart:collection';
import 'dart:ui';

import 'utils.dart';

/// Contains all options for [I18Next] to work properly.
///
/// - [pluralSuffix] is used for the pluralization mechanism.
///   Defaults to '_plural' and is used for both simple and complex
///   pluralization rule cases.
///   For example, in english where it only has singular or plural forms:
///
/// ```
/// "friend": "A friend"
/// "friend_plural": "{{count}} friends"
/// ```
///
/// - [interpolationPrefix] and [interpolationSuffix] are the deliminators
///   for the variable interpolation and formatting mechanism.
///   By default they are '{{' and '}}' respectively and can't be null but
///   can be empty.
///   [interpolationSeparator] is used to separate the variable's
///   name from the format (if any). Defaults to ',' and cannot be null nor
///   empty (otherwise it'll match every char in the interpolation).
///   They are all used to build the [interpolationPattern].
///
/// ```
/// - '{{title}}' name = 'title, format = null
/// - '{{title, uppercase}}' name = 'title', format = 'uppercase'
/// ```
///
/// - [nestingPrefix] and [nestingSuffix] are the deliminators for nesting
///   mechanism. By default they are '$t(' and ')' respectively and can't be
///   null but can be empty.
///   [nestingSeparator] is used to separate the key's name from the variables
///   (if any) which must be JSON. Defaults to ',' and cannot be null nor empty
///   (otherwise it'll match every char in the nesting).
///   They are all used to build the [nestingPattern].
///
/// ```json
/// {
///   key1: "Hello $t(key2)!"
///   key2: "World"
/// }
/// i18Next.t('key1') // "Hello World!"
/// ```
///
/// - [formatter] is called when an interpolation has been found and is ready
///   for substitution.
///   Defaults to [defaultFormatter], which simply returns the value itself in
///   String form ([Object.toString]).
class I18NextOptions extends MapView<String, Object> {
  I18NextOptions({
    String namespaceSeparator,
    String contextSeparator,
    String interpolationPrefix,
    String interpolationSuffix,
    String interpolationSeparator,
    String nestingPrefix,
    String nestingSuffix,
    String nestingSeparator,
    String pluralSuffix,
    ArgumentFormatter formatter,
    String context,
    int count,
  }) : super(Map.fromEntries([
          MapEntry('namespaceSeparator', namespaceSeparator),
          MapEntry('contextSeparator', contextSeparator),
          MapEntry('interpolationPrefix', interpolationPrefix),
          MapEntry('interpolationSuffix', interpolationSuffix),
          MapEntry('interpolationSeparator', interpolationSeparator),
          MapEntry('nestingPrefix', nestingPrefix),
          MapEntry('nestingSuffix', nestingSuffix),
          MapEntry('nestingSeparator', nestingSeparator),
          MapEntry('pluralSuffix', pluralSuffix),
          MapEntry('formatter', formatter),
          MapEntry('context', context),
          MapEntry('count', count),
        ].where((entry) => entry.value != null)));

  /// Creates a new instance of [I18NextOptions] by making a copy of [other].
  I18NextOptions.from(Map<String, Object> other) : super(Map.of(other));

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
  );

  /// Safely accesses and converts to the desired [Object] type [T].
  T _safely<T extends Object>(String name) {
    final value = this[name];
    return value is T ? value : null;
  }

  String get namespaceSeparator => _safely('namespaceSeparator');

  set namespaceSeparator(String value) => this['namespaceSeparator'] = value;

  String get contextSeparator => _safely('contextSeparator');

  set contextSeparator(String value) => this['contextSeparator'] = value;

  String get pluralSuffix => _safely('pluralSuffix');

  set pluralSuffix(String value) => this['pluralSuffix'];

  String get interpolationPrefix => _safely('interpolationPrefix');

  set interpolationPrefix(String value) => this['interpolationPrefix'] = value;

  String get interpolationSuffix => _safely('interpolationSuffix');

  set interpolationSuffix(String value) => this['interpolationSuffix'] = value;

  String get interpolationSeparator => _safely('interpolationSeparator');

  set interpolationSeparator(String value) =>
      this['interpolationSeparator'] = value;

  String get nestingPrefix => _safely('nestingPrefix');

  set nestingPrefix(String value) => this['nestingPrefix'];

  String get nestingSuffix => _safely('nestingSuffix');

  set nestingSuffix(String value) => this['nestingSuffix'];

  String get nestingSeparator => _safely('nestingSeparator');

  set nestingSeparator(String value) => this['nestingSeparator'];

  ArgumentFormatter get formatter => _safely('formatter');

  set formatter(ArgumentFormatter value) => this['formatter'] = value;

  String get context => _safely('context');

  set context(String value) => this['context'] = value;

  int get count => _safely('count');

  set count(int value) => this['count'] = value;

  /// Creates a new instance of [I18NextOptions] which overrides this
  /// instance's values for [other]'s values when they aren't null.
  ///
  /// If [other] is null, returns this instance.
  I18NextOptions apply(Map<String, Object> other) {
    if (other == null) return this;
    return I18NextOptions.from(this)..addAll(other);
  }

  /// Simply returns [value] in string form. Ignores [format] and [locale].
  static String defaultFormatter(Object value, String format, Locale locale) =>
      value.toString();
}
