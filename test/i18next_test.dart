import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';

void main() {
  const locale = Locale('en');
  I18Next i18next;

  tearDown(() {
    i18next = null;
  });

  void given(
    Map<String, Object> data, {
    LocalizationDataSource dataSource,
    ArgumentFormatter formatter,
  }) {
    i18next = I18Next(
      locale,
      dataSource ?? (namespace, locale) => data,
      interpolation: InterpolationOptions(formatter: formatter),
    );
  }

  group('when has multiple namespaces', () {
    const Map<String, Object> namespace1 = {'myKey': 'My first value'},
        namespace2 = {'myKey': 'My second value'};

    test('with multiple namespaces', () {
      i18next = I18Next(
        locale,
        (namespace, loc) {
          switch (namespace) {
            case 'ns1':
              return namespace1;
            case 'ns2':
              return namespace2;
          }
          return null;
        },
      );
      expect(i18next.t('ns1:myKey'), 'My first value');
      expect(i18next.t('ns2:myKey'), 'My second value');
    });
  });

  test('given data source', () {
    i18next = I18Next(
      locale,
      expectAsync2((namespace, loc) {
        expect(namespace, 'ns');
        expect(loc, locale);
        return {'myKey': 'My value'};
      }, count: 1),
    );
    expect(i18next.t('ns:myKey'), 'My value');
  });

  test('given key for unregistered namespace', () {
    i18next = I18Next(locale, (namespace, loc) => null);
    expect(() => i18next.t('ns:myKey'), throwsAssertionError);
  });

  test('given null key', () {
    given({});
    expect(() => i18next.t(null), throwsAssertionError);
  });

  test('given an existing string key', () {
    given({'myKey': 'This is my key'});
    expect(i18next.t('myKey'), 'This is my key');
  });

  test('given a non-existing key', () {
    given({});
    expect(i18next.t('someKey'), 'someKey');
  });

  test('given a nested string key', () {
    given({
      'my': {
        'key': 'This is my key',
        'nested': {
          'key': 'This is a more nested key',
        }
      }
    });
    expect(i18next.t('my.key'), 'This is my key');
    expect(i18next.t('my.nested.key'), 'This is a more nested key');
  });

  test('given a partially matching nested key', () {
    given({
      'my': {
        'nested': {'key': 'This is a more nested key'},
      }
    });
    expect(i18next.t('my'), 'my');
    expect(i18next.t('my.nested'), 'my.nested');
  });

  group('pluralizable data', () {
    setUp(() {
      given(const {
        'friend': 'A friend',
        'friend_plural': '{{count}} friends',
      });
    });

    test('without count', () {
      expect(i18next.t('friend'), 'A friend');
    });

    test('given count', () {
      expect(i18next.t('friend', count: 0), '0 friends');
      expect(i18next.t('friend', count: 1), 'A friend');
      expect(i18next.t('friend', count: -1), '-1 friends');
      expect(i18next.t('friend', count: 99), '99 friends');
    });

    test('given count and unmmaped context', () {
      expect(
        i18next.t('friend', count: 1, context: 'something'),
        'A friend',
      );
      expect(
        i18next.t('friend', count: 99, context: 'something'),
        '99 friends',
      );
    });

    // TODO: add special pluralization rules
  });

  group('contextual data', () {
    setUp(() {
      given(const {
        'friend': 'A friend',
        'friend_male': 'A boyfriend',
        'friend_female': 'A girlfriend',
      });
    });

    test('without context', () {
      expect(i18next.t('friend'), 'A friend');
    });

    test('given mapped context', () {
      expect(i18next.t('friend', context: 'male'), 'A boyfriend');
      expect(i18next.t('friend', context: 'female'), 'A girlfriend');
    });

    test('given unmaped context', () {
      expect(i18next.t('friend', context: 'other'), 'A friend');
    });

    test('given mapped context and count', () {
      expect(
        i18next.t('friend', context: 'male', count: 0),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', context: 'male', count: 1),
        'A boyfriend',
      );
    });

    test('given unmapped context and count', () {
      expect(
        i18next.t('friend', context: 'other', count: 1),
        'A friend',
      );
      expect(
        i18next.t('friend', context: 'other', count: 99),
        'A friend',
      );
    });
  });

  group('contextual and pluralized data', () {
    setUp(() {
      given(const {
        'friend': 'A friend',
        'friend_plural': '{{count}} friends',
        'friend_male': 'A boyfriend',
        'friend_male_plural': '{{count}} boyfriends',
        'friend_female': 'A girlfriend',
        'friend_female_plural': '{{count}} girlfriends',
      });
    });

    test('given mapped context and count', () {
      expect(
        i18next.t('friend', context: 'male', count: 0),
        '0 boyfriends',
      );
      expect(
        i18next.t('friend', context: 'male', count: 1),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', context: 'female', count: 0),
        '0 girlfriends',
      );
      expect(
        i18next.t('friend', context: 'female', count: 1),
        'A girlfriend',
      );
    });

    test('given unmmaped context and count', () {
      expect(
        i18next.t('friend', context: 'other', count: 0),
        '0 friends',
      );
      expect(
        i18next.t('friend', context: 'other', count: 1),
        'A friend',
      );
    });
  });

  group('matching arguments', () {
    setUp(() {
      given(const {'myKey': '{{first}}, {{second}}, and then {{third}}!'});
    });

    test('given non matching arguments', () {
      expect(
        i18next.t('myKey', arguments: {'none': 'none'}),
        '{{first}}, {{second}}, and then {{third}}!',
      );
    });

    test('given partially matching arguments', () {
      expect(
        i18next.t('myKey', arguments: {'first': 'fst'}),
        'fst, {{second}}, and then {{third}}!',
      );
      expect(
        i18next.t('myKey', arguments: {'first': 'fst', 'third': 'trd'}),
        'fst, {{second}}, and then trd!',
      );
    });

    test('given all matching arguments', () {
      expect(
        i18next.t('myKey', arguments: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
        }),
        'fst, snd, and then trd!',
      );
    });

    test('given extra matching arguments', () {
      expect(
        i18next.t('myKey', arguments: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
          'none': 'none',
        }),
        'fst, snd, and then trd!',
      );
    });
  });

  group('given formatter', () {
    test('with no interpolations', () {
      given(
        const {'myKey': 'leading no value trailing'},
        formatter: expectAsync3((value, format, locale) => null, count: 0),
      );
      expect(
        i18next.t('myKey'),
        'leading no value trailing',
      );
    });

    test('with no matching arguments', () {
      given(
        const {'myKey': 'leading {{value, format}} trailing'},
        formatter: expectAsync3((value, format, locale) => value.toString()),
      );
      expect(
        i18next.t('myKey', arguments: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with one matching interpolation', () {
      given(
        const {'myKey': 'leading {{value, format}} trailing'},
        formatter: expectAsync3(
          (value, format, locale) {
            expect(value, 'eulav');
            expect(format, 'format');
            expect(locale, locale);
            return value.toString();
          },
        ),
      );
      expect(
        i18next.t('myKey', arguments: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with multiple matching interpolations', () {
      final values = <String>[];
      final formats = <String>[];
      given(
        const {
          'myKey': 'leading {{value1, format1}} middle '
              '{{value2, format2}} trailing'
        },
        formatter: expectAsync3(
          (value, format, locale) {
            values.add(value);
            formats.add(format);
            return value.toString();
          },
          count: 2,
        ),
      );
      expect(
        i18next.t('myKey', arguments: {
          'value1': '1eulav',
          'value2': '2eulav',
        }),
        'leading 1eulav middle 2eulav trailing',
      );
      expect(values, orderedEquals(<String>['1eulav', '2eulav']));
      expect(formats, orderedEquals(<String>['format1', 'format2']));
    });
  });

  test('given overriding locale', () {
    const data = {'key': 'my value'};
    const anotherLocale = Locale('another');
    i18next = I18Next(locale, expectAsync2((_, loc) {
      expect(loc, anotherLocale);
      return data;
    }));
    expect(i18next.t('key', locale: anotherLocale), 'my value');
  });

  test('given overriding interpolation formatter', () {
    given(
      {'key': 'my {{value}}'},
      formatter: expectAsync3(null, count: 0),
    );
    expect(
      i18next.t(
        'key',
        arguments: {'value': 'new value'},
        interpolation: InterpolationOptions(
          formatter: expectAsync3((value, _, __) {
            expect(value, 'new value');
            return value.toString();
          }),
        ),
      ),
      'my new value',
    );
  });
}
