## [0.0.1+6]

* Migrated repository to `williamhjcho/i18next`

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
