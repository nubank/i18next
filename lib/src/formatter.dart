// ignore_for_file: lines_longer_than_80_chars

import 'dart:ui';

import 'options.dart';

/// Formats the [value] based on the [formats].
///
/// For every format in [formats], it'll check if there is an associated
/// [ValueFormatter] in [options].
/// If so then calls it and keeps formatting the result for the remaining
/// formats until it returns the final object where it will result in
/// its [Object.toString] call.
String? format(
  Object? value,
  Iterable<String> formats,
  Locale locale,
  I18NextOptions options,
) {
  value = formats.fold<Object?>(value, (val, format) {
    try {
      final parsedFormat = parseFormatString(format);
      final formatter = options.formats[parsedFormat.name];
      if (formatter != null) {
        val = formatter(val, parsedFormat.options, locale, options);
      }
    } catch (error, stackTrace) {
      assert(
        false,
        'Formatting failed for "$format".\n'
        '$error\n$stackTrace',
      );
    }
    return val;
  });
  return value?.toString();
}

/// Parses the format name its options
/// Examples
/// "Some format {{value, formatName}}",
/// "Some format {{value, formatName(optionName: optionValue)}}",
/// "Some format {{value, formatName(option1Name: option1Value; option2Name: option2Value)}}"
ParseResult parseFormatString(
  String formatString, {
  String keyValueSeparator = ':',
  String optionSeparator = ';',
}) {
  var formatName = formatString.trim();
  final formatOptions = <String, Object>{};
  if (formatName.contains('(')) {
    final parts = formatName.split('(');
    formatName = parts[0].trim();
    final optionString = parts[1].substring(0, parts[1].length - 1);
    final options = optionString
        .split(optionSeparator)
        .where((element) => element.isNotEmpty);

    for (final option in options) {
      // splits and uses the first value (before :) as the key, and the rest
      // as the value (which might contain : chars)
      final optSplit = option.split(keyValueSeparator);
      final key = optSplit.first.trim();
      final value = optSplit.sublist(1).join(keyValueSeparator).trim();

      if (value == 'false') formatOptions[key] = false;
      if (value == 'true') formatOptions[key] = true;
      if (formatOptions[key] == null) formatOptions[key] = value;
    }
  }

  return ParseResult(formatName, formatOptions);
}

class ParseResult {
  ParseResult(this.name, this.options);

  /// The name of the format
  final String name;

  /// The options that were associated to [name].
  final Map<String, Object> options;

  @override
  bool operator ==(Object other) =>
      other is ParseResult && other.name == name && other.options == options;

  @override
  int get hashCode => hashValues(name, options);

  @override
  String toString() => '($name, $options)';
}
