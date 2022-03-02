import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:i18next/interpolator.dart';

void main() {
  const baseOptions = I18NextOptions.base;
  const defaultLocale = Locale('en');

  group('interpolate', () {
    String interpol(
      String string, {
      Map<String, dynamic> variables = const {},
      Locale locale = defaultLocale,
      ArgumentFormatter? formatter,
    }) {
      final options = baseOptions.copyWith(formatter: formatter);
      return interpolate(locale, string, variables, options);
    }

    final throwsInterpolationException = throwsA(isA<InterpolationException>());

    ArgumentFormatter noFormatterCalls() =>
        expectAsync3((key, a, b) => fail('Should not have been called'),
            count: 0);

    test('given a non matching string', () {
      expect(
        interpol(
          'This is a normal string',
          formatter: noFormatterCalls(),
        ),
        'This is a normal string',
      );
    });

    group('given a matching string', () {
      test('without variable or format', () {
        expect(
          () => interpol(
            'This is a {{}} string',
            formatter: noFormatterCalls(),
          ),
          throwsInterpolationException,
        );
      });

      group('with variable only', () {
        test('without replaceable variables', () {
          expect(
            () => interpol(
              'This is a {{variable}} string',
              formatter: noFormatterCalls(),
            ),
            throwsInterpolationException,
          );
        });

        test('with replaceable variables', () {
          expect(
            interpol(
              'This is a {{variable}} string',
              variables: {'variable': 'my variable'},
              formatter: expectAsync3((variable, format, locale) {
                expect(variable, 'my variable');
                expect(format, isNull);
                expect(locale, defaultLocale);
                return 'VALUE';
              }),
            ),
            'This is a VALUE string',
          );
        });

        test('with replaceable grouped variables', () {
          expect(
            interpol(
              'This is a {{grouped.key.variable}} string',
              variables: {
                'grouped': {
                  'key': {'variable': 'grouped variable'}
                }
              },
            ),
            'This is a grouped variable string',
          );
        });

        test('with partially matching replaceable grouped variables', () {
          expect(
            () => interpol(
              'This is a {{grouped.key.variable}} string',
              variables: {
                'grouped': {'key': 'grouped variable'}
              },
            ),
            throwsInterpolationException,
          );
        });

        test('without replaceable variables', () {
          expect(
            () => interpol(
              'This is a {{variable}} string',
              variables: {'another': 'value'},
              formatter: noFormatterCalls(),
            ),
            throwsInterpolationException,
          );
        });
      });

      test('with format only', () {
        expect(
          () => interpol(
            'This is a {{, some format}} string',
            formatter: noFormatterCalls(),
          ),
          throwsInterpolationException,
        );
      });

      test('with variable and format and replaceable variables', () {
        expect(
          interpol(
            'This is a {{variable, format}} string',
            variables: {'variable': 'my variable'},
            formatter: expectAsync3((variable, format, locale) {
              expect(variable, 'my variable');
              expect(format, 'format');
              expect(locale, defaultLocale);
              return 'VALUE';
            }),
          ),
          'This is a VALUE string',
        );
      });

      test('given locale', () {
        const anotherLocale = Locale('any');
        expect(
          interpol(
            'This is a {{variable}} string',
            locale: anotherLocale,
            variables: {'variable': 'my variable'},
            formatter: expectAsync3((variable, format, locale) {
              expect(variable, 'my variable');
              expect(format, isNull);
              expect(locale, anotherLocale);
              return 'VALUE';
            }),
          ),
          'This is a VALUE string',
        );
      });
    });
  });

  group('nest', () {
    String? nst(
      String string, {
      Locale locale = defaultLocale,
      Map<String, Object> variables = const {},
      Translate translate = _defaultTranslate,
      I18NextOptions options = baseOptions,
    }) {
      return nest(locale, string, translate, variables, options);
    }

    final throwsNestingException = throwsA(isA<NestingException>());

    Translate noTranslateCalls() =>
        expectAsync4((key, a, b, c) => fail('Should not have been called'),
            count: 0);

    test('given a non matching string', () {
      expect(
        nst(
          'This is my unmatching string',
          translate: noTranslateCalls(),
        ),
        'This is my unmatching string',
      );
    });

    group('given a nesting string', () {
      test('without key or variables', () {
        expect(
          () => nst(
            r'This is my $t() string',
            translate: noTranslateCalls(),
          ),
          throwsNestingException,
        );
      });

      test('with key only', () {
        expect(
          nst(
            r'This is my $t(key) string',
            translate: expectAsync4((key, b, c, d) {
              expect(key, 'key');
              return 'VALUE';
            }),
          ),
          r'This is my VALUE string',
        );
      });

      test('with variables only', () {
        expect(
          () => nst(
            r'This is my $t(, {"x": "y"}) string',
            translate: noTranslateCalls(),
          ),
          throwsNestingException,
        );
      });

      group('with key+variables', () {
        group('when variables are a well formed json', () {
          const string = r'This is my $t(key, {"x":"y"}) string';

          test('the deserialized variables are passed', () {
            expect(
              nst(
                r'This is my $t(key, {"x":"y"}) string',
                translate: expectAsync4((key, b, variables, d) {
                  expect(key, 'key');
                  expect(variables, {'x': 'y'});
                  return 'VALUE';
                }),
              ),
              'This is my VALUE string',
            );

            expect(
              nst(
                r'This is my $t(key, {"x":"\t\ny\n\t"}) string',
                translate: expectAsync4((key, b, variables, d) {
                  expect(key, 'key');
                  expect(variables, {'x': '\t\ny\n\t'});
                  return 'VALUE';
                }),
              ),
              'This is my VALUE string',
            );
          });

          test('the new variables are merged with the previous variables', () {
            expect(
              nst(
                string,
                variables: const {'x': 'x', 'y': 'y', 'z': 'z'},
                translate: expectAsync4((key, b, variables, d) {
                  expect(key, 'key');
                  expect(
                    variables,
                    // overridden "x" for "y"
                    {'x': 'y', 'y': 'y', 'z': 'z'},
                  );
                  return 'VALUE';
                }),
              ),
              'This is my VALUE string',
            );
          });
        });

        test('when variables are a malformed json', () {
          expect(
            () => nst(
              r'This is my $t(key, "x") string',
              translate: noTranslateCalls(),
            ),
            throwsA(isA<TypeError>()),
          );
        });
      });

      test('with multiple split points', () {
        expect(
          () => nst(
            r'This is my $t(key, {"a":"a"}, {"b":"b"}) string',
            translate: noTranslateCalls(),
          ),
          throwsFormatException,
        );
      });

      test('given locale and options', () {
        const locale = Locale('any');

        expect(
          nst(
            r'This is my $t(key) string',
            locale: locale,
            options: baseOptions,
            translate: expectAsync4((key, loc, variables, options) {
              expect(loc, locale);
              expect(options, baseOptions);
              return 'VALUE';
            }),
          ),
          r'This is my VALUE string',
        );
      });
    });

    group('with multiple nestings', () {
      test('and both succeed', () {
        final returnValues = {
          'key': 'VALUE',
          'anotherKey': 'ANOTHER VALUE',
        };

        expect(
          nst(
            r'This is my $t(key) and $t(anotherKey, {"a":"A"}) string',
            translate: (key, b, c, d) => returnValues[key],
          ),
          r'This is my VALUE and ANOTHER VALUE string',
        );
      });

      test('and one fails', () {
        expect(
          () => nst(
            r'This is my $t(key) and $t(unknown) string',
            translate: (key, b, c, d) => key == 'key' ? 'VALUE' : null,
          ),
          throwsNestingException,
        );
      });
    });
  });

  group('interpolationPattern', () {
    final pattern = interpolationPattern(baseOptions);

    List<List<String?>> allMatches(String text) =>
        pattern.allMatches(text).map((match) => [match[1]]).toList();

    test('default pattern', () {
      expect(
        pattern.pattern,
        r'\{\{(.*?)\}\}',
      );
    });

    test('when has only one match without format', () {
      expect(allMatches('My text has {{one}} match'), [
        ['one']
      ]);
      expect(allMatches('My text has {{   one}} match'), [
        ['   one']
      ]);
      expect(allMatches('My text has {{one   }} match'), [
        ['one   ']
      ]);
      expect(allMatches('My text has {{  one  }} match'), [
        ['  one  ']
      ]);
      expect(allMatches('My text has {{\n\tone\n\t}} match'), [
        ['\n\tone\n\t']
      ]);
    });

    test('when has only one match with format', () {
      expect(allMatches('My text has {{one, Xyz}} match'), [
        ['one, Xyz']
      ]);
    });

    test('when has only one match with format with whitespaces', () {
      expect(allMatches('My text has {{one,   Xyz}} match'), [
        ['one,   Xyz']
      ]);
      expect(allMatches('My text has {{one, Xyz   }} match'), [
        ['one, Xyz   ']
      ]);
      expect(allMatches('My text has {{one,    Xyz   }} match'), [
        ['one,    Xyz   ']
      ]);
      expect(allMatches('My text has {{one, \n\tXyz\n\t}} match'), [
        ['one, \n\tXyz\n\t']
      ]);
    });

    test('when has multiple matches without formats', () {
      expect(allMatches('My {{text}} {{has}} {{four}} {{matches}}'), [
        ['text'],
        ['has'],
        ['four'],
        ['matches']
      ]);
    });

    test('when has multiple matches with formats', () {
      expect(
        allMatches(
          'My {{text, Aaa}} {{has, Bbb}} {{four, Ccc}} {{matches, Ddd}}',
        ),
        [
          ['text, Aaa'],
          ['has, Bbb'],
          ['four, Ccc'],
          ['matches, Ddd']
        ],
      );
    });

    test('when has multiple mixed matches', () {
      final matches = allMatches(
        'My {{text}} {{has, Bbb}} {{four, Ccc}} {{matches}}',
      );

      expect(matches, [
        ['text'],
        ['has, Bbb'],
        ['four, Ccc'],
        ['matches']
      ]);
    });
  });

  group('nestingPattern', () {
    final pattern = nestingPattern(baseOptions);

    List<List<String?>> allMatches(String text) {
      return pattern.allMatches(text).map((match) => [match[1]]).toList();
    }

    test('default pattern', () {
      expect(
        pattern.pattern,
        r'\$t\((.*?)\)',
      );
    });

    test('when has only one match without variables', () {
      expect(allMatches(r'My text has $t(one) match'), [
        ['one']
      ]);
    });

    test('when has only one match with variables', () {
      expect(allMatches(r'My text has $t(one, {"my": "values"}) match'), [
        ['one, {"my": "values"}']
      ]);
      expect(
          allMatches('My text has \$t(one, {"my": "Asd\t\nvalues\t\n"}) match'),
          [
            ['one, {"my": "Asd\t\nvalues\t\n"}']
          ]);
    });

    test('when has only one match with variables and whitespaces', () {
      expect(allMatches(r'My text has $t(one,   Xyz) match'), [
        ['one,   Xyz']
      ]);
      expect(allMatches(r'My text has $t(one, Xyz   ) match'), [
        ['one, Xyz   ']
      ]);
      expect(allMatches(r'My text has $t(one,    Xyz   ) match'), [
        ['one,    Xyz   ']
      ]);
      expect(allMatches('My text has \$t(one, \t\nXyz\t\n) match'), [
        ['one, \t\nXyz\t\n']
      ]);
    });

    test('when has multiple matches without formats', () {
      expect(allMatches(r'My $t(text) $t(has) $t(four) $t(matches)'), [
        ['text'],
        ['has'],
        ['four'],
        ['matches']
      ]);
    });

    test('when has multiple matches with formats', () {
      expect(
        allMatches(
          r'My $t(text, Aaa) $t(has, Bbb) $t(four, Ccc) $t(matches, Ddd)',
        ),
        [
          ['text, Aaa'],
          ['has, Bbb'],
          ['four, Ccc'],
          ['matches, Ddd']
        ],
      );
    });

    test('when has multiple mixed matches', () {
      final matches = allMatches(
        r'My $t(text) $t(has, Bbb) $t(four, Ccc) $t(matches)',
      );

      expect(matches, [
        ['text'],
        ['has, Bbb'],
        ['four, Ccc'],
        ['matches']
      ]);
    });
  });
}

String? _defaultTranslate(
  String key,
  Locale locale,
  Map<String, dynamic> variables,
  I18NextOptions options,
) =>
    key;
