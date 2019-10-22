import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:i18next/src/interpolator.dart';

void main() {
  final options = I18NextOptions.base;

  group('.interpolationPattern', () {
    final pattern = Interpolator.interpolationPattern(options);

    Iterable<List<String>> allMatches(String text) =>
        pattern.allMatches(text).map((match) => [
              match.namedGroup('variable'),
              match.namedGroup('format'),
            ]);

    test('default pattern', () {
      expect(
        pattern.pattern,
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

  group('.nestingPattern', () {
    final pattern = Interpolator.nestingPattern(options);

    Iterable<List<String>> allMatches(String text) =>
        pattern.allMatches(text).map((match) => [
              match.namedGroup('key'),
              match.namedGroup('variables'),
            ]);

    test('default pattern', () {
      expect(
        pattern.pattern,
        r'\$t\((?<key>.*?)(,\s*(?<variables>.*?)\s*)?\)',
      );
    });

    test('when has only one match without variables', () {
      expect(allMatches(r'My text has $t(one) match'), [
        ['one', null]
      ]);
    });

    test('when has only one match with variables', () {
      expect(allMatches(r'My text has $t(one, {"my": "values"}) match'), [
        ['one', '{"my": "values"}']
      ]);
    });

    test('when has only one match with variables and whitespaces', () {
      expect(allMatches(r'My text has $t(one,   Xyz) match'), [
        ['one', 'Xyz']
      ]);
      expect(allMatches(r'My text has $t(one, Xyz   ) match'), [
        ['one', 'Xyz']
      ]);
      expect(allMatches(r'My text has $t(one,    Xyz   ) match'), [
        ['one', 'Xyz']
      ]);
      expect(allMatches('My text has \$t(one, \nXyz\n) match'), [
        ['one', 'Xyz']
      ]);
    });

    test('when has multiple matches without formats', () {
      expect(allMatches(r'My $t(text) $t(has) $t(four) $t(matches)'), [
        ['text', null],
        ['has', null],
        ['four', null],
        ['matches', null]
      ]);
    });

    test('when has multiple matches with formats', () {
      expect(
        allMatches(
          r'My $t(text, Aaa) $t(has, Bbb) $t(four, Ccc) $t(matches, Ddd)',
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
        r'My $t(text) $t(has, Bbb) $t(four, Ccc) $t(matches)',
      );

      expect(matches, [
        ['text', null],
        ['has', 'Bbb'],
        ['four', 'Ccc'],
        ['matches', null]
      ]);
    });
  });
}
