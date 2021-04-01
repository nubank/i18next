import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:i18next/interpolator.dart';

void main() {
  const baseOptions = I18NextOptions.base;
  const defaultFormatter = I18NextOptions.defaultFormatter;
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

    test('given a non matching string', () {
      expect(
        interpol(
          'This is a normal string',
          formatter: expectAsync3(defaultFormatter, count: 0),
        ),
        'This is a normal string',
      );
    });

    group('given a matching string', () {
      test('without variable or format', () {
        expect(
          interpol(
            'This is a {{}} string',
            formatter: expectAsync3(defaultFormatter, count: 0),
          ),
          'This is a {{}} string',
        );
      });

      group('with variable only', () {
        test('without variables', () {
          expect(
            interpol(
              'This is a {{variable}} string',
              formatter: expectAsync3(defaultFormatter, count: 0),
            ),
            'This is a {{variable}} string',
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
            interpol(
              'This is a {{grouped.key.variable}} string',
              variables: {
                'grouped': {'key': 'grouped variable'}
              },
            ),
            'This is a {{grouped.key.variable}} string',
          );
        });

        test('without replaceable variables', () {
          expect(
            interpol(
              'This is a {{variable}} string',
              variables: {'another': 'value'},
              formatter: expectAsync3(defaultFormatter, count: 0),
            ),
            'This is a {{variable}} string',
          );
        });
      });

      test('with format only', () {
        expect(
          interpol(
            'This is a {{, some format}} string',
            formatter: expectAsync3(defaultFormatter, count: 0),
          ),
          'This is a {{, some format}} string',
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
    String nst(
      String string, {
      Locale locale = defaultLocale,
      Map<String, Object> variables = const {},
      Translate translate = _defaultTranslate,
      I18NextOptions options = baseOptions,
    }) {
      return nest(locale, string, translate, variables, options);
    }

    test('given a non matching string', () {
      expect(
        nst(
          'This is my unmatching string',
          translate: expectAsync4(_defaultTranslate, count: 0),
        ),
        'This is my unmatching string',
      );
    });

    group('given a nesting string', () {
      test('without key or variables', () {
        expect(
          nst(
            r'This is my $t() string',
            translate: expectAsync4(_defaultTranslate, count: 0),
          ),
          r'This is my $t() string',
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
          nst(
            r'This is my $t(, {"x": "y"}) string',
            translate: expectAsync4(_defaultTranslate, count: 0),
          ),
          r'This is my $t(, {"x": "y"}) string',
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
            nst(
              r'This is my $t(key, "x") string',
              translate: expectAsync4((key, b, variables, d) {
                expect(key, 'key');
                expect(variables, isEmpty);
                return 'VALUE';
              }),
            ),
            r'This is my VALUE string',
          );
        });
      });

      test('with multiple split points', () {
        expect(
          nst(
            r'This is my $t(key, {"a":"a"}, {"b":"b"}) string',
            translate: expectAsync4((key, b, variables, d) {
              expect(key, 'key');
              expect(variables, isEmpty);
              return 'VALUE';
            }),
          ),
          r'This is my VALUE string',
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
  });

  group('interpolationPattern', () {
    final pattern = interpolationPattern(baseOptions);

    Iterable<List<String?>> allMatches(String text) =>
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

  group('nestingPattern', () {
    final pattern = nestingPattern(baseOptions);

    Iterable<List<String?>> allMatches(String text) =>
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

String? _defaultTranslate(
  String key,
  Locale locale,
  Map<String, dynamic> variables,
  I18NextOptions options,
) =>
    key;
