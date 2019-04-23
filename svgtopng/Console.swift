
import Foundation

enum OutputType {
    case error
    case standard
}

class Console {
    class func write(_ sequence: Any..., to: OutputType = .standard) {
        var msg = ""
        _ = sequence.map { msg.append("\($0)") }

        switch to {
        case .standard:
            print(msg)
        case .error:
            fputs("Error: \(msg)\n", stderr)
        }
    }    
}
