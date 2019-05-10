
import Cocoa

class PreferencesController: NSViewController {
    
    @IBOutlet var searchPathsTextField: NSTextField!
    @IBOutlet var sizeOverridesButton: NSButton!
    
    fileprivate var hasChanges = false
    fileprivate var preferences: ExportPreferences!
    
    // MARK: - IBActions
    @IBAction func sizeOverridesClicked(_ sender: Any) {
        preferences.folderSizeOverridesSvgSize = (sizeOverridesButton.state == .on)
        hasChanges = true
    }
    
    @IBAction func searchPathsChanged(_ sender: Any) {
        preferences.additionalSearchFolders = searchPathsTextField.stringValue
        hasChanges = true
    }
    
    @IBAction func resetDialogButtons(_ sender: NSButton) {
        guard NSAlert.confirm("\(sender.title)?") else { return }
        NSAlert.removeAllSuppressionKeys()
    }

    @IBAction func exportCommansButton(_ sender: Any) {
        guard let app = NSApplication.shared.delegate as? AppDelegate else { return }
        app.exportCommands(self)
    }
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
    }

    override func viewWillAppear() {
        view.window?.delegate = self
    }

    // MARK: - Private Methods

    private func save() {
        guard hasChanges else { return }
        let manager = ExportPreferencesManager.shared
        manager.preferences = preferences
        manager.save()
        hasChanges = false
    }
    
    private func reload() {
        preferences = ExportPreferencesManager.shared.preferences
        updateUI()
    }
    
    private func updateUI() {
        sizeOverridesButton.state = preferences.folderSizeOverridesSvgSize ? .on : .off
        searchPathsTextField.stringValue = preferences.additionalSearchFolders
        searchPathsTextField.selectText(searchPathsTextField)
    }
}

// MARK: - NSWindowDelegate

extension PreferencesController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        save()
    }

    func windowDidResignKey(_: Notification) {
        save()
    }
}
