import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'i18next_localization_delegate_test.mocks.dart';

@GenerateMocks([ResourceStore, LocalizationDataSource])
void main() {
  const namespace = 'local_namespace';
  const locale = Locale('en');
  const defaultFormatter = I18NextOptions.defaultFormatter;

  late I18Next i18next;
  late MockResourceStore resourceStore;

  setUp(() {
    resourceStore = MockResourceStore();
    i18next = I18Next(locale, resourceStore);
    when(resourceStore.retrieve(any, any, any, any)).thenReturn(null);
  });

  void mockKey(
    String key,
    String answer, {
    String ns = namespace,
    Locale locale = locale,
  }) {
    when(resourceStore.retrieve(locale, ns, key, any)).thenReturn(answer);
  }

  group('given named namespaces', () {
    setUp(() {
      mockKey('key', 'My first value', ns: 'ns1');
      mockKey('key', 'My second value', ns: 'ns2');
    });

    test('given key for matching namespaces', () {
      expect(i18next.t('ns1:key'), 'My first value');
      verify(resourceStore.retrieve(locale, 'ns1', 'key', any));

      expect(i18next.t('ns2:key'), 'My second value');
      verify(resourceStore.retrieve(locale, 'ns2', 'key', any));
    });

    test('given key for unmatching namespaces', () {
      expect(i18next.t('ns3:key'), 'ns3:key');
      verify(resourceStore.retrieve(locale, 'ns3', 'key', any));
    });

    test('given key for partially matching namespaces', () {
      expect(i18next.t('ns:key'), 'ns:key');
      verify(resourceStore.retrieve(locale, 'ns', 'key', any));
    });
  });

  test('given resource store', () {
    mockKey('key', 'My value', ns: 'ns');

    expect(i18next.t('ns:key'), 'My value');
    verify(resourceStore.retrieve(locale, 'ns', 'key', any)).called(1);
  });

  test('given key without namespace', () {
    when(resourceStore.retrieve(any, any, any, any)).thenReturn(null);

    expect(i18next.t('someKey'), 'someKey');
    expect(i18next.t('some.key'), 'some.key');
  });

  test('given an existing string key', () {
    mockKey('myKey', 'This is my key');
    expect(i18next.t('$namespace:myKey'), 'This is my key');
  });

  test('given a non-existing or non matching key', () {
    expect(i18next.t('someKey'), 'someKey');
    expect(i18next.t('some.key'), 'some.key');
  });

  test('given overriding locale', () {
    const anotherLocale = Locale('another');
    mockKey('key', 'my value', locale: anotherLocale);

    expect(i18next.t('$namespace:key', locale: anotherLocale), 'my value');
    verify(resourceStore.retrieve(
      anotherLocale,
      namespace,
      'key',
      any,
    )).called(1);
  });

  group('given formatter', () {
    test('with no interpolations', () {
      i18next = I18Next(
        locale,
        resourceStore,
        options: I18NextOptions(
          formatter: expectAsync3(defaultFormatter, count: 0),
        ),
      );
      mockKey('key', 'no interpolations here');

      expect(i18next.t('$namespace:key'), 'no interpolations here');
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
        i18next.t('$namespace:key', variables: {'name': 'World'}),
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
        i18next.t('$namespace:key', variables: {'value': 'eulav'}),
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
        i18next.t('$namespace:key', variables: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with multiple matching interpolations', () {
      final values = <Object>[];
      final formats = <Object?>[];
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
        i18next.t('$namespace:key', variables: {
          'value1': '1eulav',
          'value2': '2eulav',
        }),
        'leading 1eulav middle 2eulav trailing',
      );
      expect(values, orderedEquals(<String>['1eulav', '2eulav']));
      expect(formats, orderedEquals(<String>['format1', 'format2']));
    });
  });

  group('fallback', () {
    test('given a global fallback key substitution', () {
      const fallbackNamespace1 = 'fallback_namespace_1';
      i18next = I18Next(
        locale,
        resourceStore,
        options: const I18NextOptions(
          fallbackNamespaces: [fallbackNamespace1],
        ),
      );

      mockKey('key', 'fallbackValue', ns: fallbackNamespace1);
      mockKey('key', 'value', ns: namespace);

      expect(i18next.t('key'), 'fallbackValue');
      expect(i18next.t('$namespace:key'), 'value');
    });

    group('given 2 global fallback keys subsitution', () {
      const fallbackNamespace1 = 'fallback_namespace_1';
      const fallbackNamespace2 = 'fallback_namespace_2';

      setUp(() {
        i18next = I18Next(
          locale,
          resourceStore,
          options: const I18NextOptions(
            fallbackNamespaces: [fallbackNamespace1, fallbackNamespace2],
          ),
        );
      });

      test('key only exists in second fallbackNamespace', () {
        mockKey('key2', 'fallbackValue2', ns: fallbackNamespace2);
        mockKey('key2', 'value2', ns: namespace);

        expect(i18next.t('key2'), 'fallbackValue2');
        expect(i18next.t('$namespace:key2'), 'value2');
      });

      test('key exists in both first and second fallbackNamespace', () {
        mockKey('key', 'fallbackValue1', ns: fallbackNamespace1);
        mockKey('key', 'fallbackValue2', ns: fallbackNamespace2);
        mockKey('key', 'value', ns: namespace);

        expect(i18next.t('key'), 'fallbackValue1');
        expect(i18next.t('$namespace:key'), 'value');
      });
    });
  });

  group('pluralization', () {
    setUp(() {
      // English, which is "simple" (key and key_plural):
      mockKey('friend-no-count', 'A friend');
      mockKey('friend-no-count_plural', 'Friends');
      mockKey('friend', '{{count}} friend');
      mockKey('friend_plural', '{{count}} friends');

      // Icelandic, which is also "simple" but has a subtly different rule.
      // (In Icelandic, you say "twenty and one friend".)
      const ic = Locale('is');
      mockKey('friend', '{{count}} vinur', locale: ic);
      mockKey('friend_plural', '{{count}} vinir', locale: ic);

      // Russian, which has three pluralization forms:
      const ru = Locale('ru');
      mockKey('friend_0', '{{count}} друг', locale: ru);
      mockKey('friend_1', '{{count}} друга', locale: ru);
      mockKey('friend_2', '{{count}} друзей', locale: ru);

      // Japanese, which has none:
      const ja = Locale('ja');
      mockKey('friend', '友達{{count}}人', locale: ja);
    });

    test('given key without count', () {
      expect(i18next.t('$namespace:friend-no-count'), 'A friend');
    });

    test('given key with count', () {
      expect(i18next.t('$namespace:friend', count: 0), '0 friends');
      expect(i18next.t('$namespace:friend', count: 1), '1 friend');
      expect(i18next.t('$namespace:friend', count: 99), '99 friends');
    });

    test('given key with count in Icelandic (alternate plural rule)', () {
      const ic = Locale('is');
      expect(i18next.t('$namespace:friend', count: 1, locale: ic), '1 vinur');
      expect(i18next.t('$namespace:friend', count: 20, locale: ic), '20 vinir');
      expect(i18next.t('$namespace:friend', count: 21, locale: ic), '21 vinur');
    });

    test('given key with count in Russian (multiple plurals)', () {
      const ru = Locale('ru');
      expect(i18next.t('$namespace:friend', count: 1, locale: ru), '1 друг');
      expect(i18next.t('$namespace:friend', count: 2, locale: ru), '2 друга');
      expect(i18next.t('$namespace:friend', count: 9, locale: ru), '9 друзей');
    });

    test('given key with count in Japanese (no plurals)', () {
      const ja = Locale('ja');
      expect(i18next.t('$namespace:friend', count: 1, locale: ja), '友達1人');
      expect(i18next.t('$namespace:friend', count: 5, locale: ja), '友達5人');
    });

    test('given key with count in variables', () {
      expect(
        i18next.t('$namespace:friend', variables: {'count': 0}),
        '0 friends',
      );
      expect(
        i18next.t('$namespace:friend', variables: {'count': 1}),
        '1 friend',
      );
      expect(
        i18next.t('$namespace:friend', variables: {'count': -1}),
        '-1 friend',
      );
      expect(
        i18next.t('$namespace:friend', variables: {'count': 99}),
        '99 friends',
      );
    });

    test('given key with both count property and in variables', () {
      expect(
        i18next.t('$namespace:friend', count: 0, variables: {'count': 1}),
        '0 friends',
      );
      expect(
        i18next.t('$namespace:friend', count: 1, variables: {'count': 0}),
        '1 friend',
      );
    });

    test('given key with count and unmmaped context', () {
      expect(
        i18next.t('$namespace:friend', count: 1, context: 'something'),
        '1 friend',
      );
      expect(
        i18next.t('$namespace:friend', count: 99, context: 'something'),
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
      expect(i18next.t('$namespace:friend'), 'A friend');
    });

    test('given key with mapped context', () {
      expect(i18next.t('$namespace:friend', context: 'male'), 'A boyfriend');
      expect(i18next.t('$namespace:friend', context: 'female'), 'A girlfriend');
    });

    test('given key with mapped context in variables', () {
      expect(
        i18next.t('$namespace:friend', variables: {'context': 'male'}),
        'A boyfriend',
      );
      expect(
        i18next.t('$namespace:friend', variables: {'context': 'female'}),
        'A girlfriend',
      );
    });

    test('given key with both mapped context property and in variables', () {
      expect(
        i18next.t(
          '$namespace:friend',
          context: 'female',
          variables: {'context': 'male'},
        ),
        'A girlfriend',
      );
      expect(
        i18next.t(
          '$namespace:friend',
          context: 'male',
          variables: {'context': 'female'},
        ),
        'A boyfriend',
      );
    });

    test('given key with unmaped context', () {
      expect(i18next.t('$namespace:friend', context: 'other'), 'A friend');
    });

    test('given key with mapped context and count', () {
      expect(
        i18next.t('$namespace:friend', context: 'male', count: 0),
        'A boyfriend',
      );
      expect(
        i18next.t('$namespace:friend', context: 'male', count: 1),
        'A boyfriend',
      );
    });

    test('given key with unmapped context and count', () {
      expect(
        i18next.t('$namespace:friend', context: 'other', count: 1),
        'A friend',
      );
      expect(
        i18next.t('$namespace:friend', context: 'other', count: 99),
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
        i18next.t('$namespace:friend', context: 'male', count: 0),
        '0 boyfriends',
      );
      expect(
        i18next.t('$namespace:friend', context: 'male', count: 1),
        'A boyfriend',
      );
      expect(
        i18next.t('$namespace:friend', context: 'female', count: 0),
        '0 girlfriends',
      );
      expect(
        i18next.t('$namespace:friend', context: 'female', count: 1),
        'A girlfriend',
      );
    });

    test('given key with unmmaped context and count', () {
      expect(
        i18next.t('$namespace:friend', context: 'other', count: 0),
        '0 friends',
      );
      expect(
        i18next.t('$namespace:friend', context: 'other', count: 1),
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
      expect(i18next.t('$namespace:key'), 'This is some {{}}');
    });

    test('given non matching arguments', () {
      expect(
        i18next.t('$namespace:key', variables: {'none': 'none'}),
        '{{first}}, {{second}}, and then {{third}}!',
      );
    });

    test('given partially matching arguments', () {
      expect(
        i18next.t('$namespace:key', variables: {'first': 'fst'}),
        'fst, {{second}}, and then {{third}}!',
      );
      expect(
        i18next.t(
          '$namespace:key',
          variables: {'first': 'fst', 'third': 'trd'},
        ),
        'fst, {{second}}, and then trd!',
      );
    });

    test('given all matching arguments', () {
      expect(
        i18next.t('$namespace:key', variables: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
        }),
        'fst, snd, and then trd!',
      );
    });

    test('given extra matching arguments', () {
      expect(
        i18next.t('$namespace:key', variables: {
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

      expect(i18next.t('$namespace:key'), r'This is my $t(anotherKey)');
    });

    test('given multiple simple key substitutions', () {
      mockKey('nesting1', r'1 $t(nesting2)');
      mockKey('nesting2', r'2 $t(nesting3)');
      mockKey('nesting3', '3');

      expect(i18next.t('$namespace:nesting1'), '1 2 3');
    });

    test('given a grouped key substitution', () {
      mockKey('keyA', 'A');
      mockKey('group.keyB', 'B');
      mockKey('local', r'$t(keyA), and $t(group.keyB)!');

      expect(i18next.t('$namespace:local'), 'A, and B!');
    });

    test('given a global fallback key substitution', () {
      const fallbackNamespace = 'fallback_namespace';
      i18next = I18Next(
        locale,
        resourceStore,
        options: const I18NextOptions(fallbackNamespaces: [fallbackNamespace]),
      );

      mockKey('keyZ', 'Z', ns: fallbackNamespace);
      mockKey('keyA', 'A', ns: namespace);

      mockKey('example', r'$t(keyA), and $t(keyZ)!', ns: namespace);

      expect(i18next.t('$namespace:example'), 'A, and Z!');
    });

    test('when nested local and fallback namespaces have same key', () {
      const fallbackNamespace = 'fallback_namespace';
      i18next = I18Next(
        locale,
        resourceStore,
        options: const I18NextOptions(fallbackNamespaces: [fallbackNamespace]),
      );

      mockKey('keyX', 'Global X', ns: fallbackNamespace);
      mockKey('keyX', 'Local X', ns: namespace);
      mockKey(
        'example',
        // explicit namespace key nesting
        '\$t(keyX), and \$t($fallbackNamespace:keyX)!',
        ns: namespace,
      );

      expect(i18next.t('$namespace:example'), 'Local X, and Global X!');
    });

    test('interpolation from immediate variables', () {
      mockKey('key1', 'hello world');
      mockKey('key2', 'say: {{val}}');

      expect(
        i18next.t('$namespace:key2', variables: {'val': r'$t(key1)'}),
        'say: hello world',
      );
    });

    test('nested interpolations', () {
      mockKey('key1', 'hello {{name}}');
      mockKey('key2', r'say: $t(key1)');

      expect(
        i18next.t('$namespace:key2', variables: {'name': 'world'}),
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
        i18next.t('$namespace:girlsAndBoys', count: 2, variables: {'girls': 3}),
        '3 girls and 2 boys',
      );
    });
  });

  group('.of', () {
    BuildContext? capturedContext;

    final builder = Builder(builder: (context) {
      capturedContext = context;
      return Container();
    });

    setUp(() {
      capturedContext = null;
    });

    testWidgets('when not registered in the widget tree', (tester) async {
      await tester.pumpWidget(builder);
      expect(I18Next.of(capturedContext!), isNull);
    });

    testWidgets('when is registered in the widget tree', (tester) async {
      final dataSource = MockLocalizationDataSource();
      when(dataSource.load(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(Localizations(
        locale: locale,
        delegates: [
          DefaultWidgetsLocalizations.delegate,
          I18NextLocalizationDelegate(
            locales: [locale],
            dataSource: dataSource,
          ),
        ],
        child: builder,
      ));
      await tester.pump();
      expect(I18Next.of(capturedContext!), isNotNull);
    });
  });
}
