//
//  EnumBuilder.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import CoreExtensions

private class Group {
    let name: String
    var groups = [String: Group]()
    var cases = [(String, LocalizedKeyTerm)]()
    
    init(name: String) {
        self.name = name
    }
}

private extension String {
    func lowercasedFirst() -> String {
      return prefix(1).lowercased() + self.dropFirst()
    }

    mutating func lowercaseFirst() {
      self = self.lowercasedFirst()
    }

    func uppercasedFirst() -> String {
      return prefix(1).uppercased() + self.dropFirst()
    }

    mutating func uppercaseFirst() {
      self = self.uppercasedFirst()
    }
}

private extension FormatSpecifier {
    var asParameter: String {
        switch self {
        case .any: return "CVarArg" // When all else fails
        case .integer: return "Int"
        case .unsignedInteger: return "UInt"
        case .hex: return "UInt"
        case .octal: return "UInt"
        case .double: return "Double"
        case .doubleScientificNotation: return "Double"
        case .exponent: return "Double"
        case .unsignedCharacter: return "Character"
        case .unicharacter: return "Character"
        case .unsigned8BitCharacters: return "CVarArg"
        case .unsigned16BitCharacters: return "CVarArg"
        case .doubleHexScientificNotation: return "Double"
        case .doubleDecimalNotation: return "Double"
        }
    }
}

class EnumBuilder: Builder {

    private let masterGroup = Group(name: "Strings")
    
    func build(_ keyTerms: [LocalizedKeyTerm]) -> String {
        for keyTerm in keyTerms {
            group(keyTerm)
        }

        var joiner = StringJoiner(separator: "\n")
        joiner.append(localizableProtocol)
        joiner.append("")
        joiner.append(localizableSupportProtocol)
        joiner.append("")
        joiner.append(buildEnum())
        joiner.append("")
        joiner.append(buildCaseExtensions())
        return joiner.build()
    }
    
    private func buildEnum() -> String {
        return buildEnum(masterGroup)
    }
    
    private func fixEnumName(_ value: String) -> String {
        if value == "Type" {
            return "TypeOf"
        } else if value == "For" {
            return "`For`"
        }
        return value
    }
    
    private func buildEnum(_ group: Group, indent: String = "") -> String {
        var joiner = StringJoiner(separator: "\n")
        joiner.append("\(indent)public enum \(fixEnumName(group.name)) {")
        
        let sortedCases = group.cases.sorted { lhs, rhs in
            lhs.0 > rhs.0
        }
        for keyTermCase in sortedCases {
            joiner.append(toCase(keyTermCase, indent: indent + "    "))
        }
        
        let groupKeys = group.groups.keys.sorted()
        for key in groupKeys {
            let subGroup = group.groups[key]!
            joiner.append(buildEnum(subGroup, indent: indent +  "    "))
        }
        joiner.append("\(indent)}")
        
        return joiner.build()
    }
    
    private func name(_ keyCase: (String, LocalizedKeyTerm)) -> String {
        var name = keyCase.0.trimmed.lowercasedFirst()
        if name == "for" {
            name = "`for`"
        } else if name.contains(" ") {
            let parts = name.split(separator: " ")
            name = String(parts.first!)
            name += parts.dropFirst().map { String($0).uppercasedFirst() }.joined()
        }
        
        if keyCase.1.terms.count > 1 {
            name += "Plural"
        }
        if !keyCase.1.formatSpecifiers.isEmpty {
                name += "With"
        }
        return name
    }
    
    private func toCase(_ keyCase: (String, LocalizedKeyTerm), indent: String) -> String {
        var text = "\(indent)case \(name(keyCase))"
        let keyTerm = keyCase.1
        if !keyTerm.formatSpecifiers.isEmpty {
            var joiner = StringJoiner(prefix: "(", separator: ", ", suffix: ")")
            for (index, specifier) in keyTerm.formatSpecifiers.enumerated() {
                joiner.append("_ p\(index): \(specifier.asParameter)")
            }
            text += joiner.build()
        }
        var joiner = StringJoiner(separator: "\n")
        for term in keyTerm.terms {
            joiner.append("\(indent)/// \(term)")
        }
        joiner.append(text)
        return joiner.build()
    }

