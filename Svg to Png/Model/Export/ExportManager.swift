
import Foundation

protocol ExportManagerDelegate {
    func exportAttempted(result: String, exception: NSException?)
    func exportComplete(attempted: Int)
}

class ExportManager {
    struct Arguments {
        var async: Bool
        var size: CGSize?
        var resolutions: Resolutions?
        var command: String
        var preferences: ExportPreferences

        init(async: Bool = true, command: String? = nil, size: CGSize? = nil, resolutions: Resolutions? = nil, preferences: ExportPreferences? = nil) {
            self.async = async
            self.size = size
            self.resolutions = resolutions
            self.preferences = preferences ?? ExportPreferencesManager.shared.preferences

            if let cmd = command, !cmd.isEmpty {
                self.command = command!
            } else {
                let command = ExportCommandManager.shared.exportCommands.defaultCommand
                precondition(command != nil, "No default command in ExportCommands")
                self.command = command!.obj.command
            }
        }
    }

    fileprivate let arguments: Arguments
    fileprivate var filesToExport: [ExportFile] = []
    fileprivate var filesCompleted: Int = 0
    fileprivate let bash: Bash

    init(delegate: ExportManagerDelegate? = nil, arguments: Arguments? = nil) {
        let args = arguments ?? Arguments()
        
        self.delegate = delegate
        self.arguments = args
        self.bash = Bash(addEnvironmentPaths: args.preferences.additionalSearchFolders)
    }

    // MARK: - Public Properties

    var delegate: ExportManagerDelegate?

    // MARK: - Public Functions

    func export(atlases: [Atlas]) {
        prepareToExport()

        for atlas in atlases {
            for svgFile in atlas.svgFiles {
                _ = ExportFile.create(atlas: atlas, svgFile: svgFile, size: arguments.size, resolutions: arguments.resolutions, atlasSizeOverridesSvgSize: arguments.preferences.folderSizeOverridesSvgSize).map { filesToExport.append($0) }
            }
        }

        _export()
    }

    func export(atlas: Atlas) {
        prepareToExport()

        for svgFile in atlas.svgFiles {
            _ = ExportFile.create(atlas: atlas, svgFile: svgFile, size: arguments.size, resolutions: arguments.resolutions, atlasSizeOverridesSvgSize: arguments.preferences.folderSizeOverridesSvgSize).map { filesToExport.append($0) }
        }

        _export()
    }

    func export(atlas: Atlas, svgFile: SVGFile) {
        prepareToExport()
        _ = ExportFile.create(atlas: atlas, svgFile: svgFile, size: arguments.size, resolutions: arguments.resolutions, atlasSizeOverridesSvgSize: arguments.preferences.folderSizeOverridesSvgSize).map { filesToExport.append($0) }
        _export()
    }

    // MARK: - Private Functions

    fileprivate func prepareToExport() {
        filesToExport.removeAll(keepingCapacity: true)
        filesCompleted = 0
    }

    fileprivate func _export() {
        for exportFile in filesToExport {
            guard exportFile.errors.isEmpty else {
                let output = String(describing: exportFile)
                ExportManager.completeExportFile(manager: self, result: output)
                continue
            }

            var output: String?
            var exception: NSException?

            if !arguments.async {
                let cmd = bash(exportFile: exportFile, output: &output, exception: &exception)
                let result = transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)
                ExportManager.completeExportFile(manager: self, result: result, exception: exception)
                continue
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }

                let cmd = self.bash(exportFile: exportFile, output: &output, exception: &exception)

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    let result = self.transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)

                    ExportManager.completeExportFile(manager: self, result: result, exception: exception)
                }
            }
        }
    }

    fileprivate class func completeExportFile(manager: ExportManager?, result: String, exception: NSException? = nil) {
        guard let _manager = manager else { return }
        _manager.delegate?.exportAttempted(result: result, exception: exception)
        _manager.filesCompleted += 1
        if _manager.filesCompleted == _manager.filesToExport.count {
            _manager.delegate?.exportComplete(attempted: _manager.filesCompleted)
        }
    }

    fileprivate func bash(exportFile: ExportFile, output: inout String?, exception: inout NSException?) -> ProcessCommand {
        let cmd = buildExportCommand(exportFile: exportFile)

//        useful for debugging new or modified export commands:
//        debugLog(cmd.description)

        SwiftTryCatch.try(
            {
                output = bash.execute(commandName: cmd.command, arguments: cmd.arguments) ?? ""
            },
            catch: { error in debugLog(error); exception = error },
            finally: {}
        )
        return cmd
    }

    fileprivate func transformOutput(exportFile: ExportFile, command: ProcessCommand, output: String?, exception: NSException?) -> String {
        guard exception == nil else {
            return (exception?.reason ?? "Unknown Error")
        }

        var result = output?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) ?? ""

        if result.isEmpty {
            result = "\(command.command): \(exportFile.outputURL!.path.abbreviatingWithTildeInPath)"
        }

        return result
    }

    fileprivate func buildExportCommand(exportFile: ExportFile) -> ProcessCommand {
        precondition(exportFile.errors.isEmpty, "export files must not contain errors")

        let macroParams = ExportCommandMacroParams(exportFile.inputURL!.path, exportFile.outputURL!.path, exportFile.width, exportFile.height, exportFile.originalWidth, exportFile.originalHeight)

        let expanded = ExportCommandMacro.replacing(arguments.command, params: macroParams)
        return ProcessCommand(commandLine: expanded)
    }
}
