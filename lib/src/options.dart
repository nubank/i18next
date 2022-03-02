import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// The formatter signature for [I18NextOptions.formats].
///
/// The [value] can be null if the variable wasn't evaluated properly, giving a
/// chance for the formatter to do something
typedef ValueFormatter = Object? Function(
  Object? value,
  Map<String, Object> formatOptions,
  Locale locale,
  I18NextOptions options,
);

/// Contains all options for [I18Next] to work properly.
class I18NextOptions with Diagnosticable {
  const I18NextOptions({
    this.fallbackNamespaces,
    this.namespaceSeparator,
    this.contextSeparator,
    this.pluralSeparator,
    this.keySeparator,
    this.interpolationPrefix,
    this.interpolationSuffix,
    this.formatSeparator,
    this.nestingPrefix,
    this.nestingSuffix,
    this.nestingOptionsSeparator,
    this.pluralSuffix,
    this.formats = const {},
  }) : super();

  static const I18NextOptions base = I18NextOptions(
    fallbackNamespaces: null,
    namespaceSeparator: ':',
    contextSeparator: '_',
    pluralSeparator: '_',
    keySeparator: '.',
    interpolationPrefix: '{{',
    interpolationSuffix: '}}',
    formatSeparator: ',',
    nestingPrefix: r'$t(',
    nestingSuffix: ')',
    nestingOptionsSeparator: ',',
    pluralSuffix: 'plural',
    formats: {},
  );

  /// The namespaces used to fallback to when no key matches were found on the
  /// current namespace.
  /// These namespaces are evaluated in the order they are put in the list.
  ///
  /// Defaults to null.
  final List<String>? fallbackNamespaces;

  /// The separator used when splitting the key.
  ///
  /// Defaults to ':'.
  final String? namespaceSeparator;

  /// The separator for contexts, it is inserted between the key and the
  /// context value.
  ///
  /// Defaults to '_'.
  final String? contextSeparator;

  /// The separator for plural suffixes, it is inserted between the key and the
  /// plural value ("plural" for simple rules, or a numeric index for complex
  /// rules with multiple plurals).
  ///
  /// Defaults to '_'.
  final String? pluralSeparator;

  /// The separator for nested keys. It is used to denote multiple object
  /// levels of access when retrieving a key from a namespace.
  ///
  /// Defaults to '.'.
  final String? keySeparator;

  /// [pluralSuffix] is used for the pluralization mechanism.
  ///
  /// Defaults to 'plural' and is used for simple pluralization rules.
  ///
  /// For example, in english where it only has singular or plural forms:
  ///
  /// ```
  /// "friend": "A friend"
  /// "friend_plural": "{{count}} friends"
  /// ```
  final String? pluralSuffix;

  /// [interpolationPrefix] and [interpolationSuffix] are the deliminators
  /// for the variable interpolation and formatting mechanism.
  /// By default they are '{{' and '}}' respectively and can't be null but
  /// can be empty.
  ///
  /// [formatSeparator] is used to separate the variable's
  /// name from the format (if any). Defaults to ',' and cannot be null nor
  /// empty (otherwise it'll match every char in the interpolation).
  ///
  /// ```
  /// - '{{title}}' name = 'title, format = null
  /// - '{{title, uppercase}}' name = 'title', format = 'uppercase'
  /// ```
  final String? interpolationPrefix, interpolationSuffix, formatSeparator;

  /// [nestingPrefix] and [nestingSuffix] are the deliminators for nesting
  /// mechanism. By default they are '$t(' and ')' respectively and can't be
  /// null but can be empty.
  ///
  /// [nestingOptionsSeparator] is used to separate the key's name from the
  /// variables (if any) which must be JSON. Defaults to ',' and cannot be null
  /// nor empty (otherwise it'll match every char in the nesting).
  ///
  /// ```json
  /// {
  ///   key1: "Hello $t(key2)!"
  ///   key2: "World"
  /// }
  /// i18Next.t('key1') // "Hello World!"
  /// ```
  final String? nestingPrefix, nestingSuffix, nestingOptionsSeparator;

  /// [formats] are called when interpolations find the right patterns and try
  /// to find the right substitutions.
  ///
  /// If the format doesn't exist then it either moves to the next format or
  /// the value is returned as is (in string form: [Object.toString]).
  final Map<String, ValueFormatter> formats;

