
import Cocoa

class PreferencesController: NSViewController {
    @IBAction func resetDialogButtons(_ sender: NSButton) {
        guard NSAlert.confirm("\(sender.title)?") else { return }
        NSAlert.removeAllSuppressionKeys()
    }
}
