import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:i18next/src/plural_resolver.dart';
import 'package:mockito/mockito.dart';

abstract class FakeCheckerKeyFunction {
  bool call(String pluralModifier);
}

class MockCheckerKeyFunction extends Mock implements FakeCheckerKeyFunction {}

void main() {
  group('PluralResolver', () {
    MockCheckerKeyFunction checkerKeyFnc;
    PluralResolver subject;

    setUpAll(() {
      checkerKeyFnc = MockCheckerKeyFunction();
      subject = PluralResolver();
    });

    test('when count is equal 1 returns empty string', () {
      const count = 1;
      final result = subject.pluralize(
        count,
        I18NextOptions.base,
        checkerKeyFnc,
      );

      verifyZeroInteractions(checkerKeyFnc);
      expect(result, equals(''));
    });

    group('when count is different than 1', () {
      test('when exists the specfic key', () {
        const count = 2;
        when(checkerKeyFnc.call('_plural_2')).thenReturn(true);

        final result = subject.pluralize(
          count,
          I18NextOptions.base,
          checkerKeyFnc,
        );

        expect(result, equals('_plural_2'));
      });

      test('when does not exist the specfic key', () {
        const count = 2;
        when(checkerKeyFnc.call('_plural_2')).thenReturn(false);

        final result = subject.pluralize(
          count,
          I18NextOptions.base,
          checkerKeyFnc,
        );

        expect(result, equals('_plural'));
      });
    });
  });
}
