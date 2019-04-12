//
//  PathControl.swift
//  Svg to Png
//
//  Created by Todd Denlinger on 3/7/19.
//  Copyright © 2019 Todd. All rights reserved.
//

import Cocoa

protocol PathControlDelegate {
    func pathChanged(_ url: URL?)
}

class PathControl: NSPathControl {
    struct Menu {
        static let Choose = "Choose…"
        static let ChooseNone = "Choose None"
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        finishInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        finishInit()
    }

    fileprivate func finishInit() {
        delegate = self
        pathStyle = .popUp
        action = #selector(PathControl.pathChanged(_:))
    }

    override var pathStyle: NSPathControl.Style {
        get { return Style.popUp }
        set { super.pathStyle = Style.popUp }
    }

    var pathControlDelegate: PathControlDelegate?

    @objc func selectNone(_: Any?) {
        url = nil
        pathChanged(self)
    }

    @objc func pathChanged(_: Any?) {
        pathControlDelegate?.pathChanged(url)
    }
}

extension PathControl: NSPathControlDelegate {
    func pathControl(_: NSPathControl, willDisplay openPanel: NSOpenPanel) {
        openPanel.canChooseFiles = false
        openPanel.prompt = "Choose"
    }

    func pathControl(_ pathControl: NSPathControl, willPopUp menu: NSMenu) {
//      this is critical!  If the pathControl is not first responder,
//      the the added menu item (Menu.ChooseNone - see below) will always be disabled
        if let window = window {
            window.makeFirstResponder(pathControl)
        }

        let noneItem = menu.item(withTitle: Menu.ChooseNone)

        if noneItem == nil {
            let menuItem = NSMenuItem(title: Menu.ChooseNone, action: #selector(PathControl.selectNone(_:)), keyEquivalent: "")

            if pathControl.url == nil {
                menuItem.state = .on
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let chooseItem = menu.item(withTitle: Menu.Choose) {
                        chooseItem.state = .off
                    }
                }
            }

            menu.insertItem(menuItem, at: 1)
        }
    }
}
