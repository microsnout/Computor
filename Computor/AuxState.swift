//
//  AuxState.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-07.
//
import SwiftUI
import OSLog

let logAux = Logger(subsystem: "com.microsnout.calculator", category: "aux")


/// State variables associated with the auxiliary display

struct AuxState {
    // Active view of the Auxiliary display
    var activeView = AuxDispView.memoryList
    
    // Memory Detail Item - current focused memory item in detail view
    var detailItemIndex: Int = 0
    
    // MacroListView state
    var macroKey = SymbolTag(.null)
    var list = MacroOpSeq()
    
    // Fn key currrently recording
    var kcRecording: KeyCode? = nil
    
    // Pause recording when value greater than 0
    var pauseCount: Int = 0
}


extension AuxState {
    
    var isRecording: Bool { kcRecording != nil }
    
    func isRecordingKey( _ kc: KeyCode ) -> Bool {
        kcRecording == kc
    }

    func getDebugText() -> String {
        var txt = "AuxState("
        txt += String( describing: activeView )
        txt += ") Detail:\(detailItemIndex) MacroKey:"
        txt += String( describing: macroKey )
        txt += " OpSeq:\(list.getDebugText()) Rec:"
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
        return list.opSeq.count
    }
    
    mutating func startRecFn( _ kc: KeyCode ) {
        if KeyCode.fnSet.contains(kc) && !isRecording {
            // We can start recording key kc
            // Start with an empty list of instructions
            // Auxiliary display mode to macro list
            
            // Clear display of existing macro if any
            macroKey = SymbolTag(.null)
            list.clear()
            
            kcRecording = kc
            activeView = .macroList
            
            // Disable all Fn keys except the one recording
            for key in KeyCode.fnSet {
                if key != kc {
                    SubPadSpec.disableList.insert(key)
                }
            }
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "startRecFn: \(auxTxt)" )
        }
        else {
            // Trying to start recording for an invalid key or we are already recording
            assert(false)
        }
    }
    
    mutating func recordKeyFn( _ event: KeyEvent ) {
        if pauseCount > 0 {
            logAux.debug( "recordKeyFn: Paused" )
            return
        }
        
        if !isRecording
        {
            logAux.debug( "recordKeyFn: Not Recording" )
            return
        }
        
        switch event.kc {
            
        case .enter:
            if let last = list.opSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // An enter is not needed in recording if preceeded by an untyped value
                    break
                }
            }
            // Otherwise record the key
            list.opSeq.append( MacroKey( event ) )

        case .back:
            // Backspace, need to remove last op or possibly undo a unit tag
            if let last = list.opSeq.last {
                
                if let value = last as? MacroValue
                {
                    // Last op is a value op
                    if value.tv.tag == tagUntyped {
                        
                        // No unit tag, just remove the value
                        list.opSeq.removeLast()
                    }
                    else {
                        // A tagged value, remove the tag
                        list.opSeq.removeLast()
                        var tv = value.tv
                        tv.tag = tagUntyped
                        list.opSeq.append( MacroValue( tv: tv))
                    }
                }
                else {
                    // Last op id just a key op
                    list.opSeq.removeLast()
                }
            }
            
        case let kc where kc.isUnit:
            if let last = list.opSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // Last macro op is an untyped value
                    if let tag = TypeDef.kcDict[kc] {
                        
                        var tv = value.tv
                        list.opSeq.removeLast()
                        tv.tag = tag
                        list.opSeq.append( MacroValue( tv: tv))
                        break
                    }
                }
            }
            fallthrough
            
        default:
            // Just record the key
            list.opSeq.append( MacroKey( event ) )
        }
        
        // Log debug output
        let auxTxt = getDebugText()
        logAux.debug( "recordKeyFn: \(auxTxt)" )
    }
    
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if isRecording
        {
            list.opSeq.append( MacroValue( tv: tv) )
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "recordValueFn: \(auxTxt)" )
        }
    }
    
    
    mutating func stopRecFn( _ kc: KeyCode ) {
        if let kcRec = kcRecording {
            
            // Stop recording and Change macro display to display the new macro
            kcRecording = nil
            macroKey = SymbolTag(kcRec)
            
            // Re-enable all recording keys
            SubPadSpec.disableList.removeAll()
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "stopRecFn: \(auxTxt)" )
        }
    }
}

