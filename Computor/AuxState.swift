//
//  AuxState.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-07.
//
import SwiftUI


struct AuxState {
    var mode: AuxDispMode = .memoryList
    var detailItemIndex: Int = 0
    var list = MacroOpSeq()
    var kcRecording: KeyCode? = nil
    var recording: Bool { kcRecording != nil }
    var pauseCount: Int = 0
    
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
            kcRecording = kc
            list.clear()
            mode = .macroList
            
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
        
        if recording
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
        if recording
        {
            list.opSeq.append( MacroValue( tv: tv) )
        }
    }
    
    mutating func stopRecFn( _ kc: KeyCode ) {
        if kc == kcRecording {
            kcRecording = nil
            list.clear()
            mode = .memoryList
            SubPadSpec.disableList.removeAll()
        }
    }
}

