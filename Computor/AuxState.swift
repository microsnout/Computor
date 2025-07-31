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
        
        macroRec = nil
        pauseCount = 0
        modalRecCount = 0
        recState = .none
    }
    
    
    mutating func loadMacro( _ mr: MacroRec ) {
        
        switch recState {
            
        case .none, .stop:
            macroRec = mr
            recState = .stop
            
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
            modalRecCount = 0
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
    
    func getDebugText() -> String {
        var txt = "AuxState("
        txt += String( describing: activeView )
        txt += ") state:\(recState)"
        txt += " Detail:\(detailItemIndex) MacroKey:"
        
        if let mr = macroRec {
            txt += String( describing: mr.symTag )
            txt += " OpSeq:\(mr.opSeq.getDebugText()) Rec:"
        }
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
        guard let mr = macroRec else {
            assert(false)
            return 0
        }
        
        // The index of the next element to be added will be...
        return mr.opSeq.count
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
        
        guard let mr = macroRec else {
            // No macro record despite isRec is true
            assert(false)
            return
        }
        
        switch event.kc {
            
        case .enter:
            if let last = mr.opSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // An enter is not needed in recording if preceeded by an untyped value
                    break
                }
            }
            // Otherwise record the key
            mr.opSeq.append( MacroKey( event ) )

        case .back:
            // Backspace, need to remove last op or possibly undo a unit tag
            if let last = mr.opSeq.last {
                
                if let value = last as? MacroValue
                {
                    // Last op is a value op
                    if value.tv.tag == tagUntyped {
                        
                        // No unit tag, just remove the value
                        mr.opSeq.removeLast()
                    }
                    else {
                        // A tagged value, remove the tag
                        mr.opSeq.removeLast()
                        var tv = value.tv
                        tv.tag = tagUntyped
                        mr.opSeq.append( MacroValue( tv: tv))
                    }
                }
                else {
                    // Last op id just a key op
                    mr.opSeq.removeLast()
                }
            }
            
        case let kc where kc.isUnit:
            if let last = mr.opSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // Last macro op is an untyped value
                    if let tag = TypeDef.tagFromKeyCode(kc) {
                        
                        var tv = value.tv
                        mr.opSeq.removeLast()
                        tv.tag = tag
                        mr.opSeq.append( MacroValue( tv: tv))
                        break
                    }
                }
            }
            fallthrough
            
        default:
            // Just record the key
            mr.opSeq.append( MacroKey( event ) )
        }
        
        // Log debug output
        let auxTxt = getDebugText()
        logAux.debug( "recordKeyFn: \(auxTxt)" )
    }
    
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if isRec
        {
            guard let mr = macroRec else {
                // No macro record despite isRec is true
                assert(false)
                return
            }

            mr.opSeq.append( MacroValue( tv: tv) )
            
            // Log debug output
            let auxTxt = getDebugText()
            logAux.debug( "recordValueFn: \(auxTxt)" )
        }
    }
    
}

