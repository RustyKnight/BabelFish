//
//  SwiftLint.swift
//  BabelFish
//
//  Created by Shane Whitehead on 13/5/2022.
//

import Foundation

enum SwiftLint: CustomStringConvertible {
    case disable(Rule)
    case enable(Rule)
    
    enum Rule: String, CustomStringConvertible {
        case fileLength = "file_length"
        case typeBodyLength = "type_body_length"
        
        var description: String {
            return self.rawValue
        }
    }
    
    var description: String {
        var text = "// swiftlint:"
        switch self {
        case let .disable(rule):
            text += "disable \(rule)"
        case let .enable(rule):
            text += "enable \(rule)"
        }
        return text
    }
}
