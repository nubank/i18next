import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';

void main() {
  I18NextOptions options;

  setUp(() {
    options = I18NextOptions.base;
  });

  group('#retrieve', () {
    const validLocale = Locale('en');
    const validNamespace = 'ns';

    ResourceStore store;

    setUp(() {
      store = ResourceStore(data: {
        validLocale: {
          validNamespace: {
            'key': 'This is a simple key',
            'my': {
              'key': 'This is a nested key',
              'nested': {
                'key': 'This is a more nested key',
              }
            }
          }
        }
      });
    });

    test('with null locale', () {
      expect(store.retrieve(null, validNamespace, 'key', options), isNull);
    });

    test('with unmatching locale', () {
      const anotherLocale = Locale('pt');
      expect(
        store.retrieve(anotherLocale, validNamespace, 'key', options),
        isNull,
      );
    });

    group('with matching locale', () {
      const locale = validLocale;

      test('with null namespace', () {
        expect(store.retrieve(locale, null, 'key', options), isNull);
      });

      test('with unmatching namespace', () {
        expect(store.retrieve(locale, '', 'key', options), isNull);
      });

      group('with matching namespace', () {
        const namespace = validNamespace;

        test('given null key', () {
          expect(store.retrieve(locale, namespace, null, options), isNull);
        });

        test('given a non matching key', () {
          expect(
            store.retrieve(locale, namespace, 'another.key', options),
            isNull,
          );
        });

        test('given a partially matching key', () {
          expect(store.retrieve(locale, namespace, 'my', options), isNull);
          expect(
            store.retrieve(locale, namespace, 'my.nested', options),
            isNull,
          );
        });

        test('given a matching key', () {
          expect(
            store.retrieve(locale, namespace, 'key', options),
            'This is a simple key',
          );
          expect(
            store.retrieve(locale, namespace, 'my.key', options),
            'This is a nested key',
          );
          expect(
            store.retrieve(locale, namespace, 'my.nested.key', options),
            'This is a more nested key',
          );
        });

        test('given an over matching key', () {
          expect(
            store.retrieve(locale, namespace, 'my.nested.key.value', options),
            isNull,
          );
        });
      });
    });

    test('given a keySeparator', () {
      final newOptions = options.apply(I18NextOptions(
        keySeparator: '+++',
      ));
      expect(
        store.retrieve(
          validLocale,
          validNamespace,
          'my+++nested+++key',
          newOptions,
        ),
        'This is a more nested key',
      );

      expect(
        store.retrieve(
          validLocale,
          validNamespace,
          'my.nested/key',
          newOptions,
        ),
        isNull,
      );
    });
  });

  group('.evaluate', () {
    const locale = Locale('any');

    final level2 = <Object, Object>{
      'key': 'Second level leaf',
    };
    final level1 = <Object, Object>{
      'key': 'First level leaf',
      'nested': level2,
    };
    final data = <Object, Object>{
      'key': 'Zero level leaf',
      locale: level1,
    };

    const evaluate = ResourceStore.evaluate;

    test('given null path', () {
      expect(() => evaluate(null, data), throwsNoSuchMethodError);
    });

    test('given empty path', () {
      expect(evaluate([], data), data);
    });

    test('given a non matching path', () {
      expect(evaluate(['somewhere'], data), isNull);
      expect(evaluate([null], data), isNull);
    });

    test('given leaf matching path', () {
      expect(evaluate(['key'], data), 'Zero level leaf');
      expect(evaluate([locale, 'key'], data), 'First level leaf');
      expect(evaluate([locale, 'nested', 'key'], data), 'Second level leaf');
    });

    test('given under matching path', () {
      expect(evaluate([locale], data), level1);
      expect(evaluate([locale, 'nested'], data), level2);
    });

    test('given partially matching path', () {
      expect(evaluate([locale, 'another'], data), isNull);
      expect(evaluate([locale, 'nested', 'another'], data), isNull);
    });

    test('given over matching path', () {
      expect(evaluate(['key', 'another'], data), isNull);
      expect(evaluate([locale, 'key', 'another'], data), isNull);
      expect(evaluate([locale, 'nested', 'key', 'another'], data), isNull);
    });
  });
}
