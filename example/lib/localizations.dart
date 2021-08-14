import 'package:flutter/widgets.dart';
import 'package:i18next/i18next.dart';

class HomePageL10n {
  const HomePageL10n(this.i18next);

  final I18Next i18next;

  static HomePageL10n of(BuildContext context) =>
      HomePageL10n(I18Next.of(context)!);

  String get title => i18next.t('homepage:title');

  String today(DateTime date) =>
      i18next.t('homepage:today', variables: {'date': date});

  String hello({required String name, required String world}) => i18next.t(
        'homepage:helloMessage',
        variables: {'name': name, 'world': world},
      );

  String gendered(String gender) =>
      i18next.t('homepage:genderMessage', context: gender);
}

class CounterL10n {
  const CounterL10n(this.i18next);

  final I18Next i18next;

  static CounterL10n of(BuildContext context) =>
      CounterL10n(I18Next.of(context)!);

  String clicked(int count) => i18next.t('counter:clicked', count: count);

  String get clickMe => i18next.t('counter:clickMe');

  String get resetCounter => i18next.t('counter:resetCounter');
}
