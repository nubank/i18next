import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';
import 'package:mockito/mockito.dart';

class MockBundle extends Mock implements AssetBundle {}

void main() {
  const bundlePath = 'bundle/path';
  const defaultManifest = 'AssetManifest.json';
  MockBundle bundle;
  AssetBundleLocalizationDataSource dataSource;

  setUp(() {
    bundle = MockBundle();
    dataSource = AssetBundleLocalizationDataSource(
      bundlePath: bundlePath,
      bundle: bundle,
    );
  });

  test('given bundlePath null', () {
    expect(
      () => AssetBundleLocalizationDataSource(bundlePath: null),
      throwsAssertionError,
    );
  });

  group('#loadFromAssetBundle', () {
    setUp(() {
      when(bundle.loadString(defaultManifest)).thenAnswer((_) async => '''{
            "another/asset/path": [""],
            "$bundlePath/en-US/file1.json": [""],
            "$bundlePath/en-US/file2.json": [""],
            "$bundlePath/pt/file1.json": [""],
            "$bundlePath/pt/file2.json": [""]
          }''');
    });

    test('given locale null', () {
      expect(() => dataSource.load(null), throwsAssertionError);
    });

    test('given any locale', () async {
      await expectLater(
        dataSource.load(const Locale('any')),
        completes,
      );
      verify(bundle.loadString(defaultManifest)).called(1);
    });

    test('given an unregistered locale', () {
      expect(
        dataSource.load(const Locale('ar')),
        completion(isEmpty),
      );
    });

    test('given a supported full locale', () async {
      when(bundle.loadString(argThat(contains('$bundlePath/'))))
          .thenAnswer((_) async => '{}');

      await expectLater(
        dataSource.load(const Locale('en', 'US')),
        completion(equals(<String, Map<String, Object>>{
          'file1': {},
          'file2': {},
        })),
      );

      verify(bundle.loadString('$bundlePath/en-US/file1.json')).called(1);
      verify(bundle.loadString('$bundlePath/en-US/file2.json')).called(1);
    });

    test('given an unsupported long locale', () async {
      await expectLater(
        dataSource.load(const Locale('pt-BR')),
        completion(isEmpty),
      );

      verifyNever(bundle.loadString(argThat(contains('$bundlePath/pt/'))));
      verifyNever(bundle.loadString(argThat(contains('$bundlePath/pt-BR/'))));
      verifyNever(bundle.loadString(argThat(contains('$bundlePath/en-US/'))));
    });

    test('given a supported short locale', () async {
      when(bundle.loadString(argThat(contains('$bundlePath/'))))
          .thenAnswer((_) async => '{}');

      await expectLater(
        dataSource.load(const Locale('pt')),
        completion(equals(<String, Map<String, Object>>{
          'file1': {},
          'file2': {},
        })),
      );

      verify(bundle.loadString('$bundlePath/pt/file1.json')).called(1);
      verify(bundle.loadString('$bundlePath/pt/file2.json')).called(1);
      verifyNever(bundle.loadString(argThat(contains('$bundlePath/en-US/'))));
    });

    test('given an unsupported short locale', () async {
      await expectLater(
        dataSource.load(const Locale('ar')),
        completion(isEmpty),
      );

      verifyNever(bundle.loadString(argThat(contains('$bundlePath/ar/'))));
      verifyNever(bundle.loadString(argThat(contains('$bundlePath/pt/'))));
      verifyNever(bundle.loadString(argThat(contains('$bundlePath/en-US/'))));
    });

    test('when bundle errors', () async {
      const error = 'Some error';
      when(bundle.loadString(any)).thenAnswer((_) async => throw error);

      expect(
        dataSource.load(const Locale('any')),
        throwsA(error),
      );
    });

    test('given manifest null', () {
      expect(
        () => dataSource.load(
          const Locale('any'),
          manifest: null,
        ),
        throwsAssertionError,
      );
    });

    test('given manifest empty', () {
      expect(
        () => dataSource.load(
          const Locale('any'),
          manifest: '',
        ),
        throwsAssertionError,
      );
    });

    test('given manifest', () async {
      const manifest = 'SomeManifestFile.json';
      when(bundle.loadString(any)).thenAnswer((_) async => '{}');

      await expectLater(
        dataSource.load(
          const Locale('any'),
          manifest: manifest,
        ),
        completes,
      );
      verify(bundle.loadString(manifest)).called(1);
    });
  });
}