  /// Creates a new instance of [I18NextOptions] overriding any properties
  /// where [other] isn't null.
  ///
  /// If [other] is null, returns this.
  I18NextOptions merge(I18NextOptions? other) {
    if (other == null) return this;
    return copyWith(
      fallbackNamespaces: other.fallbackNamespaces ?? fallbackNamespaces,
      namespaceSeparator: other.namespaceSeparator ?? namespaceSeparator,
      contextSeparator: other.contextSeparator ?? contextSeparator,
      pluralSeparator: other.pluralSeparator ?? pluralSeparator,
      keySeparator: other.keySeparator ?? keySeparator,
      pluralSuffix: other.pluralSuffix ?? pluralSuffix,
      interpolationPrefix: other.interpolationPrefix ?? interpolationPrefix,
      interpolationSuffix: other.interpolationSuffix ?? interpolationSuffix,
      formatSeparator: other.formatSeparator ?? formatSeparator,
      nestingPrefix: other.nestingPrefix ?? nestingPrefix,
      nestingSuffix: other.nestingSuffix ?? nestingSuffix,
      nestingOptionsSeparator:
          other.nestingOptionsSeparator ?? nestingOptionsSeparator,
      formats: {...formats, ...other.formats},
    );
  }

  /// Creates a new instance of [I18NextOptions] overriding any of the
  /// properties that aren't null.
  I18NextOptions copyWith({
    List<String>? fallbackNamespaces,
    String? namespaceSeparator,
    String? contextSeparator,
    String? pluralSeparator,
    String? keySeparator,
    String? pluralSuffix,
    String? interpolationPrefix,
    String? interpolationSuffix,
    String? formatSeparator,
    String? nestingPrefix,
    String? nestingSuffix,
    String? nestingOptionsSeparator,
    Map<String, ValueFormatter>? formats,
  }) {
    return I18NextOptions(
      fallbackNamespaces: fallbackNamespaces ?? this.fallbackNamespaces,
      namespaceSeparator: namespaceSeparator ?? this.namespaceSeparator,
      contextSeparator: contextSeparator ?? this.contextSeparator,
      pluralSeparator: pluralSeparator ?? this.pluralSeparator,
      keySeparator: keySeparator ?? this.keySeparator,
      pluralSuffix: pluralSuffix ?? this.pluralSuffix,
      interpolationPrefix: interpolationPrefix ?? this.interpolationPrefix,
      interpolationSuffix: interpolationSuffix ?? this.interpolationSuffix,
      formatSeparator: formatSeparator ?? this.formatSeparator,
      nestingPrefix: nestingPrefix ?? this.nestingPrefix,
      nestingSuffix: nestingSuffix ?? this.nestingSuffix,
      nestingOptionsSeparator:
          nestingOptionsSeparator ?? this.nestingOptionsSeparator,
      formats: formats ?? this.formats,
    );
  }

  @override
  int get hashCode => hashValues(
        fallbackNamespaces,
        namespaceSeparator,
        contextSeparator,
        pluralSeparator,
        keySeparator,
        interpolationPrefix,
        interpolationSuffix,
        formatSeparator,
        nestingPrefix,
        nestingSuffix,
        nestingOptionsSeparator,
        pluralSuffix,
        formats,
      );

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is I18NextOptions &&
      other.fallbackNamespaces == fallbackNamespaces &&
      other.namespaceSeparator == namespaceSeparator &&
      other.contextSeparator == contextSeparator &&
      other.pluralSeparator == pluralSeparator &&
      other.keySeparator == keySeparator &&
      other.interpolationPrefix == interpolationPrefix &&
      other.interpolationSuffix == interpolationSuffix &&
      other.formatSeparator == formatSeparator &&
      other.nestingPrefix == nestingPrefix &&
      other.nestingSuffix == nestingSuffix &&
      other.nestingOptionsSeparator == nestingOptionsSeparator &&
      other.pluralSuffix == pluralSuffix &&
      const MapEquality().equals(other.formats, formats);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty('fallbackNamespaces', fallbackNamespaces))
      ..add(StringProperty('namespaceSeparator', namespaceSeparator))
      ..add(StringProperty('contextSeparator', contextSeparator))
      ..add(StringProperty('pluralSeparator', pluralSeparator))
      ..add(StringProperty('keySeparator', keySeparator))
      ..add(StringProperty('interpolationPrefix', interpolationPrefix))
      ..add(StringProperty('interpolationSuffix', interpolationSuffix))
      ..add(StringProperty('formatSeparator', formatSeparator))
      ..add(StringProperty('nestingPrefix', nestingPrefix))
      ..add(StringProperty('nestingSuffix', nestingSuffix))
      ..add(StringProperty('nestingOptionsSeparator', nestingOptionsSeparator))
      ..add(StringProperty('pluralSuffix', pluralSuffix))
      ..add(StringProperty('formats', formats.toString()));
  }
}
