import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'options.dart';
import 'plural_resolver.dart';
import 'resource_store.dart';
import 'translator.dart';

/// It translates the i18next localized format in your localization objects
/// (provided by [resourceStore]) to the final translation.
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
  I18Next(this.locale, this.resourceStore, {I18NextOptions? options})
      : pluralResolver = const PluralResolver(),
        options = I18NextOptions.base.merge(options);

  /// The current and default [Locale] for this instance.
  final Locale locale;

  /// The resources store that contains all the necessary values mapped by
  /// [Locale], namespace, and keys.
  final ResourceStore resourceStore;

  /// The pluralization resolver.
  final PluralResolver pluralResolver;

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
  /// The named parameters in this method that are also declared by
  /// [I18NextOptions] supersede [options]'s values.
  ///
  /// Keys that allow both contextualization and pluralization must be declared
  /// in the order: `key_context_plural`
  String t(
    String key, {
    Locale? locale,
    String? context,
    int? count,
    Map<String, dynamic>? variables,
    I18NextOptions? options,
  }) {
    variables ??= {};
    if (context != null) variables['context'] = context;
    if (count != null) variables['count'] = count;

    locale ??= this.locale;
    final newOptions = this.options.merge(options);

    // TODO: when translator fails, allow a fallback behavior (null or throw)
    return Translator(pluralResolver, resourceStore)
            .call(key, locale, variables, newOptions) ??
        key;
  }

  /// Returns the localized [I18Next] in the widget tree that corresponds to
  /// the given [context] via [Localizations].
  ///
  /// Returns null if not found.
  ///
  /// An instance is usually registered and created by the
  /// [I18NextLocalizationDelegate].
  static I18Next? of(BuildContext context) =>
      Localizations.of(context, I18Next);
}
