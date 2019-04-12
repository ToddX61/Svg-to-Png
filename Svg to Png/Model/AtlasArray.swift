//
//  AtlasArray.swift
//  Svg to Png
//
//  Created by Todd Denlinger on 3/22/19.
//  Copyright © 2019 Todd. All rights reserved.
//

import Foundation

class AtlasArray: CustomStringConvertible {
    var atlases: [Atlas] 

    required init() { atlases = [Atlas]() }
    init(atlases: [Atlas]) { self.atlases = atlases }

    var description: String { return "\(atlases)" }

    func indexOf(folder: String) -> Int {
        var project = _Project()
        project.atlases = atlases
        return project.indexOf(folder: folder)
    }
}
