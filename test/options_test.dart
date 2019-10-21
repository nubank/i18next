import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/src/options.dart';

void main() {
  test('default values', () {
    final options = I18NextOptions();
    expect(options.namespaceSeparator, ':');

    expect(options.interpolationPrefix, '{{');
    expect(options.interpolationSuffix, '}}');
    expect(options.interpolationSeparator, ',');

    expect(options.pluralSuffix, '_plural');

    expect(options.formatter, I18NextOptions.defaultFormatter);
  });

  test('given interpolationPrefix null', () {
    expect(
      () => I18NextOptions(interpolationPrefix: null),
      throwsAssertionError,
    );
  });

  test('given interpolationPrefix empty', () {
    final options = I18NextOptions(interpolationPrefix: '');
    expect(options.interpolationPrefix, '');
    expect(
      options.interpolationPattern.pattern,
      '(?<variable>.*?)(,\\s*(?<format>.*?)\\s*)?}}',
    );
  });

  test('given interpolationSuffix null', () {
    expect(
      () => I18NextOptions(interpolationSuffix: null),
      throwsAssertionError,
    );
  });

  test('given interpolationSuffix empty', () {
    final options = I18NextOptions(interpolationSuffix: '');
    expect(options.interpolationSuffix, '');
    expect(
      options.interpolationPattern.pattern,
      '{{(?<variable>.*?)(,\\s*(?<format>.*?)\\s*)?',
    );
  });

  group('#interpolationPattern', () {
    final options = I18NextOptions();

    Iterable<List<String>> allMatches(String text) =>
        options.interpolationPattern.allMatches(text).map((match) => [
              match.namedGroup('variable'),
              match.namedGroup('format'),
            ]);

    test('default pattern', () {
      expect(
        options.interpolationPattern.pattern,
        '{{(?<variable>.*?)(,\\s*(?<format>.*?)\\s*)?}}',
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

  test('given formatter null', () {
    final options = I18NextOptions(formatter: null);
    expect(options.formatter, isNotNull);
  });

  test('given formatter', () {
    final formatter = expectAsync3((a, b, c) => a.toString(), count: 0);
    final options = I18NextOptions(formatter: formatter);
    expect(options.formatter, formatter);
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
}
