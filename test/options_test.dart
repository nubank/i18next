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

  group('#interpolationPattern', () {
    final options = I18NextOptions.base;

    Iterable<List<String>> allMatches(String text) =>
        options.interpolationPattern.allMatches(text).map((match) => [
              match.namedGroup('variable'),
              match.namedGroup('format'),
            ]);

    test('default pattern', () {
      expect(
        options.interpolationPattern.pattern,
        r'\{\{(?<variable>.*?)(,\s*(?<format>.*?)\s*)?\}\}',
      );
    });

    test('when has only one match without format', () {
      expect(allMatches('My text has {{one}} match'), [
        ['one', null]
      ]);
    });

    test('when has only one match with format', () {
      expect(allMatches('My text has {{one, Xyz}} match'), [
        ['one', 'Xyz']
      ]);
    });

    test('when has only one match with format with whitespaces', () {
      expect(allMatches('My text has {{one,   Xyz}} match'), [
        ['one', 'Xyz']
      ]);
      expect(allMatches('My text has {{one, Xyz   }} match'), [
        ['one', 'Xyz']
      ]);
      expect(allMatches('My text has {{one,    Xyz   }} match'), [
        ['one', 'Xyz']
      ]);
      expect(allMatches('My text has {{one, \nXyz\n}} match'), [
        ['one', 'Xyz']
      ]);
    });

    test('when has multiple matches without formats', () {
      expect(allMatches('My {{text}} {{has}} {{four}} {{matches}}'), [
        ['text', null],
        ['has', null],
        ['four', null],
        ['matches', null]
      ]);
    });

    test('when has multiple matches with formats', () {
      expect(
        allMatches(
          'My {{text, Aaa}} {{has, Bbb}} {{four, Ccc}} {{matches, Ddd}}',
        ),
        [
          ['text', 'Aaa'],
          ['has', 'Bbb'],
          ['four', 'Ccc'],
          ['matches', 'Ddd']
        ],
      );
    });

    test('when has multiple mixed matches', () {
      final matches = allMatches(
        'My {{text}} {{has, Bbb}} {{four, Ccc}} {{matches}}',
      );

      expect(matches, [
        ['text', null],
        ['has', 'Bbb'],
        ['four', 'Ccc'],
        ['matches', null]
      ]);
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
