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

do {
    let properties = try ArgumentsParser.execute()
    var parsers = [LocalisationParser]()

    for property in properties {
        switch property {
        case .bundle(let bundle, let path):
            parsers.append(LocalizedStringsParser(bundleSource: bundle, sourcePath: path))
            parsers.append(LocalizedDictionaryParser(bundleSource: bundle, sourcePath: path))
        }
    }

    if parsers.isEmpty {
        warning("No input specified")
    }

    var keyTerms = [LocalizedKeyTerm]()
    for parser in parsers {
        // Key conflicts resolved by preferring
        // the new value
        keyTerms.append(contentsOf: parser.parse())
    }
    
    let grouped = BuilderGroupBuilder.build(keyTerms)
//
//    var keyTerms = [LocalizedKeyTerm]()
////    "TimeOffRequest.Label.Type(%@)" = "Time off type: %@";
//    keyTerms.append(LocalizedKeyTerm(bundle: .main, key: "TimeOffRequest.Label.Type(%@)", terms: ["Time off type: %@"], formatSpecifiers: [.any]))
//
    let enumBuilder = EnumBuilder(builderGroup: grouped)
    let enumStrings = enumBuilder.build(keyTerms).trimmed
    try enumStrings.data(using: .utf8)!.write(to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("StringsEnum.swift"))
    
    let structBuilder = StructBuilder(builderGroup: grouped)
    let structStrings = structBuilder.build(keyTerms).trimmed
    try structStrings.data(using: .utf8)!.write(to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("StringsStruct.swift"))
} catch {
    print("Invalid arguments".yellow)
}
