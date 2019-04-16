
import Foundation

public func debugLog(_ sequence: Any..., functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    #if DEBUG
        var result = ""

        for (_, element) in sequence.enumerated() {
            result.append("\(element)")
        }

        let className = (fileName as NSString).lastPathComponent
        print("<\(className)> \(functionName) [#\(lineNumber)] \(result)")
    #endif
}
