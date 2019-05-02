
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

        init(async: Bool = true, command: String? = nil, size: CGSize? = nil, resolutions: Resolutions? = nil) {
            self.async = async
            self.size = size
            self.resolutions = resolutions

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

    init(delegate: ExportManagerDelegate? = nil, arguments: Arguments? = nil) {
        self.delegate = delegate
        self.arguments = arguments ?? Arguments()
    }

    // MARK: - Public Properties
    
    var delegate: ExportManagerDelegate?
    
    // MARK: - Public Functions

    func export(atlases: [Atlas]) {
        prepareToExport()

        for atlas in atlases {
            for svgFile in atlas.svgFiles {
                _ = ExportFile.create(atlas: atlas, svgFile: svgFile).map { filesToExport.append($0) }
            }
        }

        _export()
    }

    func export(atlas: Atlas) {
        prepareToExport()
        
        for svgFile in atlas.svgFiles {
            _ = ExportFile.create(atlas: atlas, svgFile: svgFile).map { filesToExport.append($0) }
        }
        
        _export()
    }

    func export(atlas: Atlas, svgFile: SVGFile) {
        prepareToExport()
        
        _ = ExportFile.create(atlas: atlas, svgFile: svgFile).map { filesToExport.append($0) }
        
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
                let cmd = performBash(exportFile: exportFile, output: &output, exception: &exception)
                let result = transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)
                ExportManager.completeExportFile(manager: self, result: result, exception: exception)
                return
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }

                let cmd = self.performBash(exportFile: exportFile, output: &output, exception: &exception)

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
    
    fileprivate func performBash(exportFile: ExportFile, output: inout String?, exception: inout NSException?) -> ProcessCommand {
        let cmd = buildExportCommand(exportFile: exportFile)
        debugLog(cmd.description)
        SwiftTryCatch.try(
            {
                output = Bash.execute(commandName: cmd.command, arguments: cmd.arguments) ?? ""
            },
            catch: { error in print(error); exception = error },
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
