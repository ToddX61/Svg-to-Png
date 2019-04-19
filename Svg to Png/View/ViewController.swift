
import Cocoa

// structs should conform to Hashable to work correctly in NSOutlineView
fileprivate struct _Indices: Hashable {
    static let None = -1
    static let Empty = _Indices(atlas: _Indices.None)

    let atlas: Int
    let svg: Int

    init(atlas: Int, svg: Int = _Indices.None) {
        self.atlas = atlas
        self.svg = svg
    }
}

class ViewController: NSViewController {
    @IBOutlet var outputView: NSTextView!
    @IBOutlet var outputScrollView: NSScrollView!
    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var filenameTextField: NSTextField!
    @IBOutlet var pathControl: PathControl!
    @IBOutlet var pathStack: NSStackView!

    @IBOutlet var propertiesBox: NSBox!
    @IBOutlet var resolutionsGroup: NSStackView!
    @IBOutlet var widthTextField: NSTextField!
    @IBOutlet var heightTextField: NSTextField!
    @IBOutlet var x1Button: NSButton!
    @IBOutlet var x2Button: NSButton!
    @IBOutlet var x3Button: NSButton!

    //    Calling before viewDidAppear (in viewDidLoad for example) throws error
    fileprivate var document: SvgProject {
        assert(view.window?.windowController?.document as? SvgProject != nil)
        return view.window?.windowController?.document as! SvgProject
    }

    //    Calling before viewDidAppear (in viewDidLoad for example) throws error
    fileprivate var prj: AtlasArray {
        return document.prj
    }

    //    MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        propertiesBox.isHidden = true
        pathStack.isHidden = true

