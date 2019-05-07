
import Foundation

struct ExportPreferences: Codable {
    var folderSizeOverridesSvgSize: Bool = false
    var additionalSearchFolders: String = ""
}

extension ExportPreferences: Equatable {
    static func == (lhs: ExportPreferences, rhs: ExportPreferences) -> Bool {
        return lhs.folderSizeOverridesSvgSize == rhs.folderSizeOverridesSvgSize
            && lhs.additionalSearchFolders == rhs.additionalSearchFolders
    }
}

typealias JSONExportPreferences = JSONRepresentable<ExportPreferences>

class ExportPreferencesManager {
    static let ExportPreferencesKey = "ExportPreferences"
    static let preferences = ExportPreferences()
    
    private var _preferences: ExportPreferences!
    private let internalQueue = DispatchQueue(label: "ExportPreferencerQueue", qos: .default, attributes: .concurrent)
    
    var preferences: ExportPreferences {
        get {
            return internalQueue.sync { _preferences }
        }
        set {
            internalQueue.async(flags: .barrier) { self._preferences = newValue }
        }
    }
    
    private init() {
        if let exportPreferences = AppSuite.userDefaults().object(forKey:ExportPreferencesManager.ExportPreferencesKey) as? Data,
            let jsonData = JSONExportPreferences(data: exportPreferences) {
                preferences = jsonData.obj
        } else {
            preferences = ExportPreferences()
        }
    }
}