    private func buildCaseExtensions() -> String {
        return buildCaseExtensions([], group: masterGroup)
    }

    private func buildCaseExtensions(_ parentKeys: [String], group: Group) -> String{
        var text = ""
        let cases = group.cases
        var newKeys = parentKeys;
        newKeys.append(fixEnumName(group.name))
        if !cases.isEmpty {
            let extName = newKeys.joined(separator: ".")
            var joiner = StringJoiner(separator: "\n")
            joiner.append("extension \(extName): LocalizableSupport {")
            joiner.append("    var localizedKey: String {")
            joiner.append("        switch self {")
            for termCase in cases {
                joiner.append("            case .\(name(termCase)): return \"\(termCase.1.key)\"")
            }
            joiner.append("        }")
            joiner.append("    }")
            joiner.append("")
            joiner.append("    var arguments: [CVarArg]? {")
            joiner.append("        switch self {")
            for termCase in cases {
                let specifiers = termCase.1.formatSpecifiers
                if specifiers.isEmpty {
                    joiner.append("            case .\(name(termCase)): return nil")
                } else {
                    var argumentJoiner = StringJoiner(separator: ", ")
                    var returnJoiner = StringJoiner(separator: ", ")
                    for (index, _) in specifiers.enumerated() {
                        argumentJoiner.append("let p\(index)")
                        returnJoiner.append("p\(index)")
                    }
                    joiner.append("            case .\(name(termCase))(\(argumentJoiner.build())): return [\(returnJoiner.build())]")
                }
            }
            joiner.append("        }")
            joiner.append("    }")
            joiner.append("")
            joiner.append("    var bundle: Bundle {")
            joiner.append("        switch self {")
            for termCase in cases {
                joiner.append("            case .\(name(termCase)): return \(termCase.1.bundle.value)")
            }
            joiner.append("        }")
            joiner.append("    }")
            joiner.append("}")
            joiner.append("")
            joiner.append("")
            text += joiner.build()
        }
        for subGroup in group.groups {
            text += buildCaseExtensions(newKeys, group: subGroup.value)
        }
        return text
    }
    
    private func cleanKey(_ key: String) -> String {
        return key
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "%d", with: "")
            .replacingOccurrences(of: "%@", with: "")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "/", with: "XOfX")
            .replacingOccurrences(of: "..", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ":", with: "")
    }
    
    private func keyGroups(from text: String) -> [String] {
        //key.split(separator: ".").map { String($0) }
        if text.contains("_") {
            return text.split(separator: "_").map { String($0) }
        } else if text.contains(".") {
            return text.split(separator: ".").map { String($0) }
        }
        return []
    }
    
    private func group(_ keyTerm: LocalizedKeyTerm) {
        let key = cleanKey(keyTerm.key)
        var groups = keyGroups(from: key)
        if !groups.isEmpty {
            let caseName = groups.last!
            groups = groups.dropLast()
            let group = findGroup(groups)
            
            group.cases.append((caseName, keyTerm))
        } else {
            masterGroup.cases.append((keyTerm.key, keyTerm))
        }
    }
    
    private func findGroup(_ groups: [String]) -> Group {
        var currentGroup: Group?
        var keyList = groups
        while !keyList.isEmpty {
            let key = keyList.first!
            currentGroup = groupFor(key, from: currentGroup)
            keyList = Array(keyList.dropFirst())
        }
        return currentGroup!
    }

    private func groupFor(_ key: String) -> Group {
        if let group = masterGroup.groups[key] {
            return group
        }
        let group = Group(name: key)
        masterGroup.groups[key] = group
        return group
    }

    private func groupFor(_ key: String, from group: Group?) -> Group {
        guard let group = group else {
            return groupFor(key)
        }
        if let group = group.groups[key] {
            return group
        }
        let newGroup = Group(name: key)
        group.groups[key] = newGroup
        return newGroup
    }
}

