import Cocoa

fileprivate class _Supression {
    
    static let Key = "_NSAlert.SuppressionKey"
    static let RemoveAll = "*.*"

    class func object(_ suppressionKey: String) -> String? {
        guard suppressionKey.isEmpty == false else { return nil }

        let defaults = UserDefaults.standard

        guard let keys = defaults.object(forKey: Key) as? [String] else { return nil }
        return keys.filter({ $0 == suppressionKey }).first
    }

    class func set(_ suppressionKey: String) {
        guard suppressionKey.isEmpty == false else { return }
        precondition(suppressionKey != RemoveAll, "SuppressionKey '\(RemoveAll)' is not allowed")

        let defaults = UserDefaults.standard
        var keys = defaults.object(forKey: Key) as? [String]

        if keys == nil {
            keys = [String]()
        }

        if keys!.contains(suppressionKey) == false {
            keys!.append(suppressionKey)
            defaults.set(keys!, forKey: Key)
        }
    }

    class func remove(_ suppressionKey: String) {
        guard suppressionKey.isEmpty == false else { return }

        let defaults = UserDefaults.standard

        if suppressionKey == RemoveAll {
            defaults.removeObject(forKey: Key)
            return
        }

        guard let keys = defaults.object(forKey: Key) as? [String] else { return }

        if keys.isEmpty {
            defaults.removeObject(forKey: Key)
        }
        else {
            defaults.set(keys.filter({ $0 != suppressionKey }), forKey: Key)
        }
    }
}

extension NSAlert {
    
    class func hasSuppressionKey(_ key: String ) -> Bool {
            return _Supression.object(key) != nil
    }
    
    class func setSuppressionKey(_ key: String) {
        _Supression.set(key)
    }
    
    class func removeSuppressionKey(_ key: String) {
        precondition(key != _Supression.RemoveAll, "SuppressionKey '\(_Supression.RemoveAll)' is not allowed")

        _Supression.remove(key)
    }

    class func removeAllSuppressionKeys() {
        _Supression.remove(_Supression.RemoveAll)
    }

    class func error(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.showsHelp = false
        alert.messageText = message

        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }

    class func information(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.showsHelp = false
        alert.messageText = message

        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }

    class func confirm(_ message: String, suppressionKey: String = "") -> Bool {
        if !suppressionKey.isEmpty, _Supression.object(suppressionKey) != nil {
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.showsHelp = false
        alert.messageText = message
        alert.showsSuppressionButton = !suppressionKey.isEmpty

        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Cancel")

        let result = alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn

        guard result == true else { return false }

        if !suppressionKey.isEmpty,
            let buttonState = alert.suppressionButton?.state,
            buttonState == NSControl.StateValue.on {
            _Supression.set(suppressionKey)
        }

        return true
    }

    class func ask(_ message: String) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.showsHelp = false
        alert.messageText = message

        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }

    enum ConfirmSaveResult: Int {
        case save = 0, cancel = 1, discardChanges = 2
    }

    class func confirmSaveAlert(_ message: String) -> ConfirmSaveResult {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.showsHelp = false
        alert.messageText = message
        alert.informativeText = "Would you like to save?"

        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")

        switch alert.runModal()
        {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            return .save
        case NSApplication.ModalResponse.alertSecondButtonReturn:
            return .cancel
        default:
            return .discardChanges
        }
    }
}
