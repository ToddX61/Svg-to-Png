
import Cocoa

// MARK: - Supports Dark Mode in OSX 10.14 Mojave

extension NSTextView {
    static let DefaultAttribute =
        [NSAttributedString.Key.foregroundColor: NSColor.textColor] as [NSAttributedString.Key: Any]

    var stringValue: String {
        return textStorage?.string ?? ""
    }

    func setString(_ string: String) {
        textStorage?.mutableString.setString("")
        append(string)
    }

    func append(_ string: String) {
        let attributedText = NSAttributedString(string: string, attributes: NSTextView.DefaultAttribute)

        textStorage?.append(attributedText)
    }
}
