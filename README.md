# BabelFish
<img src="BabelFish.png">

A proof of concept, parser and compiler to provide a means for compile time protection for localization strings for Xcode projects

![Swift](https://img.shields.io/badge/Swift-5.6-orange) ![Xcode](https://img.shields.io/badge/Xcode-13.3-orange) ![macOS](https://img.shields.io/badge/macOS-12.1-orange)

# Why?

Because string literals in code are dangerous, it's too easy to make a typo and there's no way to know until after you've run the code, which, in a suitably complex code base, might not always be picked up immediately.

Localization keys are prone to change and removal, again, there is no compile time check to catch this and these changes could go unnoticed for some time.

The intention is to take something like…

    placeholderLabel.text = "Label.Select".localized()

and replace it with something more robust, for example…

    placeholderLabel.text = Strings.Label.select.localized()

This approach would also have support for parameter and plural based localisations, for example...

    "TimeOffRequest.Label.Type(%@)".localized(timeOffSubType.name).localized()

would become

    Strings.TimeOffRequest.Label.typeWith(timeOffSubType.name).localized()

and 

    "Label.(%d)YearsOld".localized(Day.today.years(since: birthday))

would become 

    Strings.Label.yearsOldPluralWith(Day.today.years(since: birthday)).localized()
    
# Parameters

Localization keys with parameters are inspected and an attempt is made to determine the parameter type (based on [String Format Specifiers](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html)), where the parameter type can't be determine, it's parameter type is defaulted to `CVarArg`

# Ouput

The project is intended to be able to parse multiple localization sources (bundle based) and generate a `.swift` file which can then be included in the project.

Currently the project can produce a `enum` containing all the localisation keys.  Because of the way `enum` works, it is required that an additional call is needed to perform the actually tranlsation, for example, `Strings.TimeOffRequest.Label.typeWith(timeOffSubType.name)` would require a call to `.localized()` to generate the localized `String`.

The intention is to also provide a `struct` which would internally generate the localized `String`, so you'd only need to call `Strings.TimeOffRequest.Label.typeWith(timeOffSubType.name)` and the function would automatically load the translation for the specified key.

This approach is generally simpler, as the `enum` approach requires a significant more amount of "boiler plate" code (under the hood) to achieve the same result and the `struct` approach will automatically return the `String` without a need for an additional function call.

## `enum` draw backs

    /// Level (%d/%d)
    case level(_ p0: Int, _ p1: Int)
    /// Level %d
    case level(_ p0: Int)
    /// Level
    case level
    
Would all be considered the "same" case, to this end, the API needs to make a number of "assumptions" in order to over come it, for example...

    /// Level (%d/%d)
    case levelOfWith(_ p0: Int, _ p1: Int)
    /// Level %d
    case levelWith(_ p0: Int)
    /// Level
    case level

We also have the same issue with the plural terms, which means they tend to have `PluralWith` appended to the key name
 
# Helpful hints

The code generator will also include the "term" (in this case, the English term) as part of the key's documentation, for example...

    public enum Alert {
        /// Sorry, this shift type is not supported for approval workflow
        case unsupportedShiftTypeForApprovalWorkflow

# Preperations

In order to lookup the translations from different bundles, each bundle requires a means by which it can be identified.

To achieve this, it's required that each bundle provide a simple `static` identifier, for example...

    extension Bundle {
        public static var local: Bundle { return Bundle.main }
    }

The code generator will then make use of this identifier when calling `NSLocalizedString` for a given key.

# What doesn't it do?

The code generator DOES NOT actively monitor for duplicate keys, if duplicate keys do exist, then the resulting code simply won't compile.
