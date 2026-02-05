//
//  Execute.swift
//  Computor
//
//  Created by Barry Hall on 2026-02-05.
//
import SwiftUI


extension CalculatorModel {
    
    
    func execute( _ event: KeyEvent ) -> KeyPressResult {
        
        /// ** Execute **
        ///
        /// Execute provided key event producing key press result
        ///
        
        // Consider state changed if this func is called
        changed()
        
        let keyCode = event.kc
        
        switch keyCode {
            
        case .noop, .noopBrace:
            return KeyPressResult.noOp
            
        case .backUndo:
            // Undo last operation by restoring previous state
            popState()
            return KeyPressResult.stateUndo
            
        case .enter:
            // Push stack up, x becomes entry value
            pushState()
            state.stackLift()
            state.noLift = true
            
        case .fixL:
            var fmt: FormatRec = state.Xtv.fmt
            fmt.digits = max(1, fmt.digits-1)
            state.Xfmt = fmt
            
        case .fixR:
            var fmt: FormatRec = state.Xtv.fmt
            fmt.digits = min(15, fmt.digits+1)
            state.Xfmt = fmt
            
        case .fix:
            pushState()
            state.Xfmt.style = .decimal
            
        case .sci:
            pushState()
            state.Xfmt.style = .scientific
            
        case .clearX:
            // Clear X register
            pushState()
            state.Xtv = untypedZero
            state.noLift = true
            
        case .popX:
            memoryStore( SymbolTag(.X), state.Xtv)
            state.stackDrop()
            
        case .stoX:
            if let mTag = event.mTag {
                memoryStore( mTag, state.Xtv )
            }
            
        case .stoY:
            if let mTag = event.mTag {
                memoryStore( mTag, state.Ytv )
            }
            
        case .stoZ:
            if let mTag = event.mTag {
                memoryStore( mTag, state.Ztv )
            }
            
        case .rcl:
            if let mTag = event.mTag {
                
                // Recall Memory
                if let tv = memoryRecall(mTag) {
                    pushState()
                    state.pushValue(tv)
                }
            }
            
            // Function keys and Unit keys
        case .F1, .F2, .F3, .F4, .F5, .F6, .U1, .U2, .U3, .U4, .U5, .U6:
            
            // Key F1..F6, U1..U6 pressed
            
            if let tag = kstate.keyMap.tagAssignment(keyCode),
               let (mr, mfr) = getMacroFunction(tag) {
                
                // Macro function execution
                var result = KeyPressResult.noOp
                
                // Macro tag assigned to Fn key
                (result, _) = playMacroSeq(mr.opSeq.seq, in: mfr)
                
                if result == KeyPressResult.stateError {
                    return KeyPressResult.stateError
                }
            }
            else {
                // Default Fn, Un functions
                
                if KeyCode.fnSet.contains(keyCode) {
                    // Unassigned Fn keys are no op
                    return KeyPressResult.noOp
                }
                
                if KeyCode.UnSet.contains(keyCode) {
                    // Unassigned Un key is a Unit key
                    if let kc = getDefaultUnitKeycode(keyCode) {
                        let evt = KeyEvent(kc)
                        queueEvent(evt)
                    }
                    return KeyPressResult.noOp
                }
                
                assert(false)
                return KeyPressResult.stateError
            }
            
        case .lib:
            // Macro function execution
            var result = KeyPressResult.noOp
            
            // .lib, Sym code invoked by 'Lib' key or macro
            
            if let tag = event.mTag {
                
                if tag.isUserMod {
                    
                    if let (mr, mfr) = getMacroFunction(tag) {
                        
                        // Macro tag selected from popup
                        (result, _) = playMacroSeq(mr.opSeq.seq, in: mfr)
                    }
                }
                else {
                    
                    // System Library Mod code
                    if let lf = SystemLibrary.getLibFunction( for: tag ) {
                        
                        if !state.patternMatch( lf.regPattern ) {
                            
                            // Stack state not compatible with function
                            displayErrorIndicator()
                            return KeyPressResult.stateError
                        }
                        
                        let (opRes, opState) = lf.libFunc(self)
                        
                        if opRes == KeyPressResult.stateError
                        {
                            displayErrorIndicator()
                            return opRes
                        }
                        
                        if let newState = opState {
                            // Operation returned a new state, push in case of Undo
                            pushState()
                            state = newState
                            autoswitchFixSci()
                            state.noLift = false
                        }
                        return opRes
                    }
                }
            }
            
            if result == KeyPressResult.stateError {
                displayErrorIndicator()
                return KeyPressResult.stateError
            }
            
        default:
            
            // Search for operations matching this key code in the Op Table
            // The origingal dispatch method for simple functions of Real values
            // Functions return either a new state or nil for error conditions
            
            if let op = CalculatorModel.opTable[keyCode] {
                // Transition to new calculator state based on operation
                
                if let newState = op.transition( state ) {
                    // Operation has produced a new state
                    pushState()
                    state = newState
                    state.noLift = false
                    
                    
                    // Successful state change
                    autoswitchFixSci()
                    return KeyPressResult.stateChange
                }
            }
            
            // Search for operations in the Pattern Table
            // which provides pattern matching of parameters and types
            // Operators return both a key press result and a new state if there is one
            // Modal operators like mapX, do not return a new state but this does not
            // indicate an Error
            
            if let patternList = patternTable[keyCode] {
                
                for pattern in patternList {
                    
                    if state.patternMatch(pattern.regPattern) {
                        
                        // Transition to new calculator state based on operation
                        
                        let (opResult, opState): (_: KeyPressResult, _: CalcState?) = pattern.transition(self, state)
                        
                        if let newState = opState {
                            
                            assert( opResult == KeyPressResult.stateChange )
                            
                            pushState()
                            state = newState
                            state.noLift = false
                            
                            // Successful state change
                            autoswitchFixSci()
                            return KeyPressResult.stateChange
                        }
                        
                        if opResult != KeyPressResult.stateError {
                            return opResult
                        }
                        
                        // Fall through to error indication
                    }
                }
            }
            
            if keyCode.isUnit {
                // Attempt conversion of X reg to unit type keyCode
                if let tag = TypeDef.tagFromKeyCode(keyCode)
                {
                    pushState()
                    
                    for pattern in conversionTable {
                        if state.patternMatch(pattern.regPattern) {
                            pushState()
                            
                            if let newState = pattern.convert(state, to: tag) {
                                state = newState
                                state.noLift = false
                                
                                // Successful state change
                                autoswitchFixSci()
                                return KeyPressResult.stateChange
                            }
                        }
                    }
                    
                    if state.convertX( toTag: tag) {
                        // Conversion succeded
                        state.noLift = false
                        
                        // Successful state change
                        autoswitchFixSci()
                        return KeyPressResult.stateChange
                    }
                    else {
                        // else no-op as there was no new state
                        popState()
                    }
                }
            }
            
            displayErrorIndicator()
            return KeyPressResult.stateError
        }
        
        // Successful state change
        autoswitchFixSci()
        return KeyPressResult.stateChange
    }

    
    func autoswitchFixSci() {
        
        /// ** Autoswitch Fix Sci **
        
        // Autoswitch between scientific and decimal
        if state.Xfmt.style == .decimal {
            if abs(state.X) >= 10000000000000.0 {
                state.Xfmt.style = .scientific
            }
        }
        else if state.Xfmt.style == .scientific {
            if abs(state.X) < 1000.0 {
                state.Xfmt.style = .decimal
            }
        }
    }
    
    
    func displayErrorIndicator() {
        
        /// ** Display Error Indicator **
        
        // Display 'error' indicator in primary display
        self.status.error = true
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            // Clear 'error' indication
            self.status.error = false
        }
    }
    
    
    func memoryStore( _ mTag: SymbolTag, _ tv: TaggedValue ) {
        
        /// ** Memory Store **
        
        if mTag.isLocalMemoryTag {
            
            setLocalMemory( tag: mTag, value: tv )
        }
        else {
            // Global memory
            
            if currentLVF == nil {
                // Only push the state if not running or recording a macro
                // Running or recording will push the state before the operation
                pushState()
            }
            
            setMemoryValue(at: mTag, to: tv)
            
            if currentLVF == nil {
                // Scroll aux display to memory list
                // Don't change the view unless top level key press
                aux.activeView = .memoryView
            }
        }
    }
    
    
    func memoryRecall( _ mTag: SymbolTag ) -> TaggedValue? {
        
        /// ** Memory Recall **
        
        if mTag.isLocalMemoryTag {
            
            // Local Memory
            return rclLocalMemory(mTag)
        }
        else {
            
            // Global memory
            return getMemoryValue( at: mTag)
        }
    }
}
