
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
    
    var optionHelp: String {
        let value = self.rawValue
        
        switch self {
        case .version:
            return "version number"
        case .help:
            return "this help page"
        case .export:
            return "export svg files in the specified projects"
        case .files:
            return "only export svg files or folders, for instance: -\(value) svgfile1.svg svgfolder\n\t\tThe default is all svg files are processed"
        case .overrideWidthHeight:
            return "override the svg files' width and height: -\(value) 26:32"
        case .ressoltuions:
            return "the resolutions to export: 123 or 13 ... \n\t\tThe default is to use the svg file's resolutions selected in the svg project"
        case .exportCommand:
            return "the index of the export command to use when exporting: -\(value)3\n\t\tdefaults to 0"
        default:
            return "\(OptionType.unknown)"
        }
    }
}

class CLI {
    
    static let Version = "1.1.1"
    static let Copyright = "Copyright © 2019 Todd Denlinger. All rights reserved."
    
    class func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        print(executableName, "v\(Version)")
        print(Copyright)
        
        print("")
        _ = CommandLine.arguments.map {print($0) }
        
        print("")
        print("usage: svgtopng [<svgproject> <svgproject> ...] [options]\n")
        print("<svgproject> <svgproject> ... one or more svg project files\n")
        print("options:")
        for option in OptionType.allCases {
            guard option != .unknown else { continue }
            print("   -\(option.rawValue):\t\(option.optionHelp)")
        }
    }
}
