
import Foundation

enum OptionType: String, Option {
    case version = "v"
    case help = "h"
    case export = "x"
    case files = "f"
    case overrideWidthHeight = "o"
    case resolutions = "r"
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

    var asOption: String { return "-\(rawValue)" }

    var optionHelp: String {
        switch self {
        case .version:
            return "version number"
        case .help:
            return "this help page"
        case .export:
            return "export svg files in the specified projects"
        case .files:
            return "only export svg specified files or folders, for instance: \(asOption) svgfile1.svg svgfolder ...\n\t\tThe default is all svg files are processed"
        case .overrideWidthHeight:
            return "override the svg files' width and height: \(asOption) 26:32"
        case .resolutions:
            return "resolutions to export: \(asOption) '1,2,3' ' 2,3, '1' etc... \n\t\tThe default is to use the svg file's resolutions selected in the svg project"
        case .exportCommand:
            return "the index of the export command to use when exporting: \(asOption)3\n\t\tdefaults to 0"
        default:
            return "\(OptionType.unknown)"
        }
    }
}

typealias OptionTypes = Set<OptionType>

struct CLIArguments {
    var options = OptionTypes(minimumCapacity: OptionType.allCases.count)
    var width = 0
    var height = 0
    var exportCommandIdx = -1
    var resolutions = Resolutions()
    var projects = [String]()
    var files = [String]()
}

class CLI {
    //    MARK: - Constants

    static let Version = "1.1.1"
    static let Copyright = "Copyright © 2019 Todd Denlinger. All rights reserved."

    //    MARK: - private variables

    fileprivate var _args = CLIArguments()
    fileprivate var _currentOption: OptionType = .unknown

    //    MARK: - class methods

    class func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        Console.write(executableName, "v\(Version)")
        Console.write(Copyright, "\n")
        Console.write("usage: svgtopng [<svgproject> <svgproject> ...] [options]\n")
        Console.write("<svgproject> <svgproject> ... one or more svg project files\n")
        Console.write("options:")
        for option in OptionType.allCases {
            guard option != .unknown else { continue }
            Console.write("   \(option.asOption):\t\(option.optionHelp)")
        }
    }

    //    MARK: - public methods

    func run() {
        guard processArguments() else { return }
    }

    //    MARK: - private methods

    fileprivate func processArguments() -> Bool {
        if CommandLine.argc == 1 {
            CLI.printUsage()
            return false
        }

        for (idx, argument) in CommandLine.arguments.enumerated() {
            guard idx > 0 else { continue }
            guard processArgument(argument) else { return false }
        }

        return true
    }

    fileprivate func processArgument(_ argument: String) -> Bool {
        var offset = 0

        for option in OptionType.allCases {
            if argument.hasPrefix("\(option.asOption)") {
                _currentOption = option
                offset = 2
                break
            }
        }

        if offset == 0, let char = argument.first, char == "-" {
            Console.write("Invalid argument '\(argument)'")
            return false
        }

        return parseArgument(String(argument.dropFirst(offset)))
    }
    
    fileprivate func logArgumentError(_ argument: String, option: OptionType? = nil) {
        let optionType = option ?? _currentOption
        Console.write("\(optionType.asOption): invalid argument '\(argument)'")
    }

    fileprivate func parseArgument(_ argument: String) -> Bool {
        switch _currentOption {
        case .unknown:
            if !argument.isEmpty {
                _args.projects.append(argument)
            }
            return true
        case .files:
            _args.options.insert(_currentOption)
            if !argument.isEmpty {
                _args.projects.append(argument)
            }
            return true
        case .resolutions:
            let splits = argument.split(separator: ",", maxSplits: Int.max, omittingEmptySubsequences: true)
            guard splits.count != 0 else { return true }

            for s in splits {
                if let value = Int(s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)), let resolution = Resolution(value: value) {
                    _args.resolutions.insert(resolution)
                    continue
                }
                logArgumentError(argument)
                return false
            }
            
            _args.options.insert(_currentOption)
            return true
        case .overrideWidthHeight:
            let splits = argument.split(separator: ":", maxSplits: Int.max, omittingEmptySubsequences: true)
            let count = splits.count
            if count == 0 {
                return true
            }

            if count == 2,
                let width = Int(splits[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)),
                let height = Int(splits[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                _args.width = width
                _args.height = height
                _args.options.insert(_currentOption)
                return true
            }

            logArgumentError(argument)
            return false
        case .help:
            fallthrough
        case .version:
            fallthrough
        case .export:
            if argument.isEmpty {
                _args.options.insert(_currentOption)
                return true
            } else {
                logArgumentError(argument)
                return false
            }
        case .exportCommand:
            guard argument.isEmpty == false else { return true }
            
            if let index = Int(argument) {
                _args.exportCommandIdx = index
                _args.options.insert(_currentOption)
                return true
            }
        
            logArgumentError(argument)
            return false
        }
    }
}
