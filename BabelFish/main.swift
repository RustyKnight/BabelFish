//
//  main.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import Rainbow
import CoreExtensions
//import ArgumentParser
//
//// There seems to be a "bug" https://forums.swift.org/t/main-not-working-yet-in-5-3/37288
//@main
//struct BabelFish: ParsableCommand {
//    @Argument
//    var inputSources: [String]
//
//    mutating func run() throws {
//        print("Hello \(inputSources)")
//    }
//}

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
//
//    var keyTerms = [LocalizedKeyTerm]()
////    "TimeOffRequest.Label.Type(%@)" = "Time off type: %@";
//    keyTerms.append(LocalizedKeyTerm(bundle: .main, key: "TimeOffRequest.Label.Type(%@)", terms: ["Time off type: %@"], formatSpecifiers: [.any]))
//
    let enumBuilder = EnumBuilder()
    let strings = enumBuilder.build(keyTerms).trimmed
    try strings.data(using: .utf8)!.write(to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Strings.swift"))
    print(strings)
} catch {
    print("Invalid arguments".yellow)
}