        // setting hasHorizontalScroller in XCode's Interface Builder
        // causes XCode 10.1 to crash
        outputScrollView.hasHorizontalScroller = true
        // turn off word wrap. In interface builder, set the TextView max width and height to large numbers
        outputView.textContainer!.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        outputView.textContainer!.widthTracksTextView = false
        outputView.isHorizontallyResizable = true
    }

    override func viewWillAppear() {
        document.delegate = self
        outlineView.dataSource = self
        outlineView.delegate = self
        pathControl.pathControlDelegate = self

        for idx in 0 ..< prj.atlases.count {
            outlineView.expandItem(_Indices(atlas: idx))
        }
    }
    
    override func viewDidAppear() {
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
    }

    override func keyDown(with theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }

    override func deleteBackward(_: Any?) {
        let selectedRow = outlineView.selectedRow
        guard selectedRow != -1 else { return }
        guard let selected = outlineView.item(atRow: selectedRow) as? _Indices else { return }
        var atlases = prj.atlases

        if selected.svg == _Indices.None {
            let atlas = prj.atlases[selected.atlas]
            let abbreviated = URL(fileURLWithPath: atlas.folder, isDirectory: true).abbreviatingWithTildeInPath

            guard NSAlert.confirm("Remove atlas '\(abbreviated)' from project?", suppressionKey: SuppressionKey.RemoveFolder) else { return }

            let svgCount = atlas.svgFiles.count
            if svgCount != 0 {
                let msg = "Folder '\(abbreviated)' contains \(svgCount) file\(svgCount == 1 ? "" : "s")\n\nRemove from project?"
                guard NSAlert.confirm(msg) else { return }
            }

            atlases.remove(at: selected.atlas)
            outputView.append("Removing folder from project: '\(abbreviated)'\n")
        } else {
            let atlas = prj.atlases[selected.atlas]
            let svgFile = atlas.svgFiles[selected.svg]
            let abbreviated = URL(fileURLWithPath: atlas.folder, isDirectory: true).appendingPathComponent(svgFile.filename, isDirectory: false).abbreviatingWithTildeInPath

            guard NSAlert.confirm("Remove svg file '\(abbreviated)' from project?", suppressionKey: SuppressionKey.RemoveFolder) else { return }

            atlases[selected.atlas].svgFiles.remove(at: selected.svg)
            outputView.append("Removing file '\(abbreviated)' from project: '\(abbreviated)'\n")
        }

        setAtlases(atlases)

        if !atlases.isEmpty {
            let newSelectedRow = selectedRow == 0 ? selectedRow : selectedRow - 1
            outlineView.selectRow(newSelectedRow)
        }
    }

    //    MARK: - Private Functions

    fileprivate func selection() -> _Indices {
        guard let selected = outlineView.item(atRow: outlineView.selectedRow) as? _Indices else { return _Indices.Empty }
        return selected
    }

    //    if no atlas is selected,  the last atlas in the project (if one exists) is returned in Indicies
    //    if no svg is selected, the last svg in the selected atlas (if one exists) is returned
    fileprivate func selectionImplicit() -> _Indices {
        let atlasCount = prj.atlases.count

        guard atlasCount != 0 else { return _Indices.Empty }

        var atlasIdx: Int // = Indices.None
        var svgIdx: Int // = Indices.None
        let rowIdx = outlineView.selectedRow

        if rowIdx == -1 {
            atlasIdx = atlasCount - 1
            svgIdx = prj.atlases[atlasIdx].svgFiles.count - 1
            return _Indices(atlas: atlasIdx, svg: svgIdx)
        }

        guard let selected = outlineView.item(atRow: rowIdx) as? _Indices else {
            return _Indices.Empty
        }

        atlasIdx = selected.atlas
        if selected.svg == _Indices.None {
            svgIdx = prj.atlases[atlasIdx].svgFiles.count - 1
        } else {
            svgIdx = selected.svg
        }

        return _Indices(atlas: atlasIdx, svg: svgIdx)
    }

    // returns the index where a new atlas should be inserted into the outline based on the selected row in the outline
    fileprivate func addAtlasIndex() -> Int {
        let rowIdx = outlineView.selectedRow
        guard rowIdx != -1 else { return outlineView.numberOfChildren(ofItem: nil) }
        guard let indices = outlineView.item(atRow: rowIdx) as? _Indices else { return 0 }
        return indices.atlas + 1
    }

    fileprivate func reload() {
        outlineView.beginUpdates()
        reload { _ = $0 }
        outlineView.endUpdates()
    }

    fileprivate func reload(beforeReload: (_ expanded: inout [Bool]) -> Void) {
        var expanded = [Bool]()

        for idx in 0 ..< prj.atlases.count {
            let indices = _Indices(atlas: idx)
            let isExpanded = outlineView.isItemExpanded(indices)
            expanded.append(isExpanded)
        }

        beforeReload(&expanded)
        outlineView.reloadData()

        for idx in 0 ..< prj.atlases.count {
            if expanded[idx] {
                outlineView.expandItem(_Indices(atlas: idx))
            } else {
                outlineView.collapseItem(_Indices(atlas: idx))
            }
        }
    }

    @discardableResult fileprivate func updateResolutions(svgFile: SVGFile) -> Bool {
        var rawValue = 0
        var changed = false

        if x1Button.state == .on {
            rawValue |= Resolutions([.x1]).rawValue
        }
        if x2Button.state == .on {
            rawValue |= Resolutions([.x2]).rawValue
        }
        if x3Button.state == .on {
            rawValue |= Resolutions([.x3]).rawValue
        }

        if rawValue != svgFile.resolutions {
            let rowIdx = outlineView.selectedRow
            let item = outlineView.item(atRow: rowIdx)
            guard let indices = item as? _Indices else { return false }

            prj.atlases[indices.atlas].svgFiles[indices.svg].resolutions = rawValue
            document.updateChangeCount(.changeDone)
            changed = true
        }

        return changed
    }

    fileprivate func resetPathControls(atlas: Atlas) {
        // this does nothing if app is running in a sandbox
        filenameTextField.stringValue = URL(fileURLWithPath: atlas.folder, isDirectory: true).abbreviatingWithTildeInPath
        pathControl.url = atlas.outputFolder.isEmpty ? nil : URL(fileURLWithPath: atlas.outputFolder, isDirectory: true)
    }

    fileprivate func resetSizeTextFields(textField: NSTextField, svgValue: Int, atlasValue: Int) {
        if atlasValue == 0 {
            textField.placeholderString = "(in pixels)"
        } else {
            textField.placeholderString = "\(atlasValue) (inherited)"
        }

        if svgValue == 0 {
            textField.stringValue = ""
        } else {
            textField.integerValue = svgValue
        }
    }

    fileprivate func sortAll() {
        var atlases = prj.atlases
        for idx in 0 ..< atlases.count {
            atlases[idx].svgFiles.sort(by: { $0.filename < $1.filename })
        }

        atlases.sort(by: { $0.folder < $1.folder })
        setAtlases(atlases)
    }

    fileprivate func sortFolder() {
        let indices = selection()

        if indices.atlas != _Indices.None,
            !prj.atlases[indices.atlas].svgFiles.isEmpty {
            var atlases = prj.atlases
            atlases[indices.atlas].svgFiles.sort(by: { $0.filename < $1.filename })

            setAtlases(atlases)

            outlineView.selectRow(indices.atlas)
            outlineView.expandItem(_Indices(atlas: indices.atlas))
        }
    }

    fileprivate struct AddFileResult {
        var indices: _Indices = _Indices(atlas: _Indices.None)
        var atlasAdded: Bool = false
        var svgAdded: Bool = false
        var output = ""
    }

    fileprivate func addSVGFile(_ atlases: inout [Atlas], url: URL, selected: _Indices) -> AddFileResult {
        let folder = url.deletingLastPathComponent()
        let filename = url.lastPathComponent
        let atlasAdded: Bool
        let svgAdded: Bool
        let abbreviatedFolder = folder.abbreviatingWithTildeInPath
        var svgIdx: Int
        var output = ""
        var atlasIdx = AtlasArray(atlases: atlases).indexOf(folder: folder.path)

        if atlasIdx == -1 {
            output.append("Adding folder: \(abbreviatedFolder)\n")
            atlasIdx = selected.atlas + 1
            atlases.insert(Atlas(filepath: folder.path), at: atlasIdx)
            atlasAdded = true
        } else {
            atlasAdded = false
        }

        svgIdx = atlases[atlasIdx].indexOf(svgFilename: filename)

        if svgIdx != -1 {
            output.append("file: '\(filename)' already exists in atlas \(abbreviatedFolder)\n")

            svgIdx = selected.svg
            svgAdded = false
        } else {
            output.append("Adding file: '\(filename)'\n")

            svgAdded = true
            svgIdx = (selected.atlas == atlasIdx
                ? selected.svg : atlases[atlasIdx].svgFiles.count - 1) + 1

            atlases[atlasIdx].svgFiles.insert(SVGFile(filename: filename), at: svgIdx)
        }

        return AddFileResult(indices: _Indices(atlas: atlasIdx, svg: svgIdx), atlasAdded: atlasAdded, svgAdded: svgAdded, output: output)
    }

    //    MARK: - IBActions

    @IBAction func undo(_: Any?) {
        undoManager?.undo()
    }

    @IBAction func redo(_: Any?) {
        undoManager?.redo()
    }

    @IBAction func sortAll(_: Any) {
        sortAll()
    }

    @IBAction func sortFolder(_: Any) {
        sortFolder()
    }

    // not connected to a menu, forwarded by AppDelegate
    @IBAction func clearOuputText(_: Any) {
        outputView.setString("")
    }

    @IBAction func exportAll(_: Any) {
        guard !prj.atlases.isEmpty,
            NSAlert.confirm("Export All Atlases?", suppressionKey: SuppressionKey.ExportAll) else { return }

        if selection() == _Indices.Empty {
            outlineView.selectRow(0)
        }

        outputView.setString("Exporting...\n")
        ExportManager.export(atlases: prj.atlases, completionHander: exportCompletion)
    }

    @IBAction func exportSelected(_: Any) {
        let indices = selection()
        guard indices.atlas != _Indices.None,
            NSAlert.confirm("Export selected?", suppressionKey: SuppressionKey.Export)
        else { return }

        outputView.setString("Exporting...\n")
        let atlas = prj.atlases[indices.atlas]

        if indices.svg != _Indices.None {
//
            let exportFile = ExportFile.create(atlas: atlas, svgFile: atlas.svgFiles[indices.svg])
            let parser = SvgParser(svgURL: exportFile[1].inputURL!) { parser in
                debugLog("Parsing finished")
            }
            parser?.parse()

            ExportManager.export(atlas: atlas, svgFile: atlas.svgFiles[indices.svg], completionHander: exportCompletion)
        } else {
            ExportManager.export(atlases: [atlas], completionHander: exportCompletion)
        }
    }

    lazy var exportCompletion: (String) -> Void = { [weak self] (output: String) -> Void in

        guard let self = self else { return }
        self.outputView.append("\(output)\n")
        self.outputView.scrollToEndOfDocument(self)
    }

    @IBAction func removeSelected(_ sender: Any) {
        deleteBackward(sender)
    }

    @IBAction func outlineDoubleClicked(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        guard let indices = item as? _Indices else { return }

        if indices.svg == _Indices.None {
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        }
    }

    @IBAction func buttonStateChanged(_: Any) {
        let index = outlineView.selectedRow
        let item = outlineView.item(atRow: index)

        guard let indices = item as? _Indices else { return }
        let svgFile = prj.atlases[indices.atlas].svgFiles[indices.atlas]

        updateResolutions(svgFile: svgFile)
    }

    @IBAction func sizeChanged(_ sender: NSTextField) {
        let rowIdx = outlineView.selectedRow
        let item = outlineView.item(atRow: rowIdx)
        guard let indices = item as? _Indices else { return }

        let atlas = prj.atlases[indices.atlas]

        if indices.svg == _Indices.None {
            switch sender.identifier?.rawValue
            {
            case "Width":
                if atlas.defaultWidth != sender.integerValue {
                    prj.atlases[indices.atlas].defaultWidth = sender.integerValue
                    document.updateChangeCount(.changeDiscardable)
                }
            case "Height":
                if atlas.defaultHeight != sender.integerValue {
                    prj.atlases[indices.atlas].defaultHeight = sender.integerValue
                    document.updateChangeCount(.changeDiscardable)
                }
            default:
                fatalError("Unknown sender identifer: \(sender.identifier?.rawValue ?? "(unknown)")")
            }

            return
        } else {
            let svgFile = atlas.svgFiles[indices.svg]

            switch sender.identifier?.rawValue
            {
            case "Width":
                if svgFile.width != sender.integerValue {
                    prj.atlases[indices.atlas].svgFiles[indices.svg].width = sender.integerValue
                    document.updateChangeCount(.changeDiscardable)
                }
            case "Height":
                if svgFile.height != sender.integerValue {
                    prj.atlases[indices.atlas].svgFiles[indices.svg].height = sender.integerValue
                    document.updateChangeCount(.changeDiscardable)
                }
            default:
                fatalError("Unknown sender identifer: \(sender.identifier?.rawValue ?? "(unknown)")")
            }
        }
    }

    @IBAction func addFolder(_: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Add"
        panel.message = "Select a folder to add"

        panel.beginSheetModal(for: view.window!) { [weak self] in

            let panelResult = $0
            if panelResult == NSApplication.ModalResponse.OK {
                guard let url = panel.url else { return }
                guard let self = self else { return }
                let idx = self.prj.indexOf(folder: url.path)

                if idx != -1 {
                    let message = "Folder is already in project: \(url.path)"
                    NSAlert.error(message)
                    return
                }

                self.addAtlas(url: url)
            }
        }
    }

    @IBAction func addFiles(_: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = "Add"
        panel.message = "Select .svg files to add"
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = [SVGFile.FileExtension]

        panel.beginSheetModal(for: view.window!) { [weak self] in

            let panelResult = $0
            if panelResult == NSApplication.ModalResponse.OK {
                let urls = panel.urls
                guard !urls.isEmpty else { return }
                guard let self = self else { return }

                self.addSVGFiles(urls: urls)
            }
        }
    }

    //    MARK: Public Functions

    func setAtlases(_ newAtlases: [Atlas]) {
        let oldAtlases = prj.atlases
        prj.atlases = newAtlases
        reload()

        if undoManager!.isUndoing || undoManager!.isRedoing {
            outputView.setString("")
        }

        undoManager?.registerUndo(withTarget: self) { me in
            me.setAtlases(oldAtlases)
        }
    }

    func addAtlas(url: URL, selectAddedAtlas: Bool = true) {
        let rowIdx = addAtlasIndex()
        var atlases = prj.atlases

        let atlas = Atlas(filepath: url.path)
        atlases.insert(atlas, at: rowIdx)
        setAtlases(atlases)

        if selectAddedAtlas {
            let rowIdx = outlineView.row(forItem: _Indices(atlas: rowIdx))
            outlineView.selectRow(rowIdx)
        }
    }

    func addSVGFiles(urls: [URL]) {
        var indices = selectionImplicit()
        var changed = false
        var addedFiles = 0
        var lastIndices = _Indices.Empty
        let rowIdx = outlineView.selectedRow
        var atlases = prj.atlases

        for url in urls {
            let result = addSVGFile(&atlases, url: url, selected: indices)

            indices = result.indices
            lastIndices = indices

            if result.atlasAdded {
                changed = true
            }

            if result.svgAdded {
                changed = true
                addedFiles += 1
            }

            outputView.append("\(result.output)")
        }

        outputView.append("Done - \(addedFiles) file(s) added\n")
        outputView.scrollToEndOfDocument(self)

        if changed {
            setAtlases(atlases)

            if lastIndices != _Indices.Empty {
                outlineView.expandItem(_Indices(atlas: lastIndices.atlas))
                outlineView.selectRow(outlineView.row(forItem: lastIndices))
            }
        } else {
            outlineView.selectRow(rowIdx)
        }
    }
}

