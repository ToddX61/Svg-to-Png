
import Foundation

enum Resolution: String, Option {
    case x1, x2, x3

    fileprivate static let _suffix = ["", "@2x", "@3x"]

    var suffix: String {
        switch self
        {
        case .x1:
            return Resolution._suffix[0]
        case .x2:
            return Resolution._suffix[1]
        case .x3:
            return Resolution._suffix[2]
        }
    }

    var multiplier: Int {
        switch self
        {
        case .x1:
            return 1
        case .x2:
            return 2
        case .x3:
            return 3
        }
    }

    func transformURL(url: URL) -> URL {
        let path = url.deletingPathExtension().path.appending(suffix)
        return URL(fileURLWithPath: path).appendingPathExtension("png")
    }
}

extension Set where Element == Resolution {
    static var all: Set<Resolution> {
        return Set(Element.allCases)
    }
}

typealias Resolutions = Set<Resolution>
