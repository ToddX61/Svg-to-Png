import Foundation

typealias ExportCommandMacroParams = [ExportCommandMacro: Any]

enum ExportCommandMacro: String, CaseIterable {
    case source, target, width, height, originalWidth, originalHeight

    var description: String { return "@\(self)" }

    static func replacing(_ string: String, params: ExportCommandMacroParams) -> String {
        var result = string

        for macro in ExportCommandMacro.allCases {
            guard let param = params[macro] else { continue }
            result = result.replacingOccurrences(of: macro.description, with: "\(param)")
        }

        return result
    }
}

extension Dictionary where Key == ExportCommandMacro, Value == Any {
    init(_ source: Any? = nil, _ target: Any? = nil, _ width: Any? = nil, _ height: Any? = nil, _ originalWidth: Any? = nil, _ originalHeight: Any? = nil) {
        self.init()
        self[.source] = source
        self[.target] = target
        self[.width] = width
        self[.height] = height
        self[.originalWidth] = originalWidth
        self[.originalHeight] = originalHeight
    }
}
