
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject {
    fileprivate var _preferences: NSWindow?
    fileprivate var _exportCommands: NSWindow?
    
    @IBAction func exportCommands(_ sender: Any) {
        if _exportCommands == nil {
            _exportCommands = NSWindow(contentViewController: CommandController())
        }
        
        let exportCommands = _exportCommands!
        exportCommands.title = "Export Commands"
        exportCommands.styleMask.remove(.resizable)
        exportCommands.makeKeyAndOrderFront(self)
    }
    
    @IBAction func preferences(_: Any) {
        if _preferences == nil {
            _preferences = NSWindow(contentViewController: PreferencesController())
        }

        let preferences = _preferences!
        preferences.title = "Preferences"
        preferences.styleMask.remove(.resizable)
        preferences.makeKeyAndOrderFront(self)
    }
}

// MARK: - NSApplicationDelegate

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_: Notification) {
        _preferences?.close()
        _preferences = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return false
    }

    func applicationShouldOpenUntitledFile(_: NSApplication) -> Bool {
        let controller = NSDocumentController.shared
        let projects = controller.recentDocumentURLs

        if !projects.isEmpty {
            controller.openDocument(withContentsOf: projects[0], display: true) { [weak self] in
                _ = $0
                _ = $1
                guard let error = $2 else { return }

                controller.newDocument(self)
                NSAlert.error("Error opening \(projects[0].path)\(error)")
            }

            return false
        }

        return true
    }
}
