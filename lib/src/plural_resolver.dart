import 'dart:ui';

import 'options.dart';

typedef PluralizationRule = int Function(int);

class PluralResolver {
  const PluralResolver() : super();

  /// Returns the plural suffix based on [count] and presented [options].
  String pluralize(Locale locale, int count, I18NextOptions options) {
    final rule = _ruleForLocale(locale);
    final index = rule(count.abs());
    final separator = options.pluralSeparator ?? '_';

    if (_ruleUsesSimpleSuffixes(rule)) {
      final suffix = options.pluralSuffix ?? 'plural';
      return index == 0 ? '' : '$separator$suffix';
    } else {
      return '$separator$index';
    }
  }

  /// Decide whether this rule simply uses "key" and "key_plural" rather than
  /// "key_0", "key_1", ...
  bool _ruleUsesSimpleSuffixes(PluralizationRule rule) {
    return rule == _rule1 ||
        rule == _rule2 ||
        rule == _rule3 ||
        rule == _rule9 ||
        rule == _rule12 ||
        rule == _rule17;
  }

  PluralizationRule _ruleForLocale(Locale locale) {
    final language = locale.languageCode;
    switch (language) {
      // Portuguese pluralization is country-dependent:
      case 'pt':
        return locale.countryCode == 'BR' ? _rule1 : _rule2;

      // Rule 1: "n > 1" style plurals.
      case 'ach':
      case 'ak':
      case 'am':
      case 'arn':
      case 'br':
      case 'fil':
      case 'gun':
      case 'ln':
      case 'mfe':
      case 'mg':
      case 'mi':
      case 'oc':
      case 'tg':
      case 'ti':
      case 'tr':
      case 'uz':
      case 'wa':
        return _rule1;

      // Rule 2: "n != 1" style plurals.
      case 'af':
      case 'an':
      case 'ast':
      case 'az':
      case 'bg':
      case 'bn':
      case 'ca':
      case 'da':
      case 'de':
      case 'dev':
      case 'el':
      case 'en':
      case 'eo':
      case 'es':
      case 'et':
      case 'eu':
      case 'fi':
      case 'fo':
      case 'fur':
      case 'fy':
      case 'gl':
      case 'gu':
      case 'ha':
      case 'hi':
      case 'hu':
      case 'hy':
      case 'ia':
      case 'it':
      case 'kn':
      case 'ku':
      case 'lb':
      case 'mai':
      case 'ml':
      case 'mn':
      case 'mr':
      case 'nah':
      case 'nap':
      case 'nb':
      case 'ne':
      case 'nl':
      case 'nn':
      case 'no':
      case 'nso':
      case 'or':
      case 'pa':
      case 'pap':
      case 'pms':
      case 'ps':
      case 'rm':
      case 'sco':
      case 'se':
      case 'si':
      case 'so':
      case 'son':
      case 'sq':
      case 'sv':
      case 'sw':
      case 'ta':
      case 'te':
      case 'tk':
      case 'ur':
      case 'yo':
        return _rule2;

      // Rule 3: no pluralization.
      case 'ay':
      case 'bo':
      case 'cgg':
      case 'fa':
      case 'id':
      case 'ja':
      case 'jbo':
      case 'ka':
      case 'kk':
      case 'km':
      case 'ko':
      case 'ky':
      case 'lo':
      case 'ms':
      case 'sah':
      case 'su':
      case 'th':
      case 'tt':
      case 'ug':
      case 'vi':
      case 'wo':
      case 'zh':
        return _rule3;

      // Rule 4: Russian-style plurals.
      case 'be':
      case 'bs':
      case 'cnr':
      case 'dz':
      case 'hr':
      case 'ru':
      case 'sr':
      case 'uk':
        return _rule4;

      // Rule 5: Arabic.
      case 'ar':
        return _rule5;

      // Rule 6: Czech and Slovak.
      case 'cs':
      case 'sk':
        return _rule6;

      // Rule 7: Cashubian and Polish.
      case 'csb':
      case 'pl':
        return _rule7;

      // Rule 8: Welsh.
      case 'cy':
        return _rule8;

      // Rule 9: French.
      case 'fr':
        return _rule9;

      // Rule 10: Irish.
      case 'ga':
        return _rule10;

      // Rule 11: Scottish Gaelic.
      case 'gd':
        return _rule11;

      // Rule 12: Icelandic.
      case 'is':
        return _rule12;

      // Rule 13: Javanese.
      case 'jv':
        return _rule13;

      // Rule 14: Cornish.
      case 'kw':
        return _rule14;

      // Rule 15: Lithuanian.
      case 'lt':
        return _rule15;

      // Rule 16: Latvian.
      case 'lv':
        return _rule16;

      // Rule 17: Macedonian.
      case 'mk':
        return _rule17;

      // Rule 18: Mandinka.
      case 'mnk':
        return _rule18;

      // Rule 19: Maltese.
      case 'mt':
        return _rule19;

      // Rule 20: Romanian.
      case 'ro':
        return _rule20;

      // Rule 21: Slovene.
      case 'sl':
        return _rule21;

      // Rule 22: Hebrew.
      case 'he':
        return _rule22;

      // Use the "no plurals" rule as a default.
      default:
        return _rule3;
    }
  }

