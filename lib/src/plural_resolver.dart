import 'dart:ui';

import 'options.dart';

/// A callback function to determine if exists
/// the key for an specifc plural modifier
typedef CheckerKeyFunction = bool Function(
  String pluralModifier,
);

class PluralResolver {
  PluralResolver() : super();

  /// Returns the plural suffix based on [count] and presented [options].
  String pluralize(
    int count,
    I18NextOptions options,
    CheckerKeyFunction find,
  ) {
    final shouldLookForPluralKeys = count != 1;
    const resultForNonRequiredPlural = '';

    return !shouldLookForPluralKeys
        ? resultForNonRequiredPlural
        : _pluralKey(count, options, find);
  }

  String _pluralKey(
    int count,
    I18NextOptions options,
    CheckerKeyFunction find,
  ) {
    final baseKey = '${options.pluralSeparator}${options.pluralSuffix}';
    final specicPluralKey = '$baseKey${options.pluralSeparator}$count';
    final existSpecicPlural = find(specicPluralKey);

    return existSpecicPlural ? specicPluralKey : baseKey;
  }
}
