
import Foundation

struct CLIArguments {
    var options = OptionTypes(minimumCapacity: OptionType.allCases.count)
    var width = 0
    var height = 0
    var exportCommandIdx = -1
    var exportCommand: String = ""
    var resolutions = Resolutions()
    var projects = [String]()
    var filenames = [String]()
}

class CLI {
    //    MARK: - Constants

    static let Version = "1.1.1"
    static let Copyright = "Copyright © 2019 Todd Denlinger. All rights reserved."

    //    MARK: - private properties

    fileprivate var _args = CLIArguments()
    fileprivate var _currentOption: OptionType = .unknown

    //    MARK: - public methods

    var arguments: CLIArguments { return _args }

    //    MARK: - class methods

    class func printUsage(printHelp: Bool = true) {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        Console.write(executableName, " v\(Version)")
        Console.write(Copyright, "\n")

        guard printHelp else { return }
        Console.write("usage: \(executableName) [<svgproject> <svgproject> ...] [options]\n")
        Console.write("<svgproject> <svgproject> ... one or more svg project files\n")
        Console.write("options:")
        for option in OptionType.allCases {
            guard option != .unknown else { continue }
            Console.write("   \(option.flag):\t\(option.optionHelp)")
        }

        let commands = ExportCommandManager.shared.exportCommands.transformed

        Console.write("\navailable export commands:")
        for (idx, command) in commands.enumerated() {
            Console.write("\t\(idx)\t\(command.command)")
        }
    }

    //    MARK: - public methods

    func run() {
        //        following func's return a Bool: whether should continuing processing?
        guard processArguments() else { return }
        guard validateArguments() else { return }
        guard export() else { return }
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
            if argument.hasPrefix("\(option.flag)") {
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
        Console.write("\(optionType.flag): invalid argument '\(argument)'")
    }

    fileprivate func parseArgument(_ argument: String) -> Bool {
        switch _currentOption {
        case .unknown:
            if !argument.isEmpty {
                var arg = argument
                let ext = ".\(ProjectCore.FileType)"

                if !argument.hasSuffix(ext) {
                    arg.append(ext)
                }

                _args.projects.append(arg)
            }
            return true
        case .files:
            _args.options.insert(_currentOption)
            if !argument.isEmpty {
                _args.filenames.append(argument.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            return true
        case .resolutions:
            let splits = argument.split(separator: ",", maxSplits: Int.max, omittingEmptySubsequences: true)
            guard !splits.isEmpty else { return true }

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
        case .size:
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
            guard !argument.isEmpty else { return true }

            if let index = Int(argument) {
                _args.exportCommandIdx = index
                _args.options.insert(_currentOption)
                return true
            }

            logArgumentError(argument)
            return false
        }
    }

    fileprivate func validateArguments() -> Bool {
        if _args.options.count == 1 {
            if _args.options.contains(.version) {
                CLI.printUsage(printHelp: false)
                return false
            }

            if _args.options.contains(.help) {
                CLI.printUsage(printHelp: true)
                return false
            }
        }

        // assume we're exporting for now ... this may change later
        _args.options.insert(.export)

        guard validateExportCommand() else { return false }
        return true
    }

    fileprivate func validateExportCommand() -> Bool {
        if _args.projects.isEmpty {
            CLI.printUsage(printHelp: true)
            Console.write("No project file specified")
            return false
        }

        var commands = ExportCommandManager.shared.exportCommands
        commands.validate(repair: true)
        var idx = _args.exportCommandIdx

        if idx == -1 {
            if let defaultCmd = commands.defaultCommand {
                _args.exportCommand = defaultCmd.obj.command
            } else {
                idx = 0
            }
        }

        if idx >= 0, idx < commands.commands.count {
            _args.exportCommand = commands.commands[idx].obj.command
        }

        if _args.exportCommand.isEmpty {
            Console.write("Invalid \(OptionType.exportCommand.flag). No command found.")
            return false
        }

        return true
    }
}

//  MARK: - exporting

extension CLI {
    //    MARK: - exporting

    fileprivate func export() -> Bool {
        guard _args.options.contains(.export) else { return true }
        let fileManager = FileManager()
        let exportArguments = ExportManager.Arguments(async: false, command: _args.exportCommand)
        let exportManager = ExportManager(exportArguments)

        for atlas in _args.projects {
            let expanded = atlas.expandingTildeInPath

            if !fileManager.fileExists(atPath: expanded) {
                Console.write("Project \(expanded) not found")
                return false
            }

            guard let project = Project(filename: expanded) else {
                Console.write("Unable to open '\(atlas.abbreviatingWithTildeInPath)'")
                return false
            }

            let projectCore = project.obj

            if !_args.options.contains(.files) || _args.filenames.isEmpty {
                let atlases = projectCore.atlases

                if atlases.isEmpty {
                    Console.write("WARNING: Atlas '\(atlas.abbreviatingWithTildeInPath)' is empty")
                    return true
                }

                exportManager.export(atlases: atlases) { message in
                    Console.write(message)
                }

                return true
            }

            guard exportWithFilesArgument(projectCore, manager: exportManager) else { return false }
        }
        return true
    }

    fileprivate func exportWithFilesArgument(_ project: ProjectCore, manager: ExportManager) -> Bool {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var exportCount = 0

        for filename in _args.filenames {
            let expanded: URL

            do {
                guard let work = filename.expandingTildeInPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed), let url = URL(string: work) else {
                    Console.write("WARNING: could not export argument '\(filename)'")
                    continue
                }
                expanded = url
            }

            let prjIdx: Int?
            var svgIdx: Int?

            do {
                let relativeURL = URL(fileURLWithPath: expanded.path, relativeTo: documentURL)

                if let idx = project.indexOf(folder: expanded.path) {
                    prjIdx = idx
                } else if let idx = project.indexOf(folder: relativeURL.path) {
                    prjIdx = idx
                } else if let result = project.firstIndexOf(svgFile: expanded.path) {
                    prjIdx = result.prjIdx
                    svgIdx = result.svgIdx
                } else if let result = project.firstIndexOf(svgFile: relativeURL.path) {
                    prjIdx = result.prjIdx
                    svgIdx = result.svgIdx
                } else {
                    prjIdx = nil
                }
            }

            guard let pIdx = prjIdx else { continue }
            let atlas = project.atlases[pIdx]
            exportCount += 1

            if let sIdx = svgIdx {
                manager.export(atlas: atlas, svgFile: atlas.svgFiles[sIdx]) { message in
                    Console.write(message)
                }

            } else {
                manager.export(atlas: project.atlases[pIdx]) { message in
                    Console.write(message)
                }
            }
        }

        if exportCount == 0 {
            Console.write("Nothing to export")
            return false
        }

        return true
    }
}
