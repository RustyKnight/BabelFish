//
//  ArgumentsParser.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import CoreExtensions

/// Acceptable output types
enum OutputType: String {
    case `struct` = "struct"
    case `enum` = "enum"
}

/// Core command line parameters
enum ArgumentProperties {
    case bundle(_ bundle: String, path: String)
    case output(OutputType)
}

struct ArgumentsParser {
    enum Error: Swift.Error {
        case noArguments
        case unknownOutputType(String)
        case missingArgumentAt(Int)
    }

    /// Possible repeating arguments.  A repeating argument is expected
    /// to come in "groups", each "group" will contain all of these arguments
    private enum RepeatableArgument: String, CaseIterable {
        case source = "source"
        case bundle = "bundle"
    }
    
    /// Other arguments, there should only be one of these
    private enum Argument: String {
        case output = "output"
    }
    
    /// Grouped argument parameters
    private enum SourceParameter {
        case bundle(String)
        case path(String)
    }
    
    private let arguments: [String]
    
    init(arguments: [String]) {
        self.arguments = arguments
    }
    
    // This gets checked so often, wrapped it up in a simple repeated workflow
    private func errorOrValueAt(_ index: Int, from input: [String]) throws -> String {
        guard index < input.count else {
            throw Error.missingArgumentAt(index)
        }
        return input[index]
    }
    
    func gather() throws -> [ArgumentProperties] {
        guard arguments.count > 1 else {
            throw Error.noArguments
        }
        // Repeated group parameters
        var inputGroups = [Int: [SourceParameter]]()
        // Final output
        var properties = [ArgumentProperties]()
        var index = 1
        while index < arguments.count {
            defer {
                index += 1
            }
            // Get the next argument
            var argument = try errorOrValueAt(index, from: arguments)
            // All arguments should start with --
            guard argument.hasPrefix("--") else {
                warning("\(index) Skipping \(argument)")
                continue;
            }
            
            // Remove the argument prefix
            argument = argument.replacingOccurrences(of: "--", with: "")
            // Check the repeating arguments
            for repeatedArgument in RepeatableArgument.allCases {
                // The argument may end with a group number
                if argument.hasPrefix(repeatedArgument.rawValue) {
                    // Remove the argument prefix
                    let groupKey = argument.replacingOccurrences(of: repeatedArgument.rawValue, with: "")
                    // Create the group identifier
                    // A repeatable argument may not have a group identifier, which is acceptable
                    let groupIndex = Int(groupKey) ?? 0
                    // Get the value for this argument
                    index += 1
                    argument = try errorOrValueAt(index, from: arguments)
                    
                    // Store the argument with the group, because, obviously we don't
                    // know ahead of time
                    var groupedParameters = inputGroups[groupIndex] ?? [SourceParameter]()
                    switch repeatedArgument {
                    case .bundle: groupedParameters.append(.bundle(argument))
                    case .source: groupedParameters.append(.path(argument))
                    }
                    inputGroups[groupIndex] = groupedParameters
                }
            }
            
            // Process the other arguments
            if argument == Argument.output.rawValue {
                index += 1
                argument = try errorOrValueAt(index, from: arguments)
                if let type = OutputType(rawValue: argument) {
                    properties.append(.output(type))
                } else {
                    throw Error.unknownOutputType(argument)
                }
            }
        }
        
        // Process the grouped input arguments
        for (key, values) in inputGroups {
            // We only expect to find 2 arguments per group
            guard values.count == 2 else {
                warning("Input group \(key) has an invalid number of properties (\(values.count), expecting 2)")
                continue
            }
            // Get the bundle name and source path for the group
            var bundleName: String?
            var sourcePath: String?
            for value in values {
                switch value {
                case .path(let path): sourcePath = path
                case .bundle(let bundle): bundleName = bundle
                }
            }
            // Verify we have what we need
            guard let bundleName = bundleName else {
                warning("Input group \(key) is missing bundle identifier")
                continue
            }
            guard let sourcePath = sourcePath else {
                warning("Input group \(key) is missing source path")
                continue
            }
            // Append them to the properties
            properties.append(.bundle(bundleName, path: sourcePath))
        }
        
        return properties
    }
}
