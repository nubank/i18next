import 'dart:ui';

import 'options.dart';
import 'translator.dart';
import 'utils.dart';

/// It translates the i18next localized format in your localization objects
/// (provided by [dataSource]) to the final translation.
///
/// Usually the most common usage:
///
/// ```dart
/// // {
/// //   "key": "My text",
/// //   "nested": { "key": "My nested text" }
/// // }
/// I18Next.localization('key') // -> 'My text'
/// I18Next.localization('nested.key') // -> 'My nested text'
/// ```
///
/// It also allows the usage of namespaces (as long as they are provided by
/// [dataSource]:
///
/// ```dart
/// // common.json
/// // { "continue": "Continue" }
/// // feature.json
/// // { "title": "My feature Title" }
/// I18Next.t('common:continue') // -> 'Continue'
/// I18Next.t('feature:title') // -> 'My feature title'
/// ```
class I18Next {
  I18Next(this.locale, this.dataSource, {I18NextOptions options})
      : assert(dataSource != null),
        options = I18NextOptions.base.apply(options);

  /// The current [Locale] for this instance.
  ///
  /// It is used as the default locale for pluralization rules and [dataSource].
  final Locale locale;

  /// Called when a key and namespace were identified and requires the namespace
  /// object to retrieve the key.
  ///
  /// If null in debug mode throws an assertion error, in release mode  it'll
  /// just fallback to the key used.
  final LocalizationDataSource dataSource;

  /// The options used to find and format matching interpolations.
  final I18NextOptions options;

  /// Attempts to retrieve a translation at [key].
  ///
  /// - If [context] is given, then attempts to search for the key
  ///   at 'key_context', before defaulting to the [key] itself. It is useful
  ///   for selections like gender.
  /// - If [count] is given, then based on [locale] attempts to find the
  ///   appropriate pluralized key, before defaulting to the [key] itself.
  ///   Most languages like `en` have only `one` and `other` pluralization
  ///   forms but some like `ar` require a more complex system.
  /// - If [variables] are given, they are used as a lookup table when a match
  ///   has been found (delimited by [I18NextOptions.interpolationPrefix] and
  ///   [I18NextOptions.interpolationSuffix]). Before the result is added to
  ///   the final message, it first goes through [I18NextOptions.formatter].
  /// - If [locale] is given, it overrides the current locale value.
  /// - If [options] is given, it overrides any non-null property over current
  ///   options.
  ///
  /// Keys that allow both contextualization and pluralization must be declared
  /// in the order: `key_context_plural`
  String t(
    String key, {
    String context,
    int count,
    Map<String, Object> variables,
    Locale locale,
    I18NextOptions options,
  }) {
    assert(key != null);
    variables ??= {};
    if (count != null) variables['count'] ??= count;
    if (context != null) variables['context'] ??= context;

    final newOptions = I18NextOptions.from(this.options.apply(options))
      ..addAll(variables);
    return Translator(locale ?? this.locale, dataSource)
            .translate(key, newOptions) ??
        key;
  }
}
