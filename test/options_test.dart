import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/src/options.dart';

void main() {
  test('default values', () {
    final options = I18NextOptions.base;
    expect(options.namespaceSeparator, ':');
    expect(options.contextSeparator, '_');

    expect(options.interpolationPrefix, r'\{\{');
    expect(options.interpolationSuffix, r'\}\}');
    expect(options.interpolationSeparator, ',');

    expect(options.nestingPrefix, r'\$t\(');
    expect(options.nestingSuffix, r'\)');
    expect(options.nestingSeparator, ',');

    expect(options.pluralSuffix, '_plural');

    expect(options.formatter, I18NextOptions.defaultFormatter);
  });

  group('constructor', () {
    test('given no values', () {
      expect(I18NextOptions(), isEmpty);
    });
  });

  group('.from', () {
    test('given null', () {
      expect(() => I18NextOptions.from(null), throwsNoSuchMethodError);
    });

    test('creates a new copy', () {
      final original = <String, Object>{'my': 'value'};
      final options = I18NextOptions.from(original);
      original['another'] = 'value';
      expect(options, isNot(equals(original)));
    });

    test('given unmatching property value', () {
      const original = <String, Object>{'namespaceSeparator': 9.99};
      final options = I18NextOptions.from(original);
      expect(options['namespaceSeparator'], 9.99);
      expect(options.namespaceSeparator, isNull);
    });
  });

  test('.defaultFormatter', () {
    const formatter = I18NextOptions.defaultFormatter;
    expect(formatter('My value', null, null), 'My value');
    expect(formatter(9876.1234, null, null), '9876.1234');

    const object = {'my': 'value'};
    expect(formatter(object, null, null), object.toString());

    final date = DateTime.now();
    expect(formatter(date, null, null), date.toString());
  });

  group('#apply', () {
    final base = I18NextOptions.base;
    final empty = I18NextOptions();
    final another = I18NextOptions(
      namespaceSeparator: '',
      contextSeparator: '',
      interpolationPrefix: '',
      interpolationSuffix: '',
      interpolationSeparator: '',
      nestingPrefix: '',
      nestingSuffix: '',
      nestingSeparator: '',
      pluralSuffix: '',
      formatter: (value, format, locale) => null,
    );

    test('given equal', () {
      expect(base.apply(base), base);
      expect(empty.apply(empty), empty);
      expect(another.apply(another), another);
    });

    test('from empty given full', () {
      expect(empty.apply(base), base);
      expect(empty.apply(another), another);
    });

    test('from full given empty', () {
      expect(base.apply(empty), base);
      expect(another.apply(empty), another);
    });

    test('from full given full', () {
      expect(base.apply(another), another);
      expect(another.apply(base), base);
    });

    test('given null', () {
      expect(base.apply(null), base);
      expect(empty.apply(null), empty);
      expect(another.apply(null), another);
    });
  });
}
