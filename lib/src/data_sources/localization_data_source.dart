import 'dart:ui';

abstract class LocalizationDataSource {
  Future<Map<String, dynamic>> load(Locale locale);
}
