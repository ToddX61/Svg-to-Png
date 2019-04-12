import Foundation

extension URL {
    var abbreviatingWithTildeInPath: String {
        return isFileURL ? NSString(string: path).abbreviatingWithTildeInPath : path
    }
}
