
import Foundation

class ExportManager {
    // MARK: - Public Functions

    class func export(atlases: [Atlas], completionHander: @escaping (_ ouput: String) -> Void) {
        for atlas in atlases {
            for svgFile in atlas.svgFiles {
                export(atlas: atlas, svgFile: svgFile, completionHander: completionHander)
            }
        }
    }

    class func export(atlas: Atlas, svgFile: SVGFile, completionHander: @escaping (_ ouput: String) -> Void) {
        let exportFiles = ExportFile.create(atlas: atlas, svgFile: svgFile)

        for exportFile in exportFiles {
            guard exportFile.errors.isEmpty else {
                let output = String(describing: exportFile)
                completionHander(output)
                continue
            }

            var output: String?
            var exception: NSException?

            DispatchQueue.global(qos: .background).async {
                let cmd = ExportManager.buildExportCommand(exportFile: exportFile)

                SwiftTryCatch.try(
                    {
                        output = Bash.execute(commandName: cmd.command, arguments: cmd.arguments) ?? ""
                    },
                    catch: { error in print(error); exception = error },
                    finally: {}
                )

                DispatchQueue.main.async {
                    guard exception == nil else {
                        completionHander(exception?.reason ?? "Unknown Error")
                        return
                    }

                    var result = output?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) ?? ""

                    if result.isEmpty {
                        result = "\(cmd.command): \(exportFile.outputURL!.path.abbreviatingWithTildeInPath)"
                    }

                    completionHander(result)
                }
            }
        }
    }

    fileprivate class func buildExportCommand(exportFile: ExportFile) -> ProcessCommand {
        precondition(exportFile.errors.isEmpty, "export files must not contain errors")

        let command = ExportCommandManager.shared.exportCommands.defaultCommand
        precondition(command != nil, "No default command in ExportCommands")
        
        let cmd = command!.obj.command
        let macroParams = ExportCommandMacroParams(exportFile.inputURL!.path, exportFile.outputURL!.path, exportFile.width, exportFile.height)
        
        let expanded = ExportCommandMacro.replacing(cmd, params: macroParams)
        return ProcessCommand(commandLine: expanded)
    }
}
