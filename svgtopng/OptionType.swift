
import Foundation

enum OptionType: String, Option {
    case version = "v"
    case help = "h"
    case export = "x"
    case files = "f"
    case size = "s"
    case resolutions = "r"
    case exportCommand = "c"
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
    
    var flag: String { return "-\(rawValue)" }
    
    var optionHelp: String {
        switch self {
        case .version:
            return "version number"
        case .help:
            return "this help page"
        case .export:
            return "export svg files in the specified projects"
        case .files:
            return "only export svg specified files or folders, for instance: \(flag) svgfile1.svg svgfolder ...\n\t\tThe default: all svg files are processed"
        case .size:
            return "override the svg files' width and height: \(flag) 26:32"
        case .resolutions:
            return "resolutions to export: \(flag) '1,2,3' '2,3', '1' etc... \n\t\tThe default is to use the svg file's resolutions selected in the svg project"
        case .exportCommand:
            return "the index of the export command to use when exporting: \(flag)3\n\t\tdefaults to the default defined in 'Svg to Png'"
        default:
            return "\(OptionType.unknown)"
        }
    }
}

typealias OptionTypes = Set<OptionType>
