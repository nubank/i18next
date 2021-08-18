import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/src/options.dart';

void main() {
  const base = I18NextOptions.base;

  test('default values', () {
    const options = I18NextOptions();
    expect(options.namespaceSeparator, isNull);
    expect(options.contextSeparator, isNull);
    expect(options.pluralSeparator, isNull);
    expect(options.keySeparator, isNull);
    expect(options.interpolationPrefix, isNull);
    expect(options.interpolationSuffix, isNull);
    expect(options.interpolationSeparator, isNull);
    expect(options.nestingPrefix, isNull);
    expect(options.nestingSuffix, isNull);
    expect(options.nestingSeparator, isNull);
    expect(options.pluralSuffix, isNull);
    expect(options.formatter, isNull);
  });

  test('default base values', () {
    expect(base.namespaceSeparator, ':');
    expect(base.contextSeparator, '_');
    expect(base.pluralSeparator, '_');
    expect(base.keySeparator, '.');
    expect(base.interpolationPrefix, '{{');
    expect(base.interpolationSuffix, '}}');
    expect(base.interpolationSeparator, ',');
    expect(base.nestingPrefix, r'$t(');
    expect(base.nestingSuffix, ')');
    expect(base.nestingSeparator, ',');
    expect(base.pluralSuffix, 'plural');
    expect(base.formatter, I18NextOptions.defaultFormatter);
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

  group('#merge', () {
    const empty = I18NextOptions();
    final another = I18NextOptions(
      fallbackNamespaces: ['Some fallbackNamespace'],
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

    test('given no values', () {
      expect(base.merge(base), base);
      expect(base.copyWith(), base);
      expect(empty.merge(empty), empty);
      expect(another.copyWith(), another);
      expect(another.merge(another), another);
    });

    test('from empty given full', () {
      expect(empty.merge(base), base);
      expect(empty.merge(another), another);
    });

    test('from full given empty', () {
      expect(base.merge(empty), base);
      expect(another.merge(empty), another);
    });

    test('from full given full', () {
      expect(base.merge(another), another);
      expect(another.merge(another), another);
    });

    test('given null', () {
      expect(base.merge(null), equals(base));
      expect(empty.merge(null), empty);
      expect(another.merge(null), another);

      expect(identical(base.merge(null), base), isTrue);
    });
  });

  group('#copyWith', () {
    final another = I18NextOptions(
      fallbackNamespaces: ['Some fallbackNamespace'],
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
      another.fallbackNamespaces!,
      another.namespaceSeparator!,
      another.contextSeparator!,
      another.pluralSeparator!,
      another.keySeparator!,
      another.interpolationPrefix!,
      another.interpolationSuffix!,
      another.interpolationSeparator!,
      another.nestingPrefix!,
      another.nestingSuffix!,
      another.nestingSeparator!,
      another.pluralSuffix!,
    ])) {
      test('given individual values=$permutation', () {
        final result = base.copyWith(
          fallbackNamespaces: permutation[0] as List<String>?,
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
          result.fallbackNamespaces,
          permutation[0] ?? base.fallbackNamespaces,
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
        fallbackNamespaces: another.fallbackNamespaces,
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
