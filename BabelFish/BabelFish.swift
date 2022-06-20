//
//  main.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import Rainbow
import CoreExtensions
import AppKit

enum Error: Swift.Error {
    case noAvailableInputs
    case invalidSourcePath
    case noAvailableOutputs
}

@main
struct BabelFish {
    static func main() throws {
        do {
            let argumentParser = ArgumentsParser(arguments: CommandLine.arguments)
            let properties = try argumentParser.gather()
            
            let parsers = properties
                .compactMap { value -> [LocalisationParser]? in
                    switch value {
                    case let .bundle(bundle, path):
                        return [
                            LocalizedStringsParser(bundleSource: bundle, sourcePath: path),
                            LocalizedDictionaryParser(bundleSource: bundle, sourcePath: path)
                        ]
                    default: return nil
                    }
                }
                .flatMap { $0 }
            
            if parsers.isEmpty {
                throw Error.noAvailableInputs
            }
            
            //        var keyTerms = [LocalizedKeyTerm]()
            //        for parser in parsers {
            //            // Key conflicts resolved by preferring
            //            // the new value
            //            keyTerms.append(contentsOf: try parser.parse())
            //        }
            
            let keyTerms = try parsers
                .map { try $0.parse() }
                .flatMap { $0 }
            
            let grouped = BuilderGroupBuilder.build(keyTerms)
            
            let desiredOutputs = properties
                .compactMap { value -> OutputType? in
                    switch value {
                    case let .output(type): return type
                    default: return nil
                    }
                }
            
            if parsers.isEmpty {
                throw Error.noAvailableOutputs
            }
            
            for desiredOutput in desiredOutputs {
                var builder: Builder?
                var destination: String?
                switch desiredOutput {
                case .enum:
                    builder = EnumBuilder(builderGroup: grouped)
                    destination = "StringsEnum.swift"
                case .struct:
                    builder = StructBuilder(builderGroup: grouped)
                    destination = "StringsStruct.swift"
                }
                guard let builder = builder else {
                    warning("No builder available for \(desiredOutput)")
                    continue
                }
                guard let destination = destination else {
                    warning("No destination specified for \(desiredOutput)")
                    continue
                }
                let build = builder.build(keyTerms).trimmed
                debug("Write \(desiredOutput) output to \(destination)")
                try build.data(using: .utf8)!.write(to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(destination))
            }
        } catch {
            guard error is ArgumentsParser.Error else {
                throw error
            }
            printUsage()
        }
    }
    
    private static func printUsage() {
        print("Usage BabelFish --output [struct/enum] {--output [struct/enum]} --source{group} [path] --bundle{group} [bundle]")
        print("")
        print("WHERE:")
        print("    --output <value> Represents the desired output format. Valid values are \"struct\" or \"enum\"")
        print("    --source <value> Represents the source location of the \"en.lproj\" folder")
        print("    --bundle <value> Represents the name of the bundle identifier (this must be defined in the source project)")
        print("")
        print("Both --source and --bundle may specify an optional numerical \"group\" identifier. This allows you to specify multiple inputs (ie source project and dependency projects) which will be combined together")
    }
}
