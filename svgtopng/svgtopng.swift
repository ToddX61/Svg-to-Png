
import Foundation

enum OptionType: String, Option {
    case version = "v"
    case help = "h"
    case export = "x"
    case files = "f"
    case overrideWidthHeight = "o"
    case ressoltuions = "r"
    case exportCommand = "xc"
    case unknown

    init(value: String) {
        let _value = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        for option in OptionType.allCases {
            if _value == option.rawValue {
                self = option
                return
            }
        }
        self = .unknown
    }
    }

class svgtopng {
    class func printUsage() {}
}
