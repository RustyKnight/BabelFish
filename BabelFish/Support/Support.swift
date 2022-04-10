//
//  Support.swift
//  BabelFish
//
//  Created by Shane Whitehead on 9/4/2022.
//

import Foundation
import Rainbow

func warning(_ value: String) {
    print("\("!!".bold) \(value)".yellow)
}

func notify(_ value: String) {
    print(value.green)
}

func debug(_ value: String) {
    print(value.lightBlack)
}
