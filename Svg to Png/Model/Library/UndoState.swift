//
//  UndoState.swift
//  Svg to Png
//
//  Created by Todd Denlinger on 3/21/19.
//  Copyright © 2019 Todd. All rights reserved.
//
// modified from: http://blog.benjamin-encz.de/post/simple-undo-redo-swift/

import Foundation

public protocol DeepCopying {
    init()
    func copy() -> DeepCopying
}

protocol UniqueId: Hashable, DeepCopying, CustomStringConvertible {
    init()
    var id: UUID { get }
}

extension UniqueId {
    func whoAmI() {
        print(type(of: self))
    }
}

class UniqueWrapper<T: DeepCopying>: UniqueId {
    private var _obj: T?
    var id: UUID = UUID()
    var hashValue: Int { return id.hashValue }
    var obj: T { return _obj! }
    
    required init() {}
    
    init(_ obj: T) {
        _obj = (obj.copy() as! T)
    }
    
    var description: String { return "\(id), \(obj)" }
    
    func copy() -> DeepCopying {
        let result = UniqueWrapper<T>( T()  )
        result._obj = _obj!.copy() as? T
        result.id = id
        return result
    }
    
    static func == (lhs: UniqueWrapper<T>, rhs: UniqueWrapper<T>) -> Bool {
        return lhs.id == rhs.id
    }
}

struct UndoStateStep<T: DeepCopying>: CustomStringConvertible {
    let oldValue: T?
    let newValue: T?
    
    var description: String { return "UndoStateStep: \n\told: \(String(describing: oldValue)) \n\tnew: \(String(describing: oldValue))" }
    
    /// Converts and undo step into a redo step and vice-versa.
    func flip() -> UndoStateStep<T> {
        debugLog("beforeFlip\n\told: \(String(describing: newValue)) \n\tnew: \(String(describing: newValue))")
        let result = UndoStateStep(oldValue: newValue, newValue: oldValue)
        debugLog("afterFlip\n\told: \(String(describing: newValue)) \n\tnew: \(String(describing: newValue))")
        return result
    }
}

class UndoState<T> where T: UniqueId {
    var state: Set<T> = [] { didSet { debugLog("\n\t\(state)") } }
    var undoStack: [UndoStateStep<T>] = [] { didSet { debugLog("\n\t\(undoStack)") } }
    var redoStack: [UndoStateStep<T>] = [] { didSet { debugLog("\n\t\(redoStack)") } }
    
    func byId(_ uuid: UUID) -> T? { return state.first { $0.id == uuid } }
    
    func save(_ obj: T, isUndoRedo: Bool = false) {
        debugLog()
        // Don't record undo step for actions that are performed
        // as part of undo/redo.
        if !isUndoRedo {
            // Fetch old value
            let oldValue = byId(obj.id)
            // Store change on undo stack
            let undoStep = UndoStateStep(oldValue: oldValue, newValue: obj)
            undoStack.append(undoStep)
            // Reset redo stack after each user action that is not an undo/redo.
            redoStack = []
        }
        
        // Update in-memory state.
        state.remove(obj)
        state.insert(obj)
        debugLog("Exiting\n")
    }
    
    func delete(_ obj: T, isUndoRedo: Bool = false) {
        if !isUndoRedo {
            // Fetch old value
            let oldValue = byId(obj.id)
            // Store change on undo stack
            let undoStep = UndoStateStep(oldValue: oldValue, newValue: nil)
            undoStack.append(undoStep)
            
            // Reset redo stack after each user action that is not an undo/redo.
            redoStack = []
        }
        
        state.remove(obj)
    }
    
    func undo() {
        debugLog()
        guard let undoRedoStep = self.undoStack.popLast() else { return }
        perform(undoRedoStep: undoRedoStep)
        redoStack.append(undoRedoStep.flip())
        debugLog("Exiting ...")
    }
    
    func redo() {
        debugLog()
        guard let undoRedoStep = self.redoStack.popLast() else { return }
        perform(undoRedoStep: undoRedoStep)
        undoStack.append(undoRedoStep.flip())
        debugLog("Exiting ...")
    }
    
    func perform(undoRedoStep: UndoStateStep<T>) {
        // Switch over the old and new value and call a store method that
        // implements the transition between these values.
        switch (undoRedoStep.oldValue, undoRedoStep.newValue) {
        // Old and new value are non-nil: update.
        case let (oldValue?, _?):
            save(oldValue, isUndoRedo: true)
        // New value is nil, old value was non-nil: create.
        case (let oldValue?, nil):
            // Our `save` implementation also handles creates, but depending
            // on your DB interface these might be separate methods.
            save(oldValue, isUndoRedo: true)
        // Old value was nil, new value was non-nil: delete.
        case (nil, let newValue?):
            delete(newValue, isUndoRedo: true)
        default:
            fatalError("Undo step with neither old nor new value makes no sense")
        }
    }
}