// MARK: - NSMenuItemValidation

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let title = menuItem.title

        if title.hasPrefix("Remove") {
            if outlineView.clickedRow != outlineView.selectedRow {
                outlineView.selectRow(outlineView.clickedRow)
            }

            return selection().atlas != _Indices.None
        }

        if title.hasPrefix("Sort All")
            || title.hasPrefix("Export All") {
            return !prj.atlases.isEmpty
        }

        if title.hasPrefix("Sort Selected")
            || title.hasPrefix("Export Selected") {
            let indices = selection()

            return indices.atlas != _Indices.None
                && !prj.atlases[indices.atlas].svgFiles.isEmpty
                ? true : false
        }

        if title.hasPrefix("Clear Output") {
            return !outputView.stringValue.isEmpty
        }

        if title.hasPrefix("Undo") {
            return undoManager?.canUndo ?? false
        }

        if title.hasPrefix("Redo") {
            return undoManager?.canRedo ?? false
        }

        return true
    }
}

// MARK: - NSOutlineViewDataSource

extension ViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return prj.atlases.count
        } else if let indices = item as? _Indices {
            return prj.atlases[indices.atlas].svgFiles.count
        } else {
            return 0
        }
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return _Indices(atlas: index)
        }

        guard let indices = item as? _Indices else { return -1 }
        return _Indices(atlas: indices.atlas, svg: index)
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let indices = item as? _Indices else { return false }
        return indices.svg == _Indices.None ? true : false
    }
}

