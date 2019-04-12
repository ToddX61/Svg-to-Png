
import Foundation

extension String {
    func split(commandLine: String) -> [String] {
        let command = commandLine.reducingWhiteSpace
        guard !command.isEmpty else { return [] }

        var result: [String] = []
        var startQuote = false
        var work: String = ""

        for character in command {
            if character == "\"" {
                if startQuote {
                    startQuote = false
                    result.append(work)
                    work = ""
                } else {
                    startQuote = true
                }
                continue
            }

            if startQuote {
                work.append(character)
                continue
            }

            if " \t\n".contains(character) {
                if !work.isEmpty {
                    result.append(work)
                    work = ""
                }
            } else {
                work.append(character)
            }
        }

        if !work.isEmpty {
            result.append(work)
        }

        return result
    }
}

//must remove the quotes surroung arguments!

struct ProcessCommand: CustomStringConvertible {
    fileprivate var _arguments: [String]?
    var command: String
    
    var arguments: [String] {
        get { return _arguments ?? [String]() }
        set { _arguments = newValue.isEmpty ? nil : newValue }
    }
    
    var description: String {
        var result = "\(command)"
        _ = arguments.map( { result.append( " \($0)") } )
        return result
    }

    init() {
        command = ""
    }

    init(_ command: String, arguments: [String]? = nil) {
        self.command = command
        self._arguments = arguments
    }

    init(commandLine: String) {
        let array = commandLine.split(commandLine: commandLine)
        guard array.count != 0 else { command = ""; return }
        
        command = array[0]
        _arguments = Array(array.dropFirst())
    }
}
