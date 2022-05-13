//
//  Builder.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation

protocol Builder {
    func build(_ keyTerms: [LocalizedKeyTerm]) -> String
}

class AbstractBuilder: Builder {

    let masterGroup: BuilderGroup
    
    init(builderGroup: BuilderGroup) {
        masterGroup = builderGroup
    }

    func build(_ keyTerms: [LocalizedKeyTerm]) -> String {
        fatalError("Not implemented")
    }
}

class BuilderGroup {
    let name: String
    var groups = [String: BuilderGroup]()
    var cases = [(String, LocalizedKeyTerm)]()
    
    init(name: String) {
        self.name = name
    }
}

class BuilderGroupBuilder {

    let masterGroup = BuilderGroup(name: "Strings")

    private init() {
    }
    
    static func build(_ keyTerms: [LocalizedKeyTerm]) -> BuilderGroup {
        let builder = BuilderGroupBuilder()
        return builder.make(keyTerms)
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
            return text.split(separator: "_").map { String($0).uppercasedFirst() }
        } else if text.contains(".") {
            return text.split(separator: ".").map { String($0).uppercasedFirst() }
        }
        return []
    }
    
    func make(_ keyTerms: [LocalizedKeyTerm]) -> BuilderGroup {
        for keyTerm in keyTerms {
            group(keyTerm)
        }
        return masterGroup
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
    
    private func findGroup(_ groups: [String]) -> BuilderGroup {
        var currentGroup: BuilderGroup?
        var keyList = groups
        while !keyList.isEmpty {
            let key = keyList.first!
            currentGroup = groupFor(key, from: currentGroup)
            keyList = Array(keyList.dropFirst())
        }
        return currentGroup!
    }

    private func groupFor(_ key: String) -> BuilderGroup {
        if let group = masterGroup.groups[key] {
            return group
        }
        let group = BuilderGroup(name: key)
        masterGroup.groups[key] = group
        return group
    }

    private func groupFor(_ key: String, from group: BuilderGroup?) -> BuilderGroup {
        guard let group = group else {
            return groupFor(key)
        }
        if let group = group.groups[key] {
            return group
        }
        let newGroup = BuilderGroup(name: key)
        group.groups[key] = newGroup
        return newGroup
    }

}

extension String {
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
    
    var trailingTrimmed: String {
        var newString = self
        while newString.last?.isWhitespace == true {
            newString = String(newString.dropLast())
        }
        return newString
    }
    
    var dropLastIfWhiteSpace: String {
        if last?.isWhitespace ?? false {
            return String(self.dropLast())
        }
        return self
    }
}

extension FormatSpecifier {
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
