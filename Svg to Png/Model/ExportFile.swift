//
//  ExportFile.swift
//  Svg to Png
//
//  Created by Todd Denlinger on 3/8/19.
//  Copyright © 2019 Todd. All rights reserved.
//

import Foundation

struct ExportFile: CustomStringConvertible {
    enum Error: String, Option {
        case invalidInputFolder, invalidInputFile, invalidOutputFolder, invalidWidth, invalidHeight
    }

    var width = 0
    var height = 0
    var inputURL: URL?
    var outputURL: URL?
    var errors = ExportFileErrors()

    var description: String {
        guard !errors.isEmpty else { return "" }
        return "Error exporting \(inputURL?.abbreviatingWithTildeInPath ?? "(Unkown)"):\n\t\(errors.description)"
    }

    static func create(atlas: Atlas, svgFile: SVGFile) -> [ExportFile] {
        var results = [ExportFile]()

        let fileManager = FileManager.default
        let resolutions = Resolutions.create(rawValue: svgFile.resolutions)

        for resolution in resolutions {
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

            if atlas.outputFolder.isEmpty {
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

            exportFile.width = (svgFile.width == 0 ? atlas.defaultWidth : svgFile.width) * resolution.multiplier
            exportFile.height = (svgFile.height == 0 ? atlas.defaultHeight : svgFile.height) * resolution.multiplier

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
