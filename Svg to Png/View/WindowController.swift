//
//  WindowController.swift
//  Svg to Png
//
//  Created by Todd Denlinger on 3/1/19.
//  Copyright © 2019 Todd. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        shouldCascadeWindows = true
    }
}
