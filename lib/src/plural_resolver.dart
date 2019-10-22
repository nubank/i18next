import 'dart:ui';

class PluralResolver {
  PluralResolver() : super();

  /// Returns the plural suffix based on [locale] and [count].
  String pluralize(String suffix, int count, Locale locale) {
    String result = '';
    if (count != 1) {
      final number = _numberForLocale(count.abs(), locale);
      if (number >= 0)
        result = '${suffix}_$number';
      else
        result = suffix;
    }
    return result;
  }

  int _numberForLocale(int count, Locale locale) {
    // TODO: add locale based rules
    return -1;
  }
}
