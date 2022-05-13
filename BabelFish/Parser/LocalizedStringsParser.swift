//
//  LocalizedStringsParser.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import CoreExtensions

enum FormatSpecifier {
    case any // %@
    case integer // %d/%D
    case unsignedInteger // %u/%U
    case hex(uppercase: Bool) // %x/%X
    case octal(uppercase: Bool) // %o/%O
    case double // %f
    case doubleScientificNotation(uppercase: Bool) // %e/%E
    case exponent(uppercase: Bool) // %g/%G
    case unsignedCharacter // %c
    case unicharacter // %C
    case unsigned8BitCharacters // %s
    case unsigned16BitCharacters // %S
    case doubleHexScientificNotation(uppercase: Bool) // %a/%A
    case doubleDecimalNotation // %F
    
    var asSpecifier: String {
        switch self {
        case .any: return "%@"
        case .integer: return "%d"
        case .unsignedInteger: return "%u"
        case .hex(let uppercase): return "%\(uppercase ? "X" : "x")"
        case .octal(let uppercase): return "%\(uppercase ? "O" : "o")"
        case .double: return "%f"
        case .doubleScientificNotation(let uppercase): return "%\(uppercase ? "E" : "e")"
        case .exponent(let uppercase): return "%\(uppercase ? "G" : "g")"
        case .unsignedCharacter: return "%c"
        case .unicharacter: return "%C"
        case .unsigned8BitCharacters: return "%s"
        case .unsigned16BitCharacters: return "%S"
        case .doubleHexScientificNotation(let uppercase): return "%\(uppercase ? "A" : "a")"
        case .doubleDecimalNotation: return "%F"
        }
    }
    
    static func from(_ value: String) -> FormatSpecifier {
        switch value.replacingOccurrences(of: "%", with: "") {
        case "@": return .any
        case "d": return .integer
        case "D": return .integer
        case "u": return .unsignedInteger
        case "U": return .unsignedInteger
        case "x": return .hex(uppercase: false)
        case "X": return .hex(uppercase: true)
        case "o": return .octal(uppercase: false)
        case "O": return .octal(uppercase: true)
        case "f": return .double
        case "e": return .doubleScientificNotation(uppercase: false)
        case "E": return .doubleScientificNotation(uppercase: true)
        case "g": return .exponent(uppercase: false)
        case "G": return .exponent(uppercase: true)
        case "c": return .unsignedCharacter
        case "C": return .unsigned8BitCharacters
        case "S": return .unsigned8BitCharacters
        case "a": return .doubleHexScientificNotation(uppercase: false)
        case "A": return .doubleHexScientificNotation(uppercase: true)
        case "F": return .doubleDecimalNotation
        default: return .any
        }
    }
    
    static func `in`(_ text: String) -> [FormatSpecifier] {
        do {
            let regex = try NSRegularExpression(pattern: "%[@dDuUxXoOfeEgGcCSaAf]")
            let results = regex.matches(
                in: text,
                range: NSRange(text.startIndex..., in: text)
            )
            return results
                .map { String(text[Range($0.range, in: text)!]) }
                .map { FormatSpecifier.from($0) }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

struct LocalizedKeyTerm {
    let bundle: String
    let key: String
    let terms: [String]
    let formatSpecifiers: [FormatSpecifier]
}

protocol LocalisationParser {
    func parse() -> [LocalizedKeyTerm]
}

class LocalizedStringsParser: LocalisationParser {
    let bundleSource: String
    let sourceURL: URL
    
    init(bundleSource: String, sourcePath: String) {
        self.bundleSource = bundleSource
        sourceURL = URL(fileURLWithPath: sourcePath)
    }
    
    func parse() -> [LocalizedKeyTerm] {
        let inputURL = sourceURL.appendingPathComponent("en.lproj", isDirectory: true).appendingPathComponent("Localizable.strings")
        guard FileManager.default.fileExists(atPath: inputURL) else {
            warning("\"\(sourceURL.path.bold)\" does not contain \"\("en.lproj/Localizable.strings".bold)\"")
            return []
        }
        
        var keyTerms = [LocalizedKeyTerm]()
        notify("Reading localisation strings from \(inputURL.path)")
        var keys = [String]()
        do {
            let text = try String(contentsOf: inputURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                guard line.starts(with: "\"") else { continue }
                let parts = line.split(separator: "=")
                guard parts.count == 2 else {
                    warning("Ignoring \(line)")
                    continue
                }
                let key = String(String(parts[0]).trimmed.dropFirst().dropLast())
                let term = String(String(parts[1]).trimmed.dropFirst().dropLast().dropLast())
                let formatSpecifiers = FormatSpecifier.in(term)
                
                keyTerms.append(LocalizedKeyTerm(bundle: bundleSource, key: key, terms: [term], formatSpecifiers: formatSpecifiers))
                
                guard keys.contains(key) else {
                    keys.append(key)
                    continue
                }
                warning("Duplicate key: [\(key.bold)]")
            }
        } catch {
            warning("Could not read contents of \"\(sourceURL.path.bold)\"")
        }
        return keyTerms
    }
}

class LocalizedDictionaryParser: LocalisationParser {
    let bundleSource: String
    let sourceURL: URL
    
    init(bundleSource: String, sourcePath: String) {
        self.bundleSource = bundleSource
        sourceURL = URL(fileURLWithPath: sourcePath)
    }
    
    func parse() -> [LocalizedKeyTerm] {
        let inputURL = sourceURL.appendingPathComponent("en.lproj", isDirectory: true).appendingPathComponent("Localizable.stringsdict")
        guard FileManager.default.fileExists(atPath: inputURL) else {
            warning("\"\(sourceURL.path.bold)\" does not contain \"\("en.lproj/Localizable.stringsdict".bold)\"")
            return []
        }
        notify("Reading localisation strings dictionary from \(inputURL.path)")
        guard let localisactionDict = NSDictionary(contentsOf: inputURL) as? [String: Any] else { return [] }
        
        var keyTerms = [LocalizedKeyTerm]()
        for (key, value) in localisactionDict {
            guard let value = value as? [String: Any] else {
                warning("\(key.bold) does not contain a valid sub set of values")
                continue
            }
            guard let originalKey = value["NSStringLocalizedFormatKey"] as? String, let formatKey = originalKey.slice(from: "#@", to: "@") else {
                warning("\(key.bold) does not contain a valid NSStringLocalizedFormatKey")
                continue
            }
            guard let formatDict = value[formatKey] as? [String: String] else {
                warning("\(key.bold).\(formatKey.bold) does not contain any format properties")
                continue
            }
            guard let keyType = formatDict["NSStringFormatValueTypeKey"] else {
                warning("\(key.bold).\(formatKey.bold) does not have a value type key")
                continue
            }
            let formatSpecifier = FormatSpecifier.from(keyType)
            
            // These are used to form part of the comments
            var terms = [String]()
            if let zero = formatDict["zero"] {
                terms.append("Zero: \(zero)")
            }
            if let one = formatDict["one"] {
                terms.append("One: \(one)")
            }
            if let two = formatDict["two"] {
                terms.append("Two: \(two)")
            }
            if let few = formatDict["few"] {
                terms.append("Few: \(few)")
            }
            if let many = formatDict["many"] {
                terms.append("Many: \(many)")
            }
            if let other = formatDict["other"] {
                terms.append("Other: \(other)")
            }

            keyTerms.append(LocalizedKeyTerm(bundle: bundleSource, key: key, terms: terms, formatSpecifiers: [formatSpecifier]))
        }
        
        return keyTerms
    }
}
