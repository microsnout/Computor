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
            if let mr = state.memoryAt( tag: tag ) {
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
        state.memoryAt(tag: tag)
    }
    
    
    func getLocalMacro( _ tag: SymbolTag ) -> MacroRec? {
        activeModule.getLocalMacro(tag)
    }
    
    
    func newGlobalMemory( _ mTag: SymbolTag, caption: String? = nil ) -> MemoryRec {
        
        /// ** New Global Memory **
        /// Creates a new global with provided symbol and caption, value will be 0.0
        /// Does not check for already existing memory with that Symbol !!
        
        let mr = MemoryRec( tag: mTag, caption: caption )
        state.memory.append( mr )
        return mr
    }
    
    
    func changeMemorySymbol( from oldTag: SymbolTag, to newTag: SymbolTag ) {
        
        state.memoryChangeSymbol(from: oldTag, to: newTag)
    }
    
    
    func setMemoryCaption( of memTag: SymbolTag, to cap: String? ) {
        
        state.memorySetCaption( at: memTag, to: cap)
    }
    
    func setMemoryValue( at memTag: SymbolTag, to tv: TaggedValue ) {
        
        state.memorySetValue(at: memTag, to: tv)
    }
    
    
    func storeRegister( _ mTag: SymbolTag, _ tv: TaggedValue ) {
        
        if mTag.isLocalMemoryTag {
            
            if let lvf = currentLVF {
                
                // Local block {..} memory
                lvf.local[mTag] = tv
            }
        }
        else {
            // Global memory
            
            if currentLVF == nil {
                // Only push the state if not running or recording a macro
                // Running or recording will push the state before the operation
                pushState()
            }
            
            if let index = state.memory.firstIndex( where: { $0.symTag == mTag }) {
                
                // Existing global memory
                state.memory[index].tv = tv
                changed()
            }
            else {
                // New global memory
                let mr   = newGlobalMemory( mTag )
                mr.tv = tv
                changed()
            }
            
            if currentLVF == nil {
                // Scroll aux display to memory list
                // Don't change the view unless top level key press
                aux.activeView = .memoryView
            }
        }
    }
    
    
    func rclLocalMemory( _ mTag: SymbolTag ) -> TaggedValue? {
        
        if mTag.isLocalMemoryTag {
            
            // Local memory tag recall
            var lvfOptional = currentLVF
            
            while let lvf = lvfOptional {
                
                if let val = lvf.local[mTag] {
                    
                    // Local block memory found
                    return val
                }
                
                lvfOptional = lvf.prevLVF
            }
            
            return nil
        }
        
        assert(false)
        return untypedZero
    }
    
}
