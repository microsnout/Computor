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
    case inactive = 0, stop, record, recModal, play, debug
    
    var isRecording: Bool {
        switch self {
            
        case .record, .recModal:
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

    // Currently selected macro record - if non-null displays macro detail view
    var macroRec: MacroRec? = nil

    // Currently selected plot record
    var plotTag: SymbolTag = SymbolTag.Null
   
    // State of macro detail view - only significant if macroRec is not nil
    var recState: MacroRecState = .inactive
    
    // Cursor into op sequence in macro - for stepping and editing
    var opCursor: Int = 0
    
    // Index of ValueBrowser register display
    var valueIndex: Int = 2
    
    var errorFlag: Bool = false
    
    var auxLVF: LocalVariableFrame? = nil
    
    // View refresh toggle value
    var refresh: Bool = false
}


extension AuxState {
    
    static let recStates:Set<MacroRecState> = [.record, .recModal]
    
    var isRec: Bool { AuxState.recStates.contains( self.recState ) }
    
    var macroTag: SymbolTag {
        get {
            macroRec?.symTag ?? SymbolTag.Null
        }
        
        set {
            macroRec = macroMod.getLocalMacro(newValue)
        }
    }

    var plotRec: PlotRec? {
        get {
            macroMod.getLocalPlot(plotTag)
        }
        set {
            if let pr = newValue {
                plotTag = pr.symTag
            }
            else {
                plotTag = SymbolTag.Null
            }
        }
    }
    
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
    

    mutating func auxRecorderStop() {
        
        /// ** Stop Macro Recorder **
        
        auxLVF    = nil
        recState  = .stop
        errorFlag = false
    }
    
    
    mutating func deactivateMacroRecorder() {
        
        /// ** Deactivate Macro Recorder **
        /// This will retrun Aux display to Macro List

        auxRecorderStop()
        
        macroRec   = nil
        recState   = .inactive
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

    mutating func record( _ mr: MacroRec ) {
        
        switch recState {
            
        case .inactive:
            loadMacro(mr)
            activeView = .macroView
            fallthrough
            
        case .stop:
            mr.opSeq.clear()
            recState = .record
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "startRecFn: \(auxTxt)" )
            
        case .debug:
            recState = .record
            
        default:
            assert(false)
            break
        }
    }
    
    
    // *** Matched Functions ***
    
    mutating func recordModalBlock() {
        
        switch recState {
            
        case .inactive, .stop:
            // Create new macro rec for modal func
            macroTag = SymbolTag.Modal
            activeView = .macroView
            SubPadSpec.disableAllFnSubmenu()
            recState = .recModal
            opCursor = 0
            
        case .record, .recModal:
            break
            
        default:
            // Should not happen
            assert(false)
            break
        }
    }

    
    mutating func recordModalBlockEnd() {
        
        switch recState {
            
        case .record:
            break

        case .recModal:
            macroMod.deleteMacro( SymbolTag.Modal )
            recState = .inactive

        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    // ***
    
    
    func getDebugText() -> String {
        var txt = "ActiveView:"
        txt += String( describing: activeView )
        txt += " RecState:\(recState)"
        txt += " MemRec:\(memRec.debugDescription)"
        
        if let mr = macroRec {
            if mr.symTag != SymbolTag.Null {
                txt += " SymTag:\(String( describing: mr.symTag) )"
            }
            txt += " OpSeq:\(mr.opSeq.getDebugText())"
        }
        return txt
    }
    
}

