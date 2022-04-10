//
//  ArgumentsParser.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import CoreExtensions

enum ArgumentProperties {
    case bundle(_ bundle: BundleSource, path: String)
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
        for var index in 1..<arguments.count {
            let value = arguments[index].replacingOccurrences(of: "--", with: "")
            if let bundle = BundleSource.from(value) {
                guard index + 1 < arguments.count else {
                    warning("Bundle \(value.bold) is missing an associated resource path")
                    continue
                }
                index += 1
                let path = arguments[index]
                properties.append(.bundle(bundle, path: path))
            }
        }
        
        return properties
    }
}
