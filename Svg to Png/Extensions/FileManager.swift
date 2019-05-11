
import Foundation

extension FileManager {
    func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = ObjCBool(false)
        if fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue
        } else {
            return false
        }
    }
}