  // Pluralization rules from: https://github.com/i18next/i18next/blob/4bfa7a3ace9d5eb6f7dee2fe4640b918242ba441/src/PluralResolver.js#L41
  static int _rule1(int n) => n > 1 ? 1 : 0;

  static int _rule2(int n) => n != 1 ? 1 : 0;

  static int _rule3(int n) => 0;

  static int _rule4(int n) => n % 10 == 1 && n % 100 != 11
      ? 0
      : n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)
          ? 1
          : 2;

  static int _rule5(int n) => n == 0
      ? 0
      : n == 1
          ? 1
          : n == 2
              ? 2
              : n % 100 >= 3 && n % 100 <= 10
                  ? 3
                  : n % 100 >= 11
                      ? 4
                      : 5;

  static int _rule6(int n) => n == 1
      ? 0
      : n >= 2 && n <= 4
          ? 1
          : 2;

  static int _rule7(int n) => n == 1
      ? 0
      : n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)
          ? 1
          : 2;

  static int _rule8(int n) => (n == 1)
      ? 0
      : (n == 2)
          ? 1
          : (n != 8 && n != 11)
              ? 2
              : 3;

  static int _rule9(int n) => n >= 2 ? 1 : 0;

  static int _rule10(int n) => n == 1
      ? 0
      : n == 2
          ? 1
          : n < 7
              ? 2
              : n < 11
                  ? 3
                  : 4;

  static int _rule11(int n) => n == 1 || n == 11
      ? 0
      : n == 2 || n == 12
          ? 1
          : n > 2 && n < 20
              ? 2
              : 3;

  static int _rule12(int n) => n % 10 != 1 || n % 100 == 11 ? 1 : 0;

  static int _rule13(int n) => n != 0 ? 1 : 0;

  static int _rule14(int n) => n == 1
      ? 0
      : (n == 2)
          ? 1
          : (n == 3)
              ? 2
              : 3;

  static int _rule15(int n) => n % 10 == 1 && n % 100 != 11
      ? 0
      : n % 10 >= 2 && (n % 100 < 10 || n % 100 >= 20)
          ? 1
          : 2;

  static int _rule16(int n) => n % 10 == 1 && n % 100 != 11
      ? 0
      : n != 0
          ? 1
          : 2;

  static int _rule17(int n) => n == 1 || n % 10 == 1 && n % 100 != 11 ? 0 : 1;

  static int _rule18(int n) => n == 0
      ? 0
      : n == 1
          ? 1
          : 2;

  static int _rule19(int n) => n == 1
      ? 0
      : n == 0 || (n % 100 > 1 && n % 100 < 11)
          ? 1
          : n % 100 > 10 && n % 100 < 20
              ? 2
              : 3;

  static int _rule20(int n) => n == 1
      ? 0
      : n == 0 || n % 100 > 0 && n % 100 < 20
          ? 1
          : 2;

  static int _rule21(int n) => n % 100 == 1
      ? 1
      : n % 100 == 2
          ? 2
          : n % 100 == 3 || n % 100 == 4
              ? 3
              : 0;

  static int _rule22(int n) => n == 1
      ? 0
      : n == 2
          ? 1
          : (n < 0 || n > 10) && n % 10 == 0
              ? 2
              : 3;
}
