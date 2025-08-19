//
//  AuxState.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-07.
//
import SwiftUI
import OSLog

let logAux = Logger(subsystem: "com.microsnout.calculator", category: "aux")


enum MacroRecState: Int {
    case none = 0, stop, record, recModal, recNestedModal, play, playSlow
    
    var isRecording: Bool {
        switch self {
        case .record, .recModal, .recNestedModal:
            return true
            
        default:
            return false
        }
    }
}


/// State variables associated with the auxiliary display

struct AuxState {
    // Active view of the Auxiliary display
    var activeView = AuxDispView.memoryList
    
    // Memory Detail Item - current focused memory item in detail view
    var detailItemIndex: Int = -1
    
    // MacroListView state
    var recState: MacroRecState = .none
    
    var macroRec: MacroRec? = nil
}


extension AuxState {
    
    static let recStates:Set<MacroRecState> = [.record, .recModal, .recNestedModal]
    
    var isRec: Bool { AuxState.recStates.contains( self.recState ) }
    
    func disableAllFnSubmenu( except kc: KeyCode = .null ) {
        // Disable all Fn key submenus except the one recording
        for key in KeyCode.fnSet {
            if key != kc {
                SubPadSpec.disableList.insert(key)
            }
        }
    }
    
    
    mutating func clearMacroState() {
        
        macroRec = nil
        recState = .none
    }
    
    
    mutating func loadMacro( _ mr: MacroRec ) {
        
        switch recState {
            
        case .none, .stop:
            macroRec = mr
            recState = .stop
            activeView = .macroList
            
        default:
            assert(false)
        }
    }
    
    
    mutating func record( _ mr: MacroRec ) {
        
        switch recState {
            
        case .none:
            assert( macroRec == nil )
            macroRec = mr
            recState = .stop
            fallthrough
            
        case .stop:
            assert( macroRec != nil )
            macroRec = mr
            mr.opSeq.clear()
            activeView = .macroList
            recState = .record
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "startRecFn: \(auxTxt)" )
            
        default:
            assert(false)
            break
        }
    }
    
    
    mutating func recordModal() {
        
        switch recState {
            
        case .stop, .none:
            // Create new macro rec for modal func
            macroRec = MacroRec()
            activeView = .macroList
            disableAllFnSubmenu()
            recState = .recModal
            
        case .record:
            recState = .recNestedModal
            
        case .recModal, .recNestedModal:
            break
            
        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    
    mutating func recordStop() {
        
        switch recState {
            
        case .record:
            recState = .stop
            
        case .recNestedModal:
            // Cancel recording as modal rec is incomplete
            clearMacroState()
            recState = .stop
            
            // Re-enable all recording keys
            SubPadSpec.disableList.removeAll()
            
        default:
            // Should not happen
            assert(false)
            break
        }
        
        // Log debug output
        let auxTxt = getDebugText()
        logAux.debug( "stopRecFn: \(auxTxt)" )
    }
    
    
    mutating func modalRecStop() {
        
        switch recState {
            
        case .recModal, .recNestedModal:
            recState = recState == .recNestedModal ? .record : .none
            
        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    
    
    // Old Code below
    
    func getDebugText() -> String {
        var txt = "AuxState("
        txt += String( describing: activeView )
        txt += ") state:\(recState)"
        txt += " Detail:\(detailItemIndex) MacroKey:"
        
        if let mr = macroRec {
            txt += String( describing: mr.symTag )
            txt += " OpSeq:\(mr.opSeq.getDebugText()) Rec:"
        }
        return txt
    }
    
}

