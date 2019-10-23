import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:mockito/mockito.dart';

class MockResourceStore extends Mock implements ResourceStore {}

void main() {
  const locale = Locale('en');
  I18Next i18next;
  MockResourceStore resourceStore;

  setUp(() {
    resourceStore = MockResourceStore();
    i18next = I18Next(locale, resourceStore);
  });

  void mockKey(String key, String answer, {String ns = ''}) {
    when(resourceStore.retrieve(ns, key, any)).thenReturn(answer);
  }

  group('given named namespaces', () {
    setUp(() {
      mockKey('key', 'My first value', ns: 'ns1');
      mockKey('key', 'My second value', ns: 'ns2');
    });

    test('given key for matching namespaces', () {
      expect(i18next.t('ns1:key'), 'My first value');
      verify(resourceStore.retrieve('ns1', 'key', any));

      expect(i18next.t('ns2:key'), 'My second value');
      verify(resourceStore.retrieve('ns2', 'key', any));
    });

    test('given key for unmatching namespaces', () {
      expect(i18next.t('ns3:key'), 'ns3:key');
      verify(resourceStore.retrieve('ns3', 'key', any));
    });

    test('given key for partially matching namespaces', () {
      expect(i18next.t('ns:key'), 'ns:key');
      verify(resourceStore.retrieve('ns', 'key', any));
    });
  });

  test('given resource store null', () {
    expect(() => I18Next(locale, null), throwsAssertionError);
  });

  test('given resource store', () {
    mockKey('key', 'My value', ns: 'ns');

    expect(i18next.t('ns:key'), 'My value');
    verify(resourceStore.retrieve('ns', 'key', any)).called(1);
  });

  test('given key without namespace', () {
    when(resourceStore.retrieve(any, any, any)).thenReturn(null);

    expect(i18next.t('someKey'), 'someKey');
    expect(i18next.t('some.key'), 'some.key');
  });

  test('given null key', () {
    expect(() => i18next.t(null), throwsAssertionError);
  });

  test('given an existing string key', () {
    mockKey('myKey', 'This is my key');
    expect(i18next.t('myKey'), 'This is my key');
  });

  test('given a non-existing or non matching key', () {
    expect(i18next.t('someKey'), 'someKey');
    expect(i18next.t('some.key'), 'some.key');
  });

  test('given overriding locale', () {
    const anotherLocale = Locale('another');
    mockKey('key', 'my value');

    expect(i18next.t('key', locale: anotherLocale), 'my value');
    verify(resourceStore.retrieve(
      '',
      'key',
      argThat(containsPair('locale', anotherLocale)),
    )).called(1);
  });

  group('given formatter', () {
    test('with no interpolations', () {
      i18next = I18Next(
        locale,
        resourceStore,
        options: I18NextOptions(
          formatter: expectAsync3((value, format, locale) => null, count: 0),
        ),
      );
      mockKey('key', 'no interpolations here');

      expect(i18next.t('key'), 'no interpolations here');
    });

    test('with no matching variables', () {
      i18next = I18Next(
        locale,
        resourceStore,
        options: I18NextOptions(
          formatter: expectAsync3(
            (value, format, locale) => value.toString(),
            count: 0,
          ),
        ),
      );
      mockKey('key', 'leading {{value, format}} trailing');

      expect(
        i18next.t('key', variables: {'name': 'World'}),
        'leading {{value, format}} trailing',
      );
    });

    test('with matching variables', () {
      i18next = I18Next(
        locale,
        resourceStore,
        options: I18NextOptions(
          formatter: expectAsync3((value, format, locale) => value.toString()),
        ),
      );
      mockKey('key', 'leading {{value, format}} trailing');

      expect(
        i18next.t('key', variables: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with one matching interpolation', () {
      i18next = I18Next(
        locale,
        resourceStore,
        options: I18NextOptions(
          formatter: expectAsync3(
            (value, format, locale) {
              expect(value, 'eulav');
              expect(format, 'format');
              expect(locale, locale);
              return value.toString();
            },
          ),
        ),
      );
      mockKey('key', 'leading {{value, format}} trailing');

      expect(
        i18next.t('key', variables: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with multiple matching interpolations', () {
      final values = <String>[];
      final formats = <String>[];
      i18next = I18Next(
        locale,
        resourceStore,
        options: I18NextOptions(
          formatter: expectAsync3(
            (value, format, locale) {
              values.add(value);
              formats.add(format);
              return value.toString();
            },
            count: 2,
          ),
        ),
      );
      mockKey(
          'key',
          'leading {{value1, format1}} middle '
              '{{value2, format2}} trailing');

      expect(
        i18next.t('key', variables: {
          'value1': '1eulav',
          'value2': '2eulav',
        }),
        'leading 1eulav middle 2eulav trailing',
      );
      expect(values, orderedEquals(<String>['1eulav', '2eulav']));
      expect(formats, orderedEquals(<String>['format1', 'format2']));
    });
  });

  group('pluralization', () {
    setUp(() {
      mockKey('friend', 'A friend');
      mockKey('friend_plural', '{{count}} friends');
    });

    test('given key without count', () {
      expect(i18next.t('friend'), 'A friend');
    });

    test('given key with count', () {
      expect(i18next.t('friend', count: 0), '0 friends');
      expect(i18next.t('friend', count: 1), 'A friend');
      expect(i18next.t('friend', count: -1), '-1 friends');
      expect(i18next.t('friend', count: 99), '99 friends');
    });

    test('given key with count in variables', () {
      expect(i18next.t('friend', variables: {'count': 0}), '0 friends');
      expect(i18next.t('friend', variables: {'count': 1}), 'A friend');
      expect(i18next.t('friend', variables: {'count': -1}), '-1 friends');
      expect(i18next.t('friend', variables: {'count': 99}), '99 friends');
    });

    test('given key with both count property and in variables', () {
      expect(
        i18next.t('friend', count: 0, variables: {'count': 1}),
        '0 friends',
      );
      expect(
        i18next.t('friend', count: 1, variables: {'count': 0}),
        'A friend',
      );
    });

    test('given key with count and unmmaped context', () {
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

  group('contextualization', () {
    setUp(() {
      mockKey('friend', 'A friend');
      mockKey('friend_male', 'A boyfriend');
      mockKey('friend_female', 'A girlfriend');
    });

    test('given key without context', () {
      expect(i18next.t('friend'), 'A friend');
    });

    test('given key with mapped context', () {
      expect(i18next.t('friend', context: 'male'), 'A boyfriend');
      expect(i18next.t('friend', context: 'female'), 'A girlfriend');
    });

    test('given key with mapped context in variables', () {
      expect(
        i18next.t('friend', variables: {'context': 'male'}),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', variables: {'context': 'female'}),
        'A girlfriend',
      );
    });

    test('given key with both mapped context property and in variables', () {
      expect(
        i18next.t('friend', context: 'female', variables: {'context': 'male'}),
        'A girlfriend',
      );
      expect(
        i18next.t('friend', context: 'male', variables: {'context': 'female'}),
        'A boyfriend',
      );
    });

    test('given key with unmaped context', () {
      expect(i18next.t('friend', context: 'other'), 'A friend');
    });

    test('given key with mapped context and count', () {
      expect(
        i18next.t('friend', context: 'male', count: 0),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', context: 'male', count: 1),
        'A boyfriend',
      );
    });

    test('given key with unmapped context and count', () {
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

  group('contextualization and pluralization', () {
    setUp(() {
      mockKey('friend', 'A friend');
      mockKey('friend_plural', '{{count}} friends');
      mockKey('friend_male', 'A boyfriend');
      mockKey('friend_male_plural', '{{count}} boyfriends');
      mockKey('friend_female', 'A girlfriend');
      mockKey('friend_female_plural', '{{count}} girlfriends');
    });

    test('given key with mapped context and count', () {
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

    test('given key with unmmaped context and count', () {
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

  group('interpolation', () {
    setUp(() {
      mockKey('key', '{{first}}, {{second}}, and then {{third}}!');
    });

    test('given empty interpolation', () {
      mockKey('key', 'This is some {{}}');
      expect(i18next.t('key'), 'This is some {{}}');
    });

    test('given non matching arguments', () {
      expect(
        i18next.t('key', variables: {'none': 'none'}),
        '{{first}}, {{second}}, and then {{third}}!',
      );
    });

    test('given partially matching arguments', () {
      expect(
        i18next.t('key', variables: {'first': 'fst'}),
        'fst, {{second}}, and then {{third}}!',
      );
      expect(
        i18next.t('key', variables: {'first': 'fst', 'third': 'trd'}),
        'fst, {{second}}, and then trd!',
      );
    });

    test('given all matching arguments', () {
      expect(
        i18next.t('key', variables: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
        }),
        'fst, snd, and then trd!',
      );
    });

    test('given extra matching arguments', () {
      expect(
        i18next.t('key', variables: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
          'none': 'none',
        }),
        'fst, snd, and then trd!',
      );
    });
  });

  group('nesting', () {
    test('when nested key is not found', () {
      mockKey('key', r'This is my $t(anotherKey)');

      expect(i18next.t('key'), r'This is my $t(anotherKey)');
    });

    test('given multiple simple key substitutions', () {
      mockKey('nesting1', r'1 $t(nesting2)');
      mockKey('nesting2', r'2 $t(nesting3)');
      mockKey('nesting3', '3');

      expect(i18next.t('nesting1'), '1 2 3');
    });

    test('interpolation from immediate variables', () {
      mockKey('key1', 'hello world');
      mockKey('key2', 'say: {{val}}');

      expect(
        i18next.t('key2', variables: {'val': r'$t(key1)'}),
        'say: hello world',
      );
    });

    test('nested interpolations', () {
      mockKey('key1', 'hello {{name}}');
      mockKey('key2', r'say: $t(key1)');

      expect(
        i18next.t('key2', variables: {'name': 'world'}),
        'say: hello world',
      );
    });

    test('nested pluralization and interpolation ', () {
      mockKey('girlsAndBoys',
          r'$t(girls, {"count": {{girls}} }) and {{count}} boy');
      mockKey('girlsAndBoys_plural',
          r'$t(girls, {"count": {{girls}} }) and {{count}} boys');
      mockKey('girls', '{{count}} girl');
      mockKey('girls_plural', '{{count}} girls');

      expect(
        i18next.t('girlsAndBoys', count: 2, variables: {'girls': 3}),
        '3 girls and 2 boys',
      );
    });
  });
}
