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
