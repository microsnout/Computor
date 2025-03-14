//
//  AuxState.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-07.
//
import SwiftUI

/// State variables associated with the auxiliary display

struct AuxState {
    // Active view of the Auxiliary display
    var activeView = AuxDispView.memoryList
    
    // Memory Detail Item - current focused memory item in detail view
    var detailItemIndex: Int = 0
    
    // MacroListView state
    var macroKey: KeyCode = .noop
    var list = MacroOpSeq()
    
    // Fn key currrently recording
    var kcRecording: KeyCode? = nil
    
    // Pause recording when value greater than 0
    var pauseCount: Int = 0
    
}


extension AuxState {
    
    var isRecording: Bool { kcRecording != nil }
    
    mutating func pauseRecording() {
        pauseCount += 1
    }

    mutating func resumeRecording() {
        pauseCount -= 1
    }
    
    mutating func startRecFn( _ kc: KeyCode ) {
        if KeyCode.fnSet.contains(kc) && kcRecording == nil {
            // We can start recording key kc
            // Start with an empty list of instructions
            // Auxiliary display mode to macro list
            
            // Clear display of existing macro if any
            macroKey = .noop
            list.clear()
            
            kcRecording = kc
            activeView = .macroList
            
            // Disable all Fn keys except the one recording
            for key in KeyCode.fnSet {
                if key != kc {
                    SubPadSpec.disableList.insert(key)
                }
            }
        }
    }
    
    mutating func recordKeyFn( _ kc: KeyCode ) {
        if pauseCount > 0 {
            return
        }
        
        if isRecording
        {
            // Fold unit keys into value on stack if possible
            if kc.isUnit {
                if let last = list.opSeq.last,
                   let value = last as? MacroValue
                {
                    if value.tv.tag == tagUntyped {
                        if let tag = TypeDef.kcDict[kc] {
                            var tv = value.tv
                            list.opSeq.removeLast()
                            tv.tag = tag
                            list.opSeq.append( MacroValue( tv: tv))
                            return
                        }
                    }
                }
            }
            
            list.opSeq.append( MacroKey( kc: kc) )
            
            let ix = list.opSeq.indices
            
            logM.debug("recordKey: \(ix)")
        }
    }
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if isRecording
        {
            list.opSeq.append( MacroValue( tv: tv) )
        }
    }
    
    mutating func stopRecFn( _ kc: KeyCode ) {
        if let kcRec = kcRecording {
            
            assert( kc == kcRec )
            
            // Stop recording and Change macro display to display the new macro
            kcRecording = nil
            macroKey = kcRec
            
            // Re-enable all recording keys
            SubPadSpec.disableList.removeAll()
        }
    }
}

