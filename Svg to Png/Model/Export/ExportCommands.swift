
import Foundation

enum ExportCommandOption: String, Option, Encodable, Decodable {
    case isDefault, predfined
}

extension Set where Element == ExportCommandOption {
    static var all: Set<ExportCommandOption> {
        return Set(Element.allCases)
    }
}

typealias ExportCommandOptions = Set<ExportCommandOption>

struct _ExportCommand: Codable {
    fileprivate var _command: String
    fileprivate var _options: ExportCommandOptions

    var command: String {
        get { return _command }
        set {
            _command = newValue.reducingWhiteSpace
        }
    }

    var options: ExportCommandOptions { return _options }

    init() {
        _command = ""
        _options = ExportCommandOptions()
    }

    init(_ command: String, isDefault: Bool = false) {
        let newCommand = command.reducingWhiteSpace

        _command = newCommand
        _options = ExportCommandOptions()

        if isDefault {
            _options.insert(.isDefault)
        }
    }
}

extension _ExportCommand: Equatable {
    static func == (lhs: _ExportCommand, rhs: _ExportCommand) -> Bool {
        return lhs._command == rhs._command
    }
}

typealias ExportCommand = JSONRepresentable<_ExportCommand>

struct ExportCommands: Codable {
    fileprivate var _commands: [ExportCommand]

    init(_ commands: [ExportCommand] = [ExportCommand]()) {
        _commands = commands
    }

    var commands: [ExportCommand] {
        get { return _commands }
        set { _commands = newValue }
    }
    
    var transformed: [_ExportCommand] {
        var result = [_ExportCommand]()
        for idx in 0 ..< _commands.count {
            result.append(_commands[idx].obj)
        }
        return result
    }

    var defaultCommand: ExportCommand? {
        return _commands.first { $0.obj.options.contains(.isDefault) }
    }

    // calling setDefault(at: -1) will clear all defaults
    mutating func setDefault(at: Int) {
        for idx in 0 ..< _commands.count {
            if idx == at {
                _commands[idx].obj._options.insert(.isDefault)

            } else {
                _commands[idx].obj._options.remove(.isDefault)
            }
        }
    }

    @discardableResult mutating func validate(repair: Bool = false) -> Bool {
        var inValidCommands: [Int] = []
        var hasDefault = false

        for (idx, cmd) in _commands.enumerated() {
            if cmd.obj._command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inValidCommands.append(idx)
            } else if cmd.obj.options.contains(.isDefault) {
                hasDefault = true
            }
        }

        if repair {
            for idx in inValidCommands.reversed() {
                _commands.remove(at: idx)
            }
            if !hasDefault {
                setDefault(at: 0)
            }
        }

        return !inValidCommands.isEmpty && !hasDefault
    }

    @discardableResult mutating func insert(command: ExportCommand) -> Bool {
        if let _ = _commands.first(where: { $0.obj.command == command.obj.command }) {
            return false
        }

        var newCommand = command
        newCommand.obj._options.remove(.predfined)

        _commands.append(command)

        if command.obj._options.contains(.isDefault) {
            let lastIdx = _commands.count - 1
            setDefault(at: lastIdx)
        }

        return true
    }

    @discardableResult mutating func remove(at: Int) -> ExportCommand? {
        precondition(at >= 0 && at <= _commands.count)
        guard !_commands[at].obj._options.contains(.predfined) else { return nil }
        return _commands.remove(at: at)
    }

    static var predefined: ExportCommands {
        let _predefined = [
            "rsvg-convert -w @width -h @height \"@source\" -o \"@target\"",
            "svgexport \"@source\" \"@target\" 100% @originalWidth:@originalHeight @width:@height",
            "magick convert -background none -size @widthx@height \"@source\" -alpha background \"@target\"",
            "inkscape \"@source\" --export-png=\"@target\" -w@width -h@height -z"
        ]

        var commands = ExportCommands()
        for string in _predefined {
            var command = ExportCommand(object: _ExportCommand(string))
            command.obj._options.insert(.predfined)
            if commands._commands.isEmpty {
                command.obj._options.insert(.isDefault)
            }
            commands.insert(command: command)
        }
        return commands
    }
}

typealias JSONExportCommands = JSONRepresentable<ExportCommands>
