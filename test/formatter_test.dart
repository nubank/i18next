import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:i18next/src/formatter.dart';

void main() {
  group('format', () {
    const locale = Locale('en');
    late I18NextOptions options;

    setUp(() {
      options = I18NextOptions.base;
    });

    test('given an empty format', () {
      options = options.copyWith(formats: {});
      final result = format('value', [''], locale, options);
      expect(result, 'value');
    });

    group('when there only one format', () {
      test('and the format name is not found', () {
        options = options.copyWith(formats: {});
        final result = format('value', ['formatName'], locale, options);
        expect(result, 'value');
      });

      test('and the format name is found', () {
        options = options.copyWith(formats: {
          'formatName': expectAsync4((value, formatOptions, loc, opt) {
            expect(value, 'my value');
            expect(formatOptions, isEmpty);
            expect(loc, locale);
            expect(opt, options);
            return 'replaced value';
          }, count: 1),
        });
        final result = format('my value', ['formatName'], locale, options);
        expect(result, 'replaced value');
      });

      test('and the format name is found and it throws while formatting', () {
        options = options.copyWith(formats: {
          'formatName': expectAsync4(
            (value, formatOptions, loc, opt) => throw 'Some error',
            count: 1,
          ),
        });
        expect(
          () => format('my value', ['formatName'], locale, options),
          throwsAssertionError,
        );
      });

      test('and the format name is found and it returns null', () {
        options = options.copyWith(formats: {
          'formatName': expectAsync4(
            (value, formatOptions, loc, opt) => null,
            count: 1,
          ),
        });
        expect(
          format('my value', ['formatName'], locale, options),
          isNull,
        );
      });
    });

    group('when there are multiple formats', () {
      test('and finds all format names', () {
        options = options.copyWith(formats: {
          'fmt1': expectAsync4(
            (value, formatOptions, loc, opt) {
              expect(value, 'initial value');
              expect(formatOptions, isEmpty);
              expect(loc, locale);
              expect(opt, options);
              return 'replaced first value';
            },
            count: 1,
          ),
          'fmt2': expectAsync4(
            (value, formatOptions, loc, opt) {
              expect(value, 'replaced first value');
              expect(formatOptions, {'option': 'optValue'});
              expect(loc, locale);
              expect(opt, options);
              return 'replaced second value';
            },
            count: 1,
          ),
          'fmt3': expectAsync4(
            (value, formatOptions, loc, opt) {
              expect(value, 'replaced second value');
              expect(formatOptions, {
                'option1': 'option value 1',
                'option2': 'option value 2',
              });
              expect(loc, locale);
              expect(opt, options);
              return 'replaced third value';
            },
            count: 1,
          ),
        });
        final result = format(
          'initial value',
          [
            'fmt1',
            'fmt2(option:optValue)',
            'fmt3(option1: option value 1; option2: option value 2)'
          ],
          locale,
          options,
        );
        expect(result, 'replaced third value');
      });
    });

    test('and the formats return different types', () {
      options = options.copyWith(formats: {
        'fmt1': expectAsync4(
          (value, formatOptions, loc, opt) {
            expect(value, 'initial value');
            expect(formatOptions, isEmpty);
            expect(loc, locale);
            expect(opt, options);
            return 123.456;
          },
          count: 1,
        ),
        'fmt2': expectAsync4(
          (value, formatOptions, loc, opt) {
            expect(value, 123.456);
            expect(formatOptions, isEmpty);
            expect(loc, locale);
            expect(opt, options);
            return const MapEntry('Some Key', 999);
          },
          count: 1,
        ),
        'fmt3': expectAsync4(
          (value, formatOptions, loc, opt) {
            expect(value, const MapEntry('Some Key', 999));
            expect(formatOptions, isEmpty);
            expect(loc, locale);
            expect(opt, options);
            return ['a', 'b', 'c'];
          },
          count: 1,
        ),
      });
      final result =
          format('initial value', ['fmt1', 'fmt2', 'fmt3'], locale, options);
      expect(result, '[a, b, c]');
    });
  });

  group('parseFormatString', () {
    test('without any arguments', () {
      final result = parseFormatString('formatName');
      expect(result.name, 'formatName');
      expect(result.options, isEmpty);
    });

    test('with empty arguments', () {
      final result = parseFormatString('formatName()');
      expect(result.name, 'formatName');
      expect(result.options, isEmpty);
    });

    test('with one named argument', () {
      final result = parseFormatString('formatName(optionName: optionValue)');
      expect(result.name, 'formatName');
      expect(result.options, {'optionName': 'optionValue'});
    });

    test('with multiple named arguments', () {
      final result = parseFormatString(
        'formatName(optionName1: optionValue1; optionName2: optionValue2)',
      );
      expect(result.name, 'formatName');
      expect(result.options, {
        'optionName1': 'optionValue1',
        'optionName2': 'optionValue2',
      });
    });

    test('trims argument options and values', () {
      final result = parseFormatString(
        ' \t\n formatName   (   \n\toptionName1\n\t : optionValue1  \n\t ;  '
        ' \n\t optionName2  :   \n\toptionValue2\n\t   )   ',
      );
      expect(result.name, 'formatName');
      expect(result.options, {
        'optionName1': 'optionValue1',
        'optionName2': 'optionValue2',
      });
    });

    test('with an empty option', () {
      final result = parseFormatString('formatName(option:)');
      expect(result.name, 'formatName');
      expect(result.options, {'option': ''});
    });

    test('with empty options', () {
      final result = parseFormatString('formatName(option1:;option2:)');
      expect(result.name, 'formatName');
      expect(result.options, {'option1': '', 'option2': ''});
    });

    test('with malformed options', () {
      var result = parseFormatString('formatName(:)');
      expect(result.name, 'formatName');
      expect(result.options, {'': ''});

      result = parseFormatString('formatName(;)');
      expect(result.name, 'formatName');
      expect(result.options, isEmpty);

      result = parseFormatString('formatName(:;)');
      expect(result.name, 'formatName');
      expect(result.options, {'': ''});

      result = parseFormatString('formatName(:;:)');
      expect(result.name, 'formatName');
      expect(result.options, {'': ''});

      result = parseFormatString('formatName(;;)');
      expect(result.name, 'formatName');
      expect(result.options, {});
    });

    test('with bool arguments', () {
      final result = parseFormatString(
        'formatName(optionName1: true; optionName2: false)',
      );
      expect(result.name, 'formatName');
      expect(result.options, {'optionName1': true, 'optionName2': false});
    });

    test('with multiple same named arguments', () {
      final result = parseFormatString(
        'formatName(option: one; option: two)',
      );
      expect(result.name, 'formatName');
      expect(result.options, {'option': 'one'});
    });
  });
}
