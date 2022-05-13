//
//  ArgumentsParser.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import CoreExtensions

enum ArgumentProperties {
    case bundle(_ bundle: String, path: String)
}

struct ArgumentsParser {
    enum Error: Swift.Error {
        case noArguments
    }
    
    static func execute() throws -> [ArgumentProperties] {
        let arguments = CommandLine.arguments
        guard !arguments.isEmpty else {
            throw Error.noArguments
        }
        var properties = [ArgumentProperties]()
        var index = 1
        while index < arguments.count {
            defer {
                index += 1
            }
            guard arguments[index].hasPrefix("--") else {
                warning("\(index) Skipping \(arguments[index])")
                continue;
            }
            var bundle = arguments[index].replacingOccurrences(of: "--", with: "")
            if !bundle.hasPrefix(".") {
                bundle = "." + bundle
            }
            index += 1
            guard index < arguments.count else {
                warning("Bundle \(bundle.bold) is missing an associated resource path")
                continue
            }
            let path = arguments[index]
            properties.append(.bundle(bundle, path: path))
        }
        
        return properties
    }
}
