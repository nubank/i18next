import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';

void main() {
  I18NextOptions options;

  setUp(() {
    options = I18NextOptions.from(I18NextOptions.base);
  });

  group('#retrieve', () {
    const validLocale = Locale('en');
    const validNamespace = 'ns';

    ResourceStore store;

    setUp(() {
      store = ResourceStore({
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
      options.locale = null;
      expect(store.retrieve(validNamespace, 'key', options), isNull);
    });

    test('with unmatching locale', () {
      options.locale = const Locale('pt');
      expect(store.retrieve(validNamespace, 'key', options), isNull);
    });

    group('with matching locale', () {
      setUp(() {
        options.locale = validLocale;
      });

      test('with null namespace', () {
        expect(store.retrieve(null, 'key', options), isNull);
      });

      test('with unmatching namespace', () {
        expect(store.retrieve('', 'key', options), isNull);
      });

      group('with matching namespace', () {
        const namespace = validNamespace;

        test('given null key', () {
          expect(store.retrieve(namespace, null, options), isNull);
        });

        test('given a non matching key', () {
          expect(store.retrieve(namespace, 'another.key', options), isNull);
        });

        test('given a partially matching key', () {
          expect(store.retrieve(namespace, 'my', options), isNull);
          expect(store.retrieve(namespace, 'my.nested', options), isNull);
        });

        test('given a matching key', () {
          expect(
            store.retrieve(namespace, 'key', options),
            'This is a simple key',
          );
          expect(
            store.retrieve(namespace, 'my.key', options),
            'This is a nested key',
          );
          expect(
            store.retrieve(namespace, 'my.nested.key', options),
            'This is a more nested key',
          );
        });

        test('given an over matching key', () {
          expect(
            store.retrieve(namespace, 'my.nested.key.value', options),
            isNull,
          );
        });
      });
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
