//
//  StructBuilder.swift
//  BabelFish
//
//  Created by Shane Whitehead on 11/5/2022.
//

import Foundation
import CoreExtensions

//private extension String {
//    func localized(_ bundle: Bundle) -> String {
//        return NSLocalizedString(self, bundle: bundle, comment: "")
//    }
//
//    func localized(arguments: [CVarArg], bundle: Bundle) -> String {
//        return String(format: self, arguments: arguments).localized(bundle)
//    }
//}
//
//struct LocalizedStrings {
//    struct AboutUs {
//        static var heading: String = {
//            return "AboutUs.heading".localized(Bundle.main)
//        }()
//
//        static func heading(_ p0: Int, _ p1: String) -> String {
//            let arguments: [CVarArg] = [p0, p1]
//            return "AboutUs.heading".localized(arguments: arguments, bundle: .main)
//        }
//    }
//}

class StructBuilder: AbstractBuilder {
    
    override func build(_ keyTerms: [LocalizedKeyTerm]) -> String {
        var joiner = StringJoiner(separator: "\n")
        joiner.append("\(SwiftLint.disable(.fileLength))")
        joiner.append("import Foundation")
        joiner.append("")
        joiner.append(localisedExtensions)
        joiner.append("")
        joiner.append("\(SwiftLint.disable(.typeBodyLength))")
        joiner.append(buildStruct())
        joiner.append("\(SwiftLint.enable(.typeBodyLength))")
        joiner.append("\(SwiftLint.enable(.fileLength))")
        return joiner.build()
    }
    
    private func buildStruct() -> String {
        return buildStruct(masterGroup).trailingTrimmed
    }
    
    private func buildStruct(_ group: BuilderGroup, indent: String = "") -> String {
        var joiner = StringJoiner(separator: "\n")
        joiner.append("\(indent)public struct \(fixStructName(group.name)) {")
        let sortedCases = group.cases.sorted { $0.0 > $1.0 }
        for keyTermCase in sortedCases {
            joiner.append(format(keyTermCase, indent: indent + "    "))
        }
        
        
        let groupKeys = group.groups.keys.sorted()
        for key in groupKeys {
            let subGroup = group.groups[key]!
            joiner.append(buildStruct(subGroup, indent: indent + "    "))
        }
        var result = joiner.build().dropLastIfWhiteSpace
        result += "\n\(indent)}\n"
        
        return result
    }
    
    private func fixStructName(_ value: String) -> String {
        let name = value.trimmed
        if name == "Type" {
            return "TypeOf"
        } else if name == "For" {
            return "`For`"
        }
        return name
    }
    
    private func format(_ keyCase: (String, LocalizedKeyTerm), indent: String) -> String {
        var joiner = StringJoiner(separator: "\n")
        let keyTerm = keyCase.1
        for term in keyTerm.terms {
            joiner.append("\(indent)/// \(term)")
        }
        if keyTerm.formatSpecifiers.isEmpty {
            joiner.append("\(indent)public static var \(name(keyCase)): String = {")
            joiner.append("\(indent)    return \"\(keyTerm.key)\".localized(Bundle.\(keyTerm.bundle))")
            joiner.append("\(indent)}()")
        } else {
            var parameters = StringJoiner(separator: ", ")
            var arguments = StringJoiner(separator: ", ")
            for (index, specifier) in keyTerm.formatSpecifiers.enumerated() {
                parameters.append("_ p\(index): \(specifier.asParameter)")
                arguments.append("p\(index)")
            }
            joiner.append("\(indent)public static func \(name(keyCase))(\(parameters.build())) -> String {")
            joiner.append("\(indent)    let arguments: [CVarArg] = [\(arguments.build())]")
            joiner.append("\(indent)    return \"\(keyTerm.key)\".localized(arguments: arguments, bundle: Bundle.\(keyTerm.bundle))")
            joiner.append("\(indent)}")
        }
        joiner.append("")
        return joiner.build()
    }
        
    private func name(_ keyCase: (String, LocalizedKeyTerm)) -> String {
        var name = keyCase.0.trimmed.lowercasedFirst()
        if name == "for" {
            name = "`for`"
        } else if name == "in" {
            name = "`in`"
        } else if name == "is" {
            name = "`is`"
        } else if name.contains(" ") {
            let parts = name.split(separator: " ")
            name = String(parts.first!)
            name += parts.dropFirst().map { String($0).uppercasedFirst() }.joined()
        }
        
        if keyCase.1.terms.count > 1 {
            name += "Plural"
        }
//        if !keyCase.1.formatSpecifiers.isEmpty {
//                name += "With"
//        }
        return name
    }
    
    var localisedExtensions: String =
    """
    private extension String {
        func localized(_ bundle: Bundle) -> String {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }

        func localized(arguments: [CVarArg], bundle: Bundle) -> String {
            return String(format: self, arguments: arguments).localized(bundle)
        }
    }
    """

}
