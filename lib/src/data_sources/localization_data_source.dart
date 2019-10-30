import 'dart:ui';

abstract class LocalizationDataSource {
  Future<Map<String, Object>> load(Locale locale);
}
