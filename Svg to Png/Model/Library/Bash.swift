
// modified from 'Bash.swift' at:
// https://gist.github.com/andreacipriani/8c3af3719da31c8fae2cdfa8c21e17ba

import Foundation

struct EnvironmentPaths {
    static let DefaultPaths = "/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
    var paths: [String]
    
    init(additionalPaths: String = "") {
        paths = EnvironmentPaths.toArray(additionalPaths)
        paths.append(contentsOf: EnvironmentPaths.toArray(EnvironmentPaths.getEnvironmentPaths()))
        paths.append(contentsOf: EnvironmentPaths.toArray(EnvironmentPaths.DefaultPaths))
    }
    
    static func toArray(_ paths: String) -> [String] {
        var result: [String] = []
        
        let argPaths = paths.split(separator: ":", maxSplits: Int.max, omittingEmptySubsequences: true)
        _ = argPaths.map { result.append($0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) }
        
        return result
    }
    
    fileprivate static func getEnvironmentPaths() -> String {
        let environment = ProcessInfo.processInfo.environment
        guard let pathString = environment["PATH"] else { return "" }
        return pathString
    }
    
    var combined: String {
        var dictionary = [String : Int]()
        for (idx, path) in paths.enumerated() {
            guard dictionary[path] == nil else { continue }
            dictionary[path] = idx
        }
        
        var result = ""
        let work = dictionary.sorted { $0.1 < $1.1 }
        let lastIdx = work.count - 1
        for (idx,element) in work.enumerated() {
            result += (element.key.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            if idx != lastIdx {
                result += ":"
            }
        }
        return result
    }
    
}

class Bash {
    fileprivate var _paths: EnvironmentPaths = EnvironmentPaths()
    
    init(addEnvironmentPaths: [String]? = ["/usr/local/bin"]) {
        guard let epaths = addEnvironmentPaths else { return }
        _paths.paths.append(contentsOf: epaths)
    }
    
    convenience init(addEnvironmentPaths: String) {
        self.init(addEnvironmentPaths: EnvironmentPaths.toArray(addEnvironmentPaths))
    }
    
    // MARK: - Public Methods
    
    func execute(commandName: String, arguments: [String]) -> String? {
        guard var bashCommand = _execute(command: "/bin/bash", arguments: ["-l", "-c", "which \(commandName)"]) else { return "'\(commandName)' not found" }
        guard !bashCommand.isEmpty else { return "'\(commandName)' not found" }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return _execute(command: bashCommand, arguments: arguments)
    }

    // MARK: Private

    // process.lanuch() will throw an NSException on invalid command
    fileprivate func _execute(command: String, arguments: [String] = []) -> String? {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments

        let pipe = Pipe()
        
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = _paths.combined
        process.environment = environment

        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return output
    }
}
