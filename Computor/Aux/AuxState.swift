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
    case stop = 0, record, recModal, recNestedModal, play, playStep
    
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
    var activeView = AuxDispView.memoryView
    
    // Memory Detail Item - current focused memory item in detail view
    var memRec: MemoryRec? = nil
    
    // Currently viewed macro module file
    var macroMod: ModuleRec = ModuleRec( name: "_" )

    // Currently selected macro record - if non-nil displays macro detail view
    var macroRec: MacroRec? = nil
    
    // State of macro detail view - only significant if macroRec is not nil
    var recState: MacroRecState = .stop
    
    // Cursor into op sequence in macro - for stepping and editing
    var opCursor: Int = 0
    
    var auxLVF: LocalVariableFrame? = nil
    
    // View refresh toggle value
    var refresh: Bool = false
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
    
    
    // *** Macro Recorder Functions ***
    
    
    mutating func loadMacro( _ mr: MacroRec ) {
        
        /// ** Load Macro **
        /// This will change Aux display to Macro Detail view in the 'Stop' state
        
        switch recState {
            
        case .stop:
            // Set macro detail view to mr and switch to macro view pane
            macroRec   = mr
            activeView = .macroView
            opCursor   = 0

        default:
            assert(false)
        }
    }

    mutating func stopMacroRecorder() {
        
        /// ** Stop Macro Recorder **
        /// This will retrun Aux display to Macro List
        
        macroRec = nil
        recState = .stop
        opCursor = 0
    }
    
    
    mutating func stepForward() {
        
        switch recState {
            
        case .stop:
            auxLVF = LocalVariableFrame()
            opCursor = 0
            recState = .playStep
            fallthrough
            
        case .playStep:
            assert( auxLVF != nil )
            
            if let op = macroRec?.opSeq[opCursor] {
                
                
                opCursor += 1
            }
            
        default:
            break
        }
    }
    
    
    mutating func record( _ mr: MacroRec, in mfr: ModuleRec ) {
        
        switch recState {
            
        case .stop:
            macroMod = mfr
            macroRec = mr
            mr.opSeq.clear()
            activeView = .macroView
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
            
        case .stop:
            // Create new macro rec for modal func
            macroRec = MacroRec()
            activeView = .macroView
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
            
            // Re-enable all recording keys
            SubPadSpec.disableList.removeAll()
            
        case .recNestedModal:
            // Cancel recording as modal rec is incomplete
            stopMacroRecorder()
            
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
            recState = recState == .recNestedModal ? .record : .stop
            
        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    
    func getDebugText() -> String {
        var txt = "AuxState("
        txt += String( describing: activeView )
        txt += ") state:\(recState)"
        txt += " Detail:\(memRec.debugDescription) MacroKey:"
        
        if let mr = macroRec {
            txt += String( describing: mr.symTag )
            txt += " OpSeq:\(mr.opSeq.getDebugText()) Rec:"
        }
        return txt
    }
    
}

