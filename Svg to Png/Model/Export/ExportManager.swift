
import Foundation

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

    init(_ arguments: Arguments? = nil) {
        self.arguments = arguments ?? Arguments()
    }

    // MARK: - Public Functions

    func export(atlases: [Atlas], completionHander: @escaping (_ ouput: String) -> Void) {
        for atlas in atlases {
            export(atlas: atlas, completionHander: completionHander)
        }
    }

    func export(atlas: Atlas, completionHander: @escaping (_ ouput: String) -> Void) {
        for svgFile in atlas.svgFiles {
            export(atlas: atlas, svgFile: svgFile, completionHander: completionHander)
        }
    }

    func export(atlas: Atlas, svgFile: SVGFile, completionHander: @escaping (_ ouput: String) -> Void) {
        let exportFiles = ExportFile.create(atlas: atlas, svgFile: svgFile)

        for exportFile in exportFiles {
            guard exportFile.errors.isEmpty else {
                let output = String(describing: exportFile)
                completionHander(output)
                continue
            }

            var output: String?
            var exception: NSException?

            if !arguments.async {
                let cmd = performBash(exportFile: exportFile, output: &output, exception: &exception)
                let result = transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)

                completionHander(result)
                return
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }

                let cmd = self.performBash(exportFile: exportFile, output: &output, exception: &exception)

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    let result = self.transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)

                    completionHander(result)
                }
            }
        }
    }

    // MARK: - private methods
    
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
