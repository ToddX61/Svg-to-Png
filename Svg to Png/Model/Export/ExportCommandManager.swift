import Foundation

class ExportCommandManager {
    static let ExportCommandKey = "ExportCommand"
    static let shared = ExportCommandManager()

    private var _commands: ExportCommands!
    private let internalQueue = DispatchQueue(label: "ExportCommandManagerQueue", qos: .default, attributes: .concurrent)

    var exportCommands: ExportCommands {
        get {
            return internalQueue.sync { _commands }
        }
        set {
            internalQueue.async(flags: .barrier) { self._commands = newValue }
        }
    }

    private init() {
        if let commands = UserDefaults.standard.object(forKey:ExportCommandManager.ExportCommandKey) as? Data, let jsonData = JSONExportCommands(data: commands) {
                exportCommands = ExportCommands(jsonData.obj.commands)
        } else {
            exportCommands = ExportCommands.predefined
        }
    }
    
    public func resetToDefaults() {
        exportCommands = ExportCommands.predefined
        save()
    }
    
    public func save() {
        UserDefaults.standard.set(JSONExportCommands(object: exportCommands).jsonData, forKey: ExportCommandManager.ExportCommandKey)
    }
}
