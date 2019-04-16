
import Foundation

struct _Project: Codable {
    var atlases: [Atlas]

    init() {
        atlases = [Atlas]()
    }

    func indexOf(folder: String) -> Int {
        let findUrl = URL(fileURLWithPath: folder, isDirectory: true)
        if let idx = atlases.firstIndex(where: { URL(fileURLWithPath: $0.folder, isDirectory: true).path == findUrl.path }) {
            return idx
        }

        return -1
    }
}

typealias Project = JSONRepresentable<_Project>

struct Atlas: Codable {
    var folder: String
    var outputFolder: String = ""
    var defaultWidth = 0
    var defaultHeight = 0
    var exapnded = false
    var svgFiles: [SVGFile]
}

struct SVGFile: Codable {
    static let FileExtension = "svg"
    static let OuputExtension = "png"

    var filename: String
    var outputExtension: String = ".\(SVGFile.OuputExtension)"
    var width, height: Int
    var resolutions: Int

    var outputFilename: String {
        let result = filename.replacingOccurrences(of: ".\(SVGFile.FileExtension)", with: outputExtension)

        assert(filename.lowercased() != result.lowercased())
        return result
    }
}

extension Atlas {
    init() {
        folder = ""
        svgFiles = [SVGFile]()
    }

    init(filepath: String) {
        self.init()
        folder = filepath
    }

    func indexOf(svgFilename: String) -> Int {
        if let idx = svgFiles.firstIndex(where: { $0.filename == svgFilename }) {
            return idx
        }

        return -1
    }
}

extension SVGFile {
    init() {
        filename = ""
        width = 0
        height = 0
        resolutions = Resolutions.all.rawValue
    }

    init(filename: String) {
        self.init()
        self.filename = filename
    }

    init?(data: Data) {
        guard let me = try? JSONDecoder().decode(SVGFile.self, from: data) else { return nil }
        self = me
    }

    init?(_ json: String, using encoding: String.Encoding = .utf8) {
        guard let data = json.data(using: encoding) else { return nil }
        self.init(data: data)
    }

    init?(fromURL url: String) {
        guard let url = URL(string: url) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(data: data)
    }

    var jsonData: Data? {
        return try? JSONEncoder().encode(self)
    }

    var json: String? {
        guard let data = self.jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var supportedResolutions: Resolutions {
        return Resolutions.create(rawValue: resolutions)
    }

    mutating func setResolutions(supported: Resolutions) {
        resolutions = supported.rawValue
    }

    func create(from: Resolution) -> SVGFile {
        var result = SVGFile()

        let url = URL(fileURLWithPath: filename)

        result.filename = "\(url.deletingPathExtension().lastPathComponent)\(from.suffix)\(outputExtension)"

        let multiplier: Int
        switch from
        {
        case .x1:
            multiplier = 1
        case .x2:
            multiplier = 2
        case .x3:
            multiplier = 3
        }

        result.outputExtension = outputExtension
        result.width = width * multiplier
        result.height = height * multiplier
        result.resolutions = Resolutions([from]).rawValue
        return result
    }
}