private let localizableProtocol = """
public protocol Localizable {
    func localized() -> String
}
"""
private let localizableSupportProtocol = """
protocol LocalizableSupport: Localizable {
    var arguments: [CVarArg]? { get }
    var localizedKey: String { get }
    var bundle: Bundle { get }
}

extension LocalizableSupport {
    private func format(_ value: String) -> String {
        guard let arguments = arguments else { return value }
        return String(format: value, arguments: arguments)
    }

    public func localized() -> String {
        return format(NSLocalizedString(localizedKey, bundle: bundle, comment: ""))
    }
}
"""

//public protocol Localizable {
//    func localized() -> String
//}
//protocol LocalizableSupport: Localizable {
//    var arguments: [CVarArg]? { get }
//    var localizedKey: String { get }
//    var bundle: Bundle { get }
//}
//
//extension LocalizableSupport {
//    private func format(_ value: String) -> String {
//        guard let arguments = arguments else { return value }
//        return String(format: value, arguments: arguments)
//    }
//
//    public func localized() -> String {
//        return format(NSLocalizedString(localizedKey, bundle: bundle, comment: ""))
//    }
//}
//
//public enum Strings {
//    public enum TimeOffRequest {
//        public enum Label {
//            case type(_ p0: CVarArg)
//        }
//    }
//}
//
//extension Strings.TimeOffRequest.Label: LocalizableSupport {
//    var arguments: [CVarArg]? {
//        switch self {
//        case .type(let p1): return [p1]
//        }
//    }
//
//    var localizedKey: String {
//        switch self {
//        case .type: return "TimeOffRequest.Label.Type(%@)"
//        }
//    }
//
//    var bundle: Bundle {
//        switch self {
//        case .type: return .module
//        }
//    }
//}

//
//    private func format(_ value: String) -> String {
//        guard let arguments = arguments else { return value }
//        return String(format: value, arguments: arguments)
//    }
//
//    public func localized() -> String {
//        switch self {
//        case .type: return format(NSLocalizedString(localizedKey, bundle: bundle, comment: ""))
//        }
//    }


//
//public enum Strings {
//    public enum TimeOffRequest {
//        public enum Label {
//            case type(_ value: CVarArg)
//        }
//        case duration(_ value: CVarArg)
//        public enum TimeOffRequest {
//            public enum Summary {
//                case singleDay(_ p1: CVarArg, p2: CVarArg)
//                case multipleDays(_ p1: CVarArg, p2: CVarArg)
//            }
//            case timeRange(_ p1: CVarArg, p2: CVarArg)
//            case DaysAndHoursEachDay(_ p1: CVarArg, p2: CVarArg)
//        }
//    }
//}

extension Bundle {
    static let module = Bundle.main
}
//
//extension Strings.TimeOffRequest.Label: LocalizableSupport {
//
//    private func format(_ value: String) -> String {
//        guard let arguments = arguments else { return value }
//        return String(format: value, arguments: arguments)
//    }
//
//    public func localized() -> String {
//        switch self {
//        case .type: return format(NSLocalizedString(localizedKey, bundle: bundle, comment: ""))
//        }
//    }
//
//    var arguments: [CVarArg]? {
//        switch self {
//        case .type(let p1): return [p1]
//        }
//    }
//
//    var localizedKey: String {
//        switch self {
//        case .type: return "TimeOffRequest.Label.Type(%@)"
//        }
//    }
//
//    var bundle: Bundle {
//        switch self {
//        case .type: return .module
//        }
//    }
//}

//extension UILabel {
//    func setText(_ value: Localizable) {
//        self.text = value.localized()
//    }
//}
//
//let label = UILabel()
//label.setText(Strings.TimeOffRequest.Label.type(0))
