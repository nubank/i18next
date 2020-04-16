import 'dart:ui';

import 'options.dart';

/// A callback function to determine if exists
/// the key for an specifc plural modifier
typedef KeyExists = bool Function(
  String pluralModifier,
);

class PluralResolver {
  PluralResolver() : super();

  /// Returns the plural suffix based on [count] and presented [options].
  String pluralize(
    int count,
    I18NextOptions options,
    KeyExists validateKey,
  ) {
    final shouldLookForPluralKeys = count != 1;
    const resultForNonRequiredPlural = '';

    return shouldLookForPluralKeys
        ? _pluralKey(count, options, validateKey)
        : resultForNonRequiredPlural;
  }

  String _pluralKey(
    int count,
    I18NextOptions options,
    KeyExists validateKey,
  ) {
    final baseKey = '${options.pluralSeparator}${options.pluralSuffix}';
    final specicPluralKey = '${options.pluralSeparator}$count';
    final existSpecicPlural = validateKey(specicPluralKey);

    return existSpecicPlural ? specicPluralKey : baseKey;
  }
}
