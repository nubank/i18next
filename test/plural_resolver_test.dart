import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:i18next/src/plural_resolver.dart';
import 'package:mockito/mockito.dart';

class MockKeyExists extends Mock {
  bool call(String pluralModifier);
}

void main() {
  MockKeyExists keyExists;
  PluralResolver subject;

  setUp(() {
    keyExists = MockKeyExists();
    subject = PluralResolver();
  });

  group('given count equals 0', () {
    test('when exists the specfic key', () {
      when(keyExists.call('_0')).thenReturn(true);
      const count = 0;
      final result = subject.pluralize(
        count,
        I18NextOptions.base,
        keyExists,
      );

      expect(result, equals('_0'));
    });

    test('when does not exist the specfic key', () {
      when(keyExists.call('_0')).thenReturn(false);
      const count = 0;
      final result = subject.pluralize(
        count,
        I18NextOptions.base,
        keyExists,
      );

      expect(result, equals('_plural'));
    });
  });

  test('given count equals 1', () {
    const count = 1;
    final result = subject.pluralize(
      count,
      I18NextOptions.base,
      keyExists,
    );

    verifyZeroInteractions(keyExists);
    expect(result, equals(''));
  });

  group('when count is different than 1', () {
    test('when exists the specfic key', () {
      const count = 2;
      when(keyExists.call('_2')).thenReturn(true);

      final result = subject.pluralize(
        count,
        I18NextOptions.base,
        keyExists,
      );

      expect(result, equals('_2'));
    });

    test('when does not exist the specfic key', () {
      const count = 2;
      when(keyExists.call('_2')).thenReturn(false);

      final result = subject.pluralize(
        count,
        I18NextOptions.base,
        keyExists,
      );

      expect(result, equals('_plural'));
    });
  });
}
