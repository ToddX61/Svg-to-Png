
// slightly modified from 'Bash.swift' at:
// https://gist.github.com/andreacipriani/8c3af3719da31c8fae2cdfa8c21e17ba

import Foundation

class Bash {
    // MARK: - CommandExecuting

    class func execute(commandName: String) -> String? {
        return execute(commandName: commandName, arguments: [])
    }

    class func execute(commandName: String, arguments: [String]) -> String? {
        guard var bashCommand = execute(command: "/bin/bash", arguments: ["-l", "-c", "which \(commandName)"]) else { return "\(commandName) not found" }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return execute(command: bashCommand, arguments: arguments)
    }

    // MARK: Private

    // process.lanuch() will throw an NSException on invalid command
    private class func execute(command: String, arguments: [String] = []) -> String? {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return output
    }
}
