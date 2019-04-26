
import Foundation

class ExportManager {
    // MARK: - Public Functions

    class func export(atlases: [Atlas], async: Bool = true, completionHander: @escaping (_ ouput: String) -> Void) {
        for atlas in atlases {
            export(atlas: atlas, async: async, completionHander: completionHander)
        }
    }
    
    class func export(atlas: Atlas, async: Bool = true, completionHander: @escaping (_ ouput: String) -> Void) {
        for svgFile in atlas.svgFiles {
            export(atlas: atlas, svgFile: svgFile, async: async, completionHander: completionHander)
        }
    }

    class func export(atlas: Atlas, svgFile: SVGFile, async: Bool = true, completionHander: @escaping (_ ouput: String) -> Void) {
        let exportFiles = ExportFile.create(atlas: atlas, svgFile: svgFile)

        for exportFile in exportFiles {
            guard exportFile.errors.isEmpty else {
                let output = String(describing: exportFile)
                completionHander(output)
                continue
            }

            var output: String?
            var exception: NSException?
            
            if !async {
                let cmd = ExportManager.buildExportCommand(exportFile: exportFile)
                performBash(exportFile: exportFile, output: &output, exception: &exception)
                
                let result = transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)
                
                completionHander(result)
                return
            }

            DispatchQueue.global(qos: .background).async {
                let cmd = ExportManager.buildExportCommand(exportFile: exportFile)
                performBash(exportFile: exportFile, output: &output, exception: &exception)

                DispatchQueue.main.async {
                    let result = transformOutput(exportFile: exportFile, command: cmd, output: output, exception: exception)
                    completionHander(result)
                }
            }
        }
    }
    
    fileprivate class func performBash(exportFile: ExportFile, output: inout String?, exception: inout NSException?) {
        let cmd = ExportManager.buildExportCommand(exportFile: exportFile)
        
        SwiftTryCatch.try(
        {
                output = Bash.execute(commandName: cmd.command, arguments: cmd.arguments) ?? ""
        },
        catch: { error in print(error); exception = error },
        finally: {}
        )
    }
    
    fileprivate class func transformOutput(exportFile: ExportFile, command: ProcessCommand, output: String?, exception: NSException?) -> String {
        guard exception == nil else {
            return (exception?.reason ?? "Unknown Error")
        }
        
        var result = output?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) ?? ""
        
        if result.isEmpty {
            result = "\(command.command): \(exportFile.outputURL!.path.abbreviatingWithTildeInPath)"
        }
        
        return result
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
