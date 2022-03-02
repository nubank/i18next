import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18next/i18next.dart';
import 'package:intl/intl.dart';

import 'localizations.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  final List<Locale> locales = const [
    Locale('en', 'US'),
    Locale('pt', 'BR'),
    // TODO: add multi plural language(s)
  ];

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale locale;

  @override
  void initState() {
    super.initState();

    locale = widget.locales.first;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I18nu Demo',
      theme: ThemeData(
        dividerTheme: const DividerThemeData(
          color: Colors.black45,
          space: 32.0,
        ),
      ),
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        I18NextLocalizationDelegate(
          locales: widget.locales,
          dataSource: AssetBundleLocalizationDataSource(
            // This is the path for the files declared in pubspec which should
            // contain all of your localizations
            bundlePath: 'localizations',
          ),
          // extra formatting options can be added here
          options: I18NextOptions(formats: formatters()),
        ),
      ],
      home: MyHomePage(
        supportedLocales: widget.locales,
        onUpdateLocale: updateLocale,
      ),
      locale: locale,
      supportedLocales: widget.locales,
    );
  }

  void updateLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  static Map<String, ValueFormatter> formatters() {
    return <String, ValueFormatter>{
      'uppercase': (value, valueOption, locale, options) =>
          value.toString().toUpperCase(),
      'lowercase': (value, valueOption, locale, options) =>
          value.toString().toLowerCase(),
      'datetime': (value, valueOption, locale, options) {
        if (value is! DateTime) return value;

        var format = valueOption['format'];
        format = format is String ? format : 'dd/MM/yyyy';
        return DateFormat(format, locale.toString()).format(value);
      },
    };
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.supportedLocales,
    required this.onUpdateLocale,
  }) : super(key: key);

  final List<Locale> supportedLocales;
  final ValueChanged<Locale> onUpdateLocale;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _gender = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homepageL10n = HomePageL10n.of(context);
    final counterL10n = CounterL10n.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(homepageL10n.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            CupertinoSegmentedControl<Locale>(
              children: {
                for (var e in widget.supportedLocales) e: Text(e.toString())
              },
              groupValue: Localizations.localeOf(context),
              onValueChanged: widget.onUpdateLocale,
            ),
            const Divider(),
            Text(
              homepageL10n.hello(name: 'Name', world: 'Flutter'),
              style: theme.textTheme.headline6,
            ),
            Text(
              homepageL10n.today(DateTime.now()),
              style: theme.textTheme.subtitle2,
            ),
            CupertinoSegmentedControl<String>(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: const {
                'male': Text('MALE'),
                'female': Text('FEMALE'),
                '': Text('OTHER'),
              },
              groupValue: _gender,
              onValueChanged: updateGender,
            ),
            Text(homepageL10n.gendered(_gender)),
            const Divider(),
            Text(
              counterL10n.clicked(_counter),
              style: theme.textTheme.headline4,
            ),
            TextButton(
              onPressed: resetCounter,
              child: Text(counterL10n.resetCounter),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: incrementCounter,
        tooltip: counterL10n.clickMe,
        child: const Icon(Icons.add),
      ),
    );
  }

  void incrementCounter() => setState(() => _counter++);

  void resetCounter() => setState(() => _counter = 0);

  void updateGender(String gender) => setState(() => _gender = gender);
}
