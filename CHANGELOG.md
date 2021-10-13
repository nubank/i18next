## [0.5.2]

* Fix: Unnecessary reloads of the localizationDataSource

## [0.5.1]

* Fix: Asset path (rely on Flutter asset specifications)

## [0.5.0]

* Adds support for multiple fallback namespaces

## [0.4.1]

* Officializes the null-safety migration

## [0.4.0-nullsafety.0]

* Migrates the codebase to flutter stable 2.0.3 + null-safety
  Renames `I18NextOptions.apply -> merge`

## [0.3.1]

* Renames `utils.dart -> definitions.dart`
* Adds and moves `evaluate` to `lib/utils.dart` as a part of the package, but without explicitly exporting it.
* Allows interpolations to access grouped variables like so:
  `'An example with {{grouped.key}}' + {'grouped': {'key': 'grouped keys'}} = 'An example with grouped keys'`
* Moves `lib/src/interpolator.dart` to `lib/interpolator.dart`
  To allow the interpolator usage as a separate package import

## [0.3.0]

* Bumps to flutter stable 1.20

## [0.2.0]

* Updates README bitrise badge
* Adds pluralization to non-english locales (Fixes #6) @lynn

## [0.1.0]

* Bumps to match flutter version 1.17

## [0.0.1+8]

* Bumps analysis options #9
* Adds fallback namespace #10
* Refactors Translator to a callable class #10
* Refactors interpolator class to global pure functions #10

## [0.0.1+7]

* Change the namespaces type from `Map<String, Map<String, Object>> -> Map<String, Object>`
* Adds I18Next.of(BuildContext) from Localizations
* Adds `I18NextLocalizationDelegate`
* Adds convenience methods to `ResourceStore` for adding, removing, and verifiying locales and namespaces
* Adds asset bundle data source and the LocalizationDataSource interface
* Changes links to nubank/i18next
* Adds example app

## [0.0.1+6]

* Migrated repository to `williamhjcho/i18next`
* Reduce description size

## [0.0.1+5]

* Adds plural separator in I18NextOptions
* Adds key separator in I18NextOptions
* Adds and replaces LocalizationDataSource for ResourceStore
* Makes `I18Next.t`'s parameters supersede the options parameter
* Removes `Map` extension from `I18NextOptions`
* Makes `I18NextOptions` `Diagnosticable`
* Improves and adds more cases on `Interpolator`

## [0.0.1+4]

* Renames arguments to variables
* Replaces InterpolationOptions for I18NextOptions
* Updates I18Next inner workings to more contextualized methods.
* Escapes interpolation strings in options for RegExp
* Adds base nesting mechanism
* Isolates Translator, PluralResolver, and Interpolator into separate classes
* Makes I18NextOptions's properties optional and allows individual overrides
* Makes I18NextOption conform to Map<String, Object>
* Reduces API surface by merging most of the optional properties into I18NextOptions itself
* Moves pattern builders from options to the classes themselves
* Keeps property variables in I18NextOptions while keeping Map extension.
* Adds/merges locale property in I18NextOptions

## [0.0.1+3]

* Adds InterpolationOption
* Allows locale and interpolation options override on `t`
* Adds a little more documentation

Internal:
* Splits data fetching and translation into separate methods

## [0.0.1] - TODO: Add release date.

* TODO: Describe initial release.
