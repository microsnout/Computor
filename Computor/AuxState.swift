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
}


/// State variables associated with the auxiliary display

struct AuxState {
    // Active view of the Auxiliary display
    var activeView = AuxDispView.memoryList
    
    // Memory Detail Item - current focused memory item in detail view
    var detailItemIndex: Int = -1
    
    // MacroListView state
    var recState: MacroRecState = .none
    
    var macroKey = SymbolTag(.null)
    var macroSeq = MacroOpSeq()
    var macroCap = ""
    
    // Fn key currrently recording
    var kcRecording: KeyCode? = nil
    
    // Pause recording when value greater than 0
    var pauseCount: Int = 0
    
    // Number of active modal recording blocks {..}
    var modalRecCount: Int = 0
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
        macroKey = SymbolTag(.null)
        macroSeq.clear()
        kcRecording = nil
        pauseCount = 0
        modalRecCount = 0
    }
    
    
    mutating func record( _ sTag: SymbolTag = SymbolTag(.null), kc: KeyCode? = nil, caption: String? = nil ) {
        switch recState {
            
        case .stop, .none:
            // Start recording, sTag is requireds but can be null, kc is optional
            if let kcFn = kc {
                
                kcRecording = kc

                if sTag == SymbolTag(.null) {
                    
                    // kc provided but no tag - try to create tag from kc
                    guard let fnTag = SymbolTag.getFnSym(kcFn) else {
                        // if a kc is provided it must map to a tag
                        assert(false)
                    }
                    
                    macroKey = fnTag
                }
                else {
                    // Both tag and kc provided - re-recording a renamed Fn key
                    macroKey = sTag
                }
            }
            else {
                // No kc provided - recording macro that is not assigned to a key
                macroKey = sTag
                kcRecording = nil
            }
            macroCap = caption ?? ""
            macroSeq.clear()
            modalRecCount = 0
            activeView = .macroList
            recState = .record

            if let kcFn = kc {
                disableAllFnSubmenu( except: kcFn )
            }
            
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
            macroKey = SymbolTag(.null)
            macroSeq.clear()
            kcRecording = nil
            activeView = .macroList
            disableAllFnSubmenu()
            modalRecCount = 1
            recState = .recModal

        case .record:
            modalRecCount = 1
            recState = .recNestedModal
            
        case .recModal:
            modalRecCount += 1

        case .recNestedModal:
            modalRecCount += 1

        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    
    mutating func recordStop() {
        
        switch recState {
            
        case .record:
            kcRecording = nil
            recState = .stop
            
            // Re-enable all recording keys
            SubPadSpec.disableList.removeAll()
            
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
            modalRecCount -= 1
           
            if modalRecCount == 0 {
                // Re-enable all recording keys
                SubPadSpec.disableList.removeAll()
            }
            
            recState = recState == .recNestedModal ? .record : .none

        default:
            // Should not happen
            assert(false)
            break
        }
    }
    
    
    
    // Old Code below
    
    func isRecordingKey( _ kc: KeyCode ) -> Bool {
        kcRecording == kc
    }

    func getDebugText() -> String {
        var txt = "AuxState("
        txt += String( describing: activeView )
        txt += ") state:\(recState)"
        txt += " Detail:\(detailItemIndex) MacroKey:"
        txt += String( describing: macroKey )
        txt += " OpSeq:\(macroSeq.getDebugText()) Rec:"
        txt += String( describing: kcRecording ?? KeyCode.null )
        txt += " Pause:\(pauseCount)"
        return txt
    }
    
    mutating func pauseRecording() {
        pauseCount += 1
    }

    mutating func resumeRecording() {
        pauseCount -= 1
    }
    
    
    func markMacroIndex() -> Int {
        // The index of the next element to be added will be...
        return macroSeq.count
    }
    
    
    mutating func recordKeyFn( _ event: KeyEvent ) {
        if pauseCount > 0 {
            logAux.debug( "recordKeyFn: Paused" )
            return
        }
        
        if !isRec
        {
            logAux.debug( "recordKeyFn: Not Recording" )
            return
        }
        
        switch event.kc {
            
        case .enter:
            if let last = macroSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // An enter is not needed in recording if preceeded by an untyped value
                    break
                }
            }
            // Otherwise record the key
            macroSeq.append( MacroKey( event ) )

        case .back:
            // Backspace, need to remove last op or possibly undo a unit tag
            if let last = macroSeq.last {
                
                if let value = last as? MacroValue
                {
                    // Last op is a value op
                    if value.tv.tag == tagUntyped {
                        
                        // No unit tag, just remove the value
                        macroSeq.removeLast()
                    }
                    else {
                        // A tagged value, remove the tag
                        macroSeq.removeLast()
                        var tv = value.tv
                        tv.tag = tagUntyped
                        macroSeq.append( MacroValue( tv: tv))
                    }
                }
                else {
                    // Last op id just a key op
                    macroSeq.removeLast()
                }
            }
            
        case let kc where kc.isUnit:
            if let last = macroSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // Last macro op is an untyped value
                    if let tag = TypeDef.kcDict[kc] {
                        
                        var tv = value.tv
                        macroSeq.removeLast()
                        tv.tag = tag
                        macroSeq.append( MacroValue( tv: tv))
                        break
                    }
                }
            }
            fallthrough
            
        default:
            // Just record the key
            macroSeq.append( MacroKey( event ) )
        }
        
        // Log debug output
        let auxTxt = getDebugText()
        logAux.debug( "recordKeyFn: \(auxTxt)" )
    }
    
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if isRec
        {
            macroSeq.append( MacroValue( tv: tv) )
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "recordValueFn: \(auxTxt)" )
        }
    }
    
}

