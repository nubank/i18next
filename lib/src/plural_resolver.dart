import 'dart:ui';

import 'options.dart';

class PluralResolver {
  PluralResolver() : super();

  /// Returns the plural suffix based on [count] and presented [options].
  String pluralize(Locale locale, int count, I18NextOptions options) {
    var result = '';
    if (count != 1) {
      final number = _numberForLocale(count.abs(), locale);
      if (number >= 0) {
        result = '${options.pluralSuffix}${options.pluralSeparator}$number';
      } else {
        result = '${options.pluralSeparator}${options.pluralSuffix}';
      }
    }
    return result;
  }

  int _numberForLocale(int count, Locale locale) {
    // TODO: add locale based rules
    return -1;
  }
}
