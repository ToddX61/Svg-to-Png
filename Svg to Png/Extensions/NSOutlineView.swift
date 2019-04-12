
import Cocoa

extension NSOutlineView {
    // convenience function to select a single row
    func selectRow(_ index: Int) {
        guard index != -1 else { return }
        selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }
}
