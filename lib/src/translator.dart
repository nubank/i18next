import 'dart:ui';

import 'interpolator.dart';
import 'options.dart';
import 'plural_resolver.dart';
import 'resource_store.dart';

class Translator {
  Translator(
    this.interpolator,
    this.pluralResolver,
    this.resourceStore,
  )   : assert(interpolator != null),
        assert(pluralResolver != null),
        assert(resourceStore != null);

  final Interpolator interpolator;
  final PluralResolver pluralResolver;
  final ResourceStore resourceStore;

  String translate(
    String key,
    Locale locale,
    Map<String, Object> variables,
    I18NextOptions options,
  ) {
    assert(key != null);

    var namespace = '', keyPath = key;
    final match = RegExp(options.namespaceSeparator).firstMatch(key);
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }
    return translateKey(locale, namespace, keyPath, variables, options);
  }

  /// Order of key resolution:
  ///
  /// - context + pluralization:
  ///   ['key_ctx_plr', 'key_ctx', 'key_plr', 'key']
  /// - context only:
  ///   ['key_ctx', 'key']
  /// - pluralization only:
  ///   ['key_plr', 'key']
  /// - Otherwise:
  ///   ['key']
  String translateKey(
    Locale locale,
    String namespace,
    String key,
    Map<String, Object> variables,
    I18NextOptions options,
  ) {
    final String context = variables['context'];
    final int count = variables['count'];
    final needsContext = context != null && context.isNotEmpty;
    final needsPlural = count != null;

    String pluralSuffix;
    if (needsPlural) {
      pluralSuffix = pluralResolver.pluralize(
        count,
        options,
        (pluralModifier) => _checkForPluralKey(
          pluralModifier,
          baseKey: key,
          locale: locale,
          namespace: namespace,
          options: options,
        ),
      );
    }

    var tempKey = key;
    final keys = <String>[key];
    if (needsContext && needsPlural) {
      keys.add(tempKey + pluralSuffix);
    }
    if (needsContext) {
      keys.add(tempKey += '${options.contextSeparator}$context');
    }
    if (needsPlural) {
      keys.add(tempKey += pluralSuffix);
    }

    String result;
    while (keys.isNotEmpty) {
      final currentKey = keys.removeLast();
      final found = find(locale, namespace, currentKey, variables, options);
      if (found != null) {
        result = found;
        break;
      }
    }
    return result;
  }

  /// Attempts to find the value given a [namespace] and [key].
  ///
  /// If one is not found directly, then tries to fallback (if necessary). May
  /// still return null if none is found.
  String find(
    Locale locale,
    String namespace,
    String key,
    Map<String, Object> variables,
    I18NextOptions options,
  ) {
    final value = resourceStore.retrieve(locale, namespace, key, options);
    if (value == null) {
      // TODO: fallback locales
      // TODO: fallback namespaces
      // TODO: fallback to default value
    }

    String result;
    if (value != null) {
      result = interpolator.interpolate(locale, value, variables, options);
      result = interpolator.nest(locale, result, translate, variables, options);
    }
    return result;
  }

  bool _checkForPluralKey(
    String pluralModifier, {
    Locale locale,
    String namespace,
    String baseKey,
    I18NextOptions options,
  }) {
    final value = resourceStore.retrieve(
      locale,
      namespace,
      '$baseKey$pluralModifier',
      options,
    );

    return value != null;
  }
}
