
import Cocoa

class CommandController: NSViewController {
    enum Column: Int {
        case isDefault = 0, command = 1
        var indexSet: IndexSet { return IndexSet(integer: rawValue) }
    }

    @IBOutlet var commandTable: NSTableView!
    @IBOutlet var commandText: NSTextView!
    @IBOutlet var addButton: NSButton!
    @IBOutlet var removeButton: NSButton!

    fileprivate var hasChanges = false
    fileprivate var exportCommands = ExportCommandManager.shared.exportCommands {
        didSet {
            hasChanges = true
        }
    }

    //    MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        commandTable.delegate = self
        commandTable.dataSource = self
        commandTable.focusRingType = .none
        commandText.delegate = self
        reload()
    }

    override func viewWillAppear() {
        view.window?.delegate = self
    }

    //    MARK: - Private Methods

    fileprivate func reload() {
        commandTable.reloadData()
        updateViewState()
    }

    fileprivate func save() {
        if exportCommands.validate(repair: true) {
            reload()
        }

        guard hasChanges else { return }

        let manager = ExportCommandManager.shared
        manager.exportCommands = exportCommands
        manager.save()
        hasChanges = false
    }

    fileprivate func updateViewState() {
        let selectedRow = commandTable.selectedRow

        if selectedRow == -1 {
            commandText.setString("")
            commandText.isEditable = false
            removeButton.isHidden = true
            removeButton.isEnabled = false
            return
        }

        let exportCommand = exportCommands.commands[selectedRow].obj

        if exportCommand.options.contains(.predfined) {
            commandText.isEditable = false
            removeButton.isHidden = true
            removeButton.isEnabled = false
        } else {
            commandText.setString(exportCommands.commands[selectedRow].obj.command)
            commandText.isEditable = true
            removeButton.isHidden = false
            removeButton.isEnabled = true
            view.window!.makeFirstResponder(commandText)
        }

        commandText.setString(exportCommand.command)
    }

    //    MARK: - IBActions

    @IBAction func addButton(_: Any) {
        if exportCommands.insert(command: ExportCommand(object: _ExportCommand("(new command)"))) {
            reload()
            let indexSet = IndexSet(integer: commandTable.numberOfRows - 1)
            commandTable.selectRowIndexes(indexSet, byExtendingSelection: false)
            commandTable.scrollToEndOfDocument(self)
            commandText.selectAll(self)
        }
    }

    @IBAction func removeButton(_: Any) {
        let selectedRow = commandTable.selectedRow
        guard selectedRow >= 0 else { return }

        let exportCommand = exportCommands.commands[selectedRow].obj
        guard !exportCommand.options.contains(.predfined) else { return }

        precondition(commandTable.numberOfRows > 1)
        if exportCommand.options.contains(.isDefault), commandTable.numberOfRows > 1 {
            exportCommands.setDefault(at: 0)
        }

        exportCommands.remove(at: selectedRow)
        reload()
    }

    @IBAction func resetToDefaults(_: Any) {
        let confirm = "Remove all commands and reset to defaults?\n\nThis can't be undone"
        guard NSAlert.confirm(confirm) else { return }

        let manager = ExportCommandManager.shared
        manager.resetToDefaults()
        exportCommands = manager.exportCommands
        reload()
        hasChanges = false
    }
}

//    MARK: - NSTableViewDataSource

extension CommandController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return exportCommands.commands.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let tableColumn = tableColumn else { return nil }

        if tableColumn == tableView.tableColumns[Column.isDefault.rawValue] {
            if exportCommands.commands[row].obj.options.contains(.isDefault) {
                return 1
            }
        } else if tableColumn == tableView.tableColumns[Column.command.rawValue] {
            return exportCommands.commands[row].obj.command
        }

        return nil
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let state = object as? Bool else { return }
        exportCommands.setDefault(at: state ? row : -1)
        reload()
    }
}

//    MARK: - NSTableViewDelegate

extension CommandController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_: Notification) {
        updateViewState()
    }
}

//    MARK: - NSTextViewDelegate

extension CommandController: NSTextViewDelegate {
    func textDidChange(_: Notification) {
        let selectedRow = commandTable.selectedRow
        let rowIndexSet = IndexSet(integer: commandTable.selectedRow)

        exportCommands.commands[selectedRow].obj.command = commandText.string
        commandTable.reloadData(forRowIndexes: rowIndexSet, columnIndexes: Column.command.indexSet)
    }
}

extension CommandController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        save()
    }

    func windowDidResignKey(_: Notification) {
        save()
    }
}
