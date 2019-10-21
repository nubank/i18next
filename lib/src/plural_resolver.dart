import 'dart:ui';

class PluralResolver {
  PluralResolver() : super();

  /// Returns the pluralized form for the [key] based on [locale] and [count].
  String pluralize(String key, String suffix, int count, Locale locale) {
    if (count != 1) {
      final number = _numberForLocale(count.abs(), locale);
      if (number >= 0)
        key = '$key${suffix}_$number';
      else
        key = '$key$suffix';
    }
    return key;
  }

  int _numberForLocale(int count, Locale locale) {
    // TODO: add locale based rules
    return -1;
  }
}
