//
//  Memory.swift
//  Computor
//
//  Created by Barry Hall on 2026-01-02.
//

import SwiftUI

extension CalculatorModel {
    
    
    func memoryOp( key: KeyCode, tag: SymbolTag ) {
        pushState()
        acceptTextEntry()
        
        // Leading edge swipe operations
        switch key {
            
        case .rclMem:
            if let mr = state.memoryAt( at: tag ) {
                state.stackLift()
                state.Xtv = mr.tv
            }
            
        case .stoMem:
            setMemoryValue( at: tag, to: state.Xtv )
            
        case .mPlus:
            if let index = state.memoryIndex( at: tag ) {
                if state.Xt == state.memory[index].tv.tag {
                    state.memory[index].tv.reg += state.X
                }
            }
            
        case .mMinus:
            if let index = state.memoryIndex( at: tag ) {
                if state.Xt == state.memory[index].tv.tag {
                    state.memory[index].tv.reg -= state.X
                }
            }
            
        default:
            break
        }
        
        changed()
    }
    
    
    func deleteMemoryRecords( set: SymbolSet ) {
        pushState()
        entry.clearEntry()
        state.deleteMemoryRecords( tags: set )
        changed()
    }
    
    
    // *** Memory Helper functions
    
    func getMemory( _ tag: SymbolTag ) -> MemoryRec? {
        state.memoryAt( at: tag)
    }
    
    
    func newGlobalMemory( _ mTag: SymbolTag, caption: String? = nil ) -> MemoryRec {
        
        /// ** New Global Memory **
        /// Creates a new global with provided symbol and caption, value will be 0.0
        /// Does not check for already existing memory with that Symbol !!
        
        let mr = MemoryRec( tag: mTag, caption: caption )
        state.memory.append( mr )
        setDependencyList(mr)
        return mr
    }
    
    
    func changeMemorySymbol( from oldTag: SymbolTag, to newTag: SymbolTag ) {
        
        state.memoryChangeSymbol(from: oldTag, to: newTag)
        
        if let mr = getMemory(newTag) {
            setDependencyList(mr)
        }
    }
    
    
    func setMemoryCaption( of memTag: SymbolTag, to cap: String? ) {
        
        state.memorySetCaption( at: memTag, to: cap)
    }
    
    
    func setMemoryValue( at memTag: SymbolTag, to tv: TaggedValue ) {
        
        // Change memory in current state
        state.memorySetValue(at: memTag, to: tv)
        
        // Mark document as changed
        changed()
        
        // Update any dependant computed memories
        if let mr = getMemory(memTag) {
            
            for upTag in mr.updateSeq {
                
                if let macro = getLocalMacro(upTag.localTag) {
                    
                    let (result, _) = playMacroSeq( macro.opSeq, in: activeModule )
                    
                    let tv = result == KeyPressResult.stateChange ?  state.Xtv : untypedZero
                    
                    // Restore state of stack
                    popState()
                    
                    setMemoryValue( at: upTag, to: tv )
                }
            }
        }
    }
    
    
    func getMemoryValue( at memTag: SymbolTag ) -> TaggedValue? {
        
        // Recall global memory
        return state.memoryGetValue(at: memTag)
    }
    
    
    func setDependencyList( _ mr: MemoryRec ) {
        
        if mr.symTag.isComputedMemoryTag {
            
            if let macro = getLocalMacro(mr.symTag.localTag) {
                
                for op in macro.opSeq {
                    
                    if let evt = op as? MacroEvent,
                       let tag = evt.event.mTag {
                        
                        if evt.event.kc == .rcl {
                            
                            if let depMem = getMemory(tag) {
                                
                                if depMem.updateSeq.firstIndex( where: { $0 == mr.symTag } ) == nil {
                                    
                                    depMem.updateSeq.append(mr.symTag)
                                }
                            }
                        }
                    }
                }
                
                // Evaluate the new computed memory
                let (result, _) = playMacroSeq( macro.opSeq, in: activeModule )
                let tv = result == KeyPressResult.stateChange ?  state.Xtv : untypedZero
                
                // Restore state of stack
                popState()
                
                setMemoryValue( at: mr.symTag, to: tv )
                
                changed()
                saveDocument()
            }
        }
    }
    
}
