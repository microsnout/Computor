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
    case inactive = 0, stop, record, recModal, recNestedModal, play, debug
    
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
    var recState: MacroRecState = .inactive
    
    // Cursor into op sequence in macro - for stepping and editing
    var opCursor: Int = 0
    
    var errorFlag: Bool = false
    
    var auxLVF: LocalVariableFrame? = nil
    
    // View refresh toggle value
    var refresh: Bool = false
}


extension AuxState {
    
    static let recStates:Set<MacroRecState> = [.record, .recModal, .recNestedModal]
    
    var isRec: Bool { AuxState.recStates.contains( self.recState ) }
    
    
    // *** Macro Recorder Functions ***
    
    
    mutating func loadMacro( _ mr: MacroRec ) {
        
        /// ** Load Macro **
        /// This will change Aux display to Macro Detail view in the 'Stop' state
        
        switch recState {
            
        case .inactive, .stop:
            // Set macro detail view to mr and switch to macro view pane
            macroRec   = mr
            activeView = .macroView
            opCursor   = 0
            auxLVF     = nil
            recState   = .stop
            errorFlag  = false

        default:
            assert(false)
            break
        }
    }
    
    
    mutating func setError( at index: Int ) {
        opCursor = index
        errorFlag = true
    }
    
    
    mutating func clearError() {
        errorFlag = false
    }
    
    
    mutating func resetMacroCursor() {
        
        /// ** Reset Macro Cursor **
        
        opCursor  = 0
    }
    

    mutating func stopMacroRecorder() {
        
        /// ** Stop Macro Recorder **
        
        auxLVF    = nil
        recState  = .stop
        errorFlag = false
    }
    
    
    mutating func deactivateMacroRecorder() {
        
        /// ** Deactivate Macro Recorder **
        /// This will retrun Aux display to Macro List

        stopMacroRecorder()
        macroRec   = nil
        recState   = .inactive
        errorFlag  = false
    }

    
    mutating func startDebug( at line: Int = 0 ) {
        
        switch recState {
            
        case .stop:
            // Establich a local variable frame and switch to play/stop debug mode
            auxLVF = LocalVariableFrame()
            opCursor   = line
            errorFlag  = false
            recState   = .debug

        default:
            break
        }
    }
    
    
    // *** Matched Functions ***

    mutating func record( _ mr: MacroRec, in mfr: ModuleRec ) {
        
        switch recState {
            
        case .inactive:
            macroMod = mfr
            loadMacro(mr)
            activeView = .macroView
            fallthrough
            
        case .stop:
            mr.opSeq.clear()
            recState = .record
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "startRecFn: \(auxTxt)" )
            
        default:
            assert(false)
            break
        }
    }
    
    
    mutating func recordStop() {
        
        switch recState {
            
        case .debug:
            stopMacroRecorder()
            
        case .record:
            stopMacroRecorder()
            
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
    
    
    // *** Matched Functions ***
    
    mutating func recordModalBlock() {
        
        switch recState {
            
        case .inactive, .stop:
            // Create new macro rec for modal func
            macroRec = MacroRec()
            activeView = .macroView
            SubPadSpec.disableAllFnSubmenu()
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

    
    mutating func recordModalBlockEnd() {
        
        switch recState {
            
        case .recModal:
            recState = .stop

        case .recNestedModal:
            recState = .record

        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    // ***
    
    
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

