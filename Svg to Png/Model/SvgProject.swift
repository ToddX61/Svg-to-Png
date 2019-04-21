
import Cocoa

protocol SvgProjectDelegate {
    func beforeSave()
}

class SvgProject: NSDocument {
    let DocumentTypeName = "SVG Project"

    fileprivate var _atlases = AtlasArray()

    //    MARK: - Public Variables

    var delegate: SvgProjectDelegate?
    var prj: AtlasArray {
        get { return _atlases }
        set { _atlases = newValue }
    }

    var projectExtension: String {
        if let result = fileNameExtension(forType: DocumentTypeName, saveOperation: .saveOperation) {
            return result
        }
        return "(document type '\(DocumentTypeName)' not defined in project settings)"
    }

    //    MARK: - Overrides

    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        addWindowController(windowController)
    }

    override func data(ofType _: String) throws -> Data {
        delegate?.beforeSave()

        var project = Project(object: _Project())
        project.obj.atlases = _atlases.atlases

        if let data = project.jsonData {
            return data
        }

        throw CocoaError(.fileWriteUnknown)
    }

    override func read(from data: Data, ofType _: String) throws {
        guard let project = Project(data: data) else { throw CocoaError(.fileReadUnknown) }

        _atlases.atlases = project.obj.atlases
    }

    //    MARK: - Public Functions

    func loadDummyProject() {
        let path = "/Users/todddenlinger/Documents/"

        for idx in 0 ..< 3 {
            var atlas = Atlas()
            atlas.folder = "\(path)Sprite\(idx + 1).atlas"
            atlas.defaultWidth = 32 * (idx + 1)
            atlas.defaultHeight = 36 * (idx + 1)

            for idx2 in 0 ..< 3 {
                var svgFile = SVGFile()
                svgFile.filename = "File\(idx2 + 1).svg"
                //                svgFile.width = 32 * idx2 + 1
                //                svgFile.height = 36 * idx2 + 1
                atlas.svgFiles.append(svgFile)
            }

            prj.atlases.append(atlas)
        }
    }
}
