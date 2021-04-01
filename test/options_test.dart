import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/src/options.dart';

void main() {
  test('default values', () {
    const options = I18NextOptions();
    expect(options.namespaceSeparator, ':');
    expect(options.contextSeparator, '_');
    expect(options.pluralSeparator, '_');
    expect(options.keySeparator, '.');
    expect(options.interpolationPrefix, r'\{\{');
    expect(options.interpolationSuffix, r'\}\}');
    expect(options.interpolationSeparator, ',');
    expect(options.nestingPrefix, r'\$t\(');
    expect(options.nestingSuffix, r'\)');
    expect(options.nestingSeparator, ',');
    expect(options.pluralSuffix, 'plural');
    expect(options.formatter, I18NextOptions.defaultFormatter);
  });

  test('.defaultFormatter', () {
    const format = 'format';
    const locale = Locale('en');
    const formatter = I18NextOptions.defaultFormatter;

    expect(formatter('My value', format, locale), 'My value');
    expect(formatter(9876.1234, format, locale), '9876.1234');

    const object = {'my': 'value'};
    expect(formatter(object, format, locale), object.toString());

    final date = DateTime.now();
    expect(formatter(date, format, locale), date.toString());
  });

  group('#copyWith', () {
    const base = I18NextOptions();
    final another = I18NextOptions(
      fallbackNamespace: 'Some fallbackNamespace',
      namespaceSeparator: 'Some namespaceSeparator',
      contextSeparator: 'Some contextSeparator',
      pluralSeparator: 'Some pluralSeparator',
      keySeparator: 'Some keySeparator',
      interpolationPrefix: 'Some interpolationPrefix',
      interpolationSuffix: 'Some interpolationSuffix',
      interpolationSeparator: 'Some interpolationSeparator',
      nestingPrefix: 'Some nestingPrefix',
      nestingSuffix: 'Some nestingSuffix',
      nestingSeparator: 'Some nestingSeparator',
      pluralSuffix: 'Some pluralSuffix',
      formatter: (value, format, locale) => value.toString(),
    );

    test('equality', () {
      expect(base == base, isTrue);
      expect(another == another, isTrue);
      expect(another == base, isFalse);
    });

    test('given no values', () {
      expect(base.copyWith(), base);
      expect(another.copyWith(), another);
    });

    for (final permutation in _generatePermutations([
      another.fallbackNamespace!,
      another.namespaceSeparator,
      another.contextSeparator,
      another.pluralSeparator,
      another.keySeparator,
      another.interpolationPrefix,
      another.interpolationSuffix,
      another.interpolationSeparator,
      another.nestingPrefix,
      another.nestingSuffix,
      another.nestingSeparator,
      another.pluralSuffix,
    ])) {
      test('given individual values=$permutation', () {
        final result = base.copyWith(
          fallbackNamespace: permutation[0] as String?,
          namespaceSeparator: permutation[1] as String?,
          contextSeparator: permutation[2] as String?,
          pluralSeparator: permutation[3] as String?,
          keySeparator: permutation[4] as String?,
          interpolationPrefix: permutation[5] as String?,
          interpolationSuffix: permutation[6] as String?,
          interpolationSeparator: permutation[7] as String?,
          nestingPrefix: permutation[8] as String?,
          nestingSuffix: permutation[9] as String?,
          nestingSeparator: permutation[10] as String?,
          pluralSuffix: permutation[11] as String?,
        );
        // at least one should be different
        expect(result, isNot(base));
        expect(
          result.fallbackNamespace,
          permutation[0] ?? base.fallbackNamespace,
        );
        expect(
          result.namespaceSeparator,
          permutation[1] ?? base.namespaceSeparator,
        );
        expect(
          result.contextSeparator,
          permutation[2] ?? base.contextSeparator,
        );
        expect(
          result.pluralSeparator,
          permutation[3] ?? base.pluralSeparator,
        );
        expect(
          result.keySeparator,
          permutation[4] ?? base.keySeparator,
        );
        expect(
          result.interpolationPrefix,
          permutation[5] ?? base.interpolationPrefix,
        );
        expect(
          result.interpolationSuffix,
          permutation[6] ?? base.interpolationSuffix,
        );
        expect(
          result.interpolationSeparator,
          permutation[7] ?? base.interpolationSeparator,
        );
        expect(
          result.nestingPrefix,
          permutation[8] ?? base.nestingPrefix,
        );
        expect(
          result.nestingSuffix,
          permutation[9] ?? base.nestingSuffix,
        );
        expect(
          result.nestingSeparator,
          permutation[10] ?? base.nestingSeparator,
        );
        expect(
          result.pluralSuffix,
          permutation[11] ?? base.pluralSuffix,
        );
      });
    }

    test('given all values', () {
      final result = base.copyWith(
        fallbackNamespace: another.fallbackNamespace,
        namespaceSeparator: another.namespaceSeparator,
        contextSeparator: another.contextSeparator,
        pluralSeparator: another.pluralSeparator,
        keySeparator: another.keySeparator,
        pluralSuffix: another.pluralSuffix,
        interpolationPrefix: another.interpolationPrefix,
        interpolationSuffix: another.interpolationSuffix,
        interpolationSeparator: another.interpolationSeparator,
        nestingPrefix: another.nestingPrefix,
        nestingSuffix: another.nestingSuffix,
        nestingSeparator: another.nestingSeparator,
        formatter: another.formatter,
      );
      expect(result, another);
    });
  });
}

/// Generates a list of [input]s with just one non-null value
List<List<Object?>> _generatePermutations(List<Object> input) {
  final result = <List<Object?>>[];
  for (var index = 0; index < input.length; index += 1) {
    final alteredInput = List<Object?>.filled(input.length, null);
    alteredInput[index] = input[index];
    result.add(alteredInput);
  }
  return result;
}
