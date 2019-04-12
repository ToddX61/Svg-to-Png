//
//  Set.swift
//  Svg to Png
//
//  Created by Todd Denlinger on 3/8/19.
//  Copyright © 2019 Todd. All rights reserved.
//

// from: https://nshipster.com/optionset/

import Foundation

protocol Option: RawRepresentable, Hashable, CaseIterable {}

extension Set where Element: Option {
    var rawValue: Int {
        var rawValue = 0
        for (index, element) in Element.allCases.enumerated() {
            if contains(element) {
                rawValue |= (1 << index)
            }
        }

        return rawValue
    }

    static func create(rawValue: Int) -> Set<Element> {
        var result = Set<Element>()

        for (index, element) in Element.allCases.enumerated() {
            if (1 << index) & rawValue != 0 {
                result.insert(element)
            }
        }

        return result
    }
}

extension Set where Element: Option {
    var description: String {
        var result = String()
        let lastIdx = count - 1

        for (idx, error) in enumerated() {
            result.append(String(describing: error).transformEnumValue())
            if idx != lastIdx {
                result.append(", ")
            }
        }

        return result
    }
}