// MARK: - NSOutlineViewDelegate

extension ViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        guard let indices = item as? _Indices else { return nil }

        var view: NSTableCellView?
        let atlas = prj.atlases[indices.atlas]

        if indices.svg == _Indices.None {
            let cellIdentifier = NSUserInterfaceItemIdentifier("AtlasCell")
            view = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

            if let textField = view?.textField {
                textField.stringValue = URL(fileURLWithPath: atlas.folder, isDirectory: true).lastPathComponent
                textField.sizeToFit()
            }

            return view
        }

        let svgFile = atlas.svgFiles[indices.svg]
        let cellIdentifier = NSUserInterfaceItemIdentifier("SvgFileCell")
        view = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if let textField = view?.textField {
            textField.stringValue = svgFile.filename
            textField.sizeToFit()
        }

        return view
    }

    func outlineViewSelectionDidChange(_: Notification) {
        let index = outlineView.selectedRow
        let item = outlineView.item(atRow: index)

        guard let indices = item as? _Indices else {
            propertiesBox.isHidden = true
            pathStack.isHidden = true
            filenameTextField.stringValue = ""
            return
        }

//        if selected row is an Atlas
        if indices.svg == _Indices.None {
            let atlas = prj.atlases[indices.atlas]

            resetPathControls(atlas: atlas)
            widthTextField.integerValue = atlas.defaultWidth
            heightTextField.integerValue = atlas.defaultHeight

            propertiesBox.title = "Default Width and Height"
            propertiesBox.isHidden = false
            pathStack.isHidden = false
            resolutionsGroup.isHidden = true
            return
        }

//        selected row not an atlas, it must be a svg
        let atlas = prj.atlases[indices.atlas]
        let svgFile = atlas.svgFiles[indices.svg]

        resetPathControls(atlas: atlas)

        let resolutions = svgFile.supportedResolutions
        x1Button.state = resolutions.contains(.x1) ? NSControl.StateValue.on : NSControl.StateValue.off
        x2Button.state = resolutions.contains(.x2) ? NSControl.StateValue.on : NSControl.StateValue.off
        x3Button.state = resolutions.contains(.x3) ? NSControl.StateValue.on : NSControl.StateValue.off

        resetSizeTextFields(textField: widthTextField, svgValue: svgFile.width, atlasValue: atlas.defaultWidth)
        resetSizeTextFields(textField: heightTextField, svgValue: svgFile.height, atlasValue: atlas.defaultHeight)

        propertiesBox.title = "SVG File Width and Height"
        propertiesBox.isHidden = false
        pathStack.isHidden = false
        resolutionsGroup.isHidden = false
    }
}

//    MARK: - SvgProjectDelegate

extension ViewController: SvgProjectDelegate {
    func beforeSave() {
        for idx in 0 ..< prj.atlases.count {
            let indices = _Indices(atlas: idx)
            prj.atlases[idx].exapnded = outlineView.isItemExpanded(indices)
        }
    }
}

// MARK: - PathControlDelegate

extension ViewController: PathControlDelegate {
    func pathChanged(_ url: URL?) {
        let rowIdx = outlineView.selectedRow
        let item = outlineView.item(atRow: rowIdx)
        guard let indices = item as? _Indices else { return }

        prj.atlases[indices.atlas].outputFolder = url?.path ?? ""
        document.updateChangeCount(.changeDone)
    }
}
