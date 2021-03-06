
import Foundation

extension CGSize {
    var nonsense: Bool { return width <= 0 || height <= 0 }
}

func * (_ size: CGSize, multiplier: Int) -> CGSize {
    let mult = CGFloat(multiplier)
    var result = CGSize(width: size.width, height: size.height)
    result.width *= mult
    result.height *= mult
    return result
}

struct ExportFile: CustomStringConvertible {
    enum Error: String, Option {
        case invalidInputFolder, invalidInputFile, invalidOutputFolder, invalidWidth, invalidHeight
    }

    var width = 0
    var height = 0
    var originalWidth = 0
    var originalHeight = 0
    var inputURL: URL?
    var outputURL: URL?
    var resolutions: Resolutions?
    var errors = ExportFileErrors()

    var size: CGSize {
        get {
            return CGSize(width: width, height: height)
        }
        set {
            width = Int(newValue.width)
            height = Int(newValue.height)
        }
    }

    var originalSize: CGSize {
        get {
            return CGSize(width: originalWidth, height: originalHeight)
        }
        set {
            originalWidth = Int(newValue.width)
            originalHeight = Int(newValue.height)
        }
    }

    var description: String {
        guard !errors.isEmpty else { return "" }
        return "Error exporting \(inputURL?.abbreviatingWithTildeInPath ?? "(Unkown)"):\n\t\(errors.description)"
    }

    static func create(atlas: Atlas,
                       svgFile: SVGFile,
                       size: CGSize? = nil,
                       resolutions: Resolutions? = nil,
                       targetFolder: String? = nil,
                       atlasSizeOverridesSvgSize: Bool = false) -> [ExportFile] {
        var results = [ExportFile]()

        let fileManager = FileManager.default
        let _resolutions: Resolutions

        if let work = resolutions, !work.isEmpty {
            _resolutions = work
        } else {
            _resolutions = Resolutions.create(rawValue: svgFile.resolutions)
        }

        for resolution in _resolutions {
            var exportFile = ExportFile()
            var errors = ExportFileErrors()
            let inputFolder = URL(fileURLWithPath: atlas.folder, isDirectory: true)
            let outputFolder: URL

            exportFile.inputURL = inputFolder.appendingPathComponent(svgFile.filename, isDirectory: false)

            if atlas.folder.isEmpty
                || !fileManager.fileExists(atPath: inputFolder.path) {
                errors.insert(.invalidInputFolder)
            }

            if svgFile.filename.isEmpty {
                errors.insert(.invalidInputFile)
            } else if !fileManager.fileExists(atPath: exportFile.inputURL!.path) {
                errors.insert(.invalidInputFile)
            }
            
            if let target = targetFolder, !target.isEmpty {
                outputFolder = URL(fileURLWithPath: target, isDirectory: false)
                
                if !fileManager.fileExists(atPath: outputFolder.path) {
                    errors.insert(.invalidOutputFolder)
                }
            } else if atlas.outputFolder.isEmpty {
                outputFolder = inputFolder

                if atlas.folder.isEmpty {
                    errors.insert(.invalidOutputFolder)
                }
            } else {
                outputFolder = URL(fileURLWithPath: atlas.outputFolder, isDirectory: false)

                if !fileManager.fileExists(atPath: outputFolder.path) {
                    errors.insert(.invalidOutputFolder)
                }
            }

            exportFile.outputURL = resolution.transformURL(url: outputFolder.appendingPathComponent(svgFile.outputFilename, isDirectory: false))

            let svgSize = CGSize(width: svgFile.width, height: svgFile.height)
            let argSize = size ?? CGSize(width: 0, height: 0)
            let defaultSize = CGSize(width: atlas.defaultWidth, height: atlas.defaultHeight)

            if !argSize.nonsense {
                exportFile.size = argSize * resolution.multiplier
                exportFile.originalSize = argSize
            } else if atlasSizeOverridesSvgSize, !defaultSize.nonsense {
                exportFile.size = defaultSize * resolution.multiplier
                exportFile.originalSize = defaultSize
            } else {
                exportFile.size = svgSize * resolution.multiplier
                exportFile.originalSize = svgSize
            }

            if exportFile.width <= 0 {
                errors.insert(.invalidWidth)
            }

            if exportFile.height <= 0 {
                errors.insert(.invalidHeight)
            }

            exportFile.errors = errors
            results.append(exportFile)
        }

        return results
    }
}

typealias ExportFileErrors = Set<ExportFile.Error>
