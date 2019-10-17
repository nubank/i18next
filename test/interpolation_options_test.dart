import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';

void main() {
  const defaultPrefix = '{{', defaultSuffix = '}}';

  InterpolationOptions interpolation;

  setUp(() {
    interpolation = InterpolationOptions();
  });

  Iterable<Match> allMatches(String text) =>
      interpolation.pattern.allMatches(text);

  group('default pattern', () {
    test('when has only one match', () {
      final matches = allMatches('My text has {{one}} match');
      expect(matches.map((match) => match.group(0)), ['{{one}}']);
      expect(matches.map((match) => match.group(1)), ['one']);
    });

    test('when has multiple matches', () {
      final matches = allMatches('My {{text}} {{has}} {{four}} {{matches}}');
      expect(
        matches.map((match) => match.group(0)),
        ['{{text}}', '{{has}}', '{{four}}', '{{matches}}'],
      );
      expect(
        matches.map((match) => match.group(1)),
        ['text', 'has', 'four', 'matches'],
      );
    });
  });

  test('given prefix null', () {
    expect(() => InterpolationOptions(prefix: null), throwsAssertionError);
  });

  test('given prefix', () {
    interpolation = InterpolationOptions(prefix: 'prefix');
    RegExp pattern = interpolation.pattern;
    expect(pattern.pattern, 'prefix(.*?)$defaultSuffix');
  });

  test('given prefix empty', () {
    interpolation = InterpolationOptions(prefix: '');
    RegExp pattern = interpolation.pattern;
    expect(pattern.pattern, '(.*?)$defaultSuffix');
  });

  test('given suffix null', () {
    expect(() => InterpolationOptions(suffix: null), throwsAssertionError);
  });

  test('given suffix', () {
    interpolation = InterpolationOptions(suffix: 'suffix');
    RegExp pattern = interpolation.pattern;
    expect(pattern.pattern, '$defaultPrefix(.*?)suffix');
  });

  test('given suffix empty', () {
    interpolation = InterpolationOptions(suffix: '');
    RegExp pattern = interpolation.pattern;
    expect(pattern.pattern, '$defaultPrefix(.*?)');
  });

  test('given null', () {
    expect(
      () => InterpolationOptions(formatSeparator: null),
      throwsAssertionError,
    );
  });

  test('given formatSeparator', () {
    interpolation = InterpolationOptions(formatSeparator: 'separator');
    RegExp pattern = interpolation.separatorPattern;
    expect(pattern.pattern, ' *separator *');
  });

  test('given formatSeparator empty', () {
    expect(
      () => InterpolationOptions(formatSeparator: ''),
      throwsAssertionError,
    );
  });

  test('given formatter null', () {
    interpolation = InterpolationOptions(formatter: null);
    expect(interpolation.formatter, isNotNull);
  });

  test('given formatter', () {
    final formatter = expectAsync3((a, b, c) => a.toString(), count: 0);
    interpolation = InterpolationOptions(formatter: formatter);
    expect(interpolation.formatter, formatter);
  });

  test('.defaultFormatter', () {
    const defaultFormatter = InterpolationOptions.defaultFormatter;

    expect(defaultFormatter('My value', null, null), 'My value');
    expect(defaultFormatter(9876.1234, null, null), '9876.1234');

    const object = {'my': 'value'};
    expect(defaultFormatter(object, null, null), object.toString());

    final date = DateTime.now();
    expect(defaultFormatter(date, null, null), date.toString());
  });
}
