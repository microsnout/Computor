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
                changed()
            }
            
        case .stoMem:
            setMemoryValue( at: tag, to: state.Xtv )
            
        case .mPlus, .mMinus:
            if let index = state.memoryIndex( at: tag ) {
                
                var tvMem = state.memory[index].tv
                
                let sign = key == .mPlus ? 1.0 : -1.0
                
                if let ratio = typeAddable( tvMem.tag, state.Xt) {
                    
                    tvMem.reg += sign * state.X * ratio
                    
                    setMemoryValue( at: tag, to: tvMem )
                }
            }
            
        default:
            // No Op
            break
        }
    }
    
    
    func deleteMemoryRecords( set: SymbolSet ) {
        pushState()
        entry.clearEntry()
        state.deleteMemoryRecords( tags: set )
        refreshAllComputedMemories()
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
        
        state.memoryChangeSymbol( from: oldTag, to: newTag )
        
        refreshAllComputedMemories()
    }
    
    
    func setMemoryCaption( of memTag: SymbolTag, to cap: String? ) {
        
        state.memorySetCaption( at: memTag, to: cap)
    }
    
    
    func setMemoryValue( at memTag: SymbolTag, to tv: TaggedValue ) {
        
        /// ** Set memory Value **
        /// Assign value tv to memory memTag
        
        // Change memory in current state
        state.memorySetValue( at: memTag, to: tv)
        
        // Mark document as changed
        changed()
        
        // Update any dependant computed memories
        let seq = getTopologicalSortSeq( startTags: [memTag] )
        recomputeMemories( updateSeq: seq )
    }
    
    
    func getMemoryValue( at memTag: SymbolTag ) -> TaggedValue? {
        
        // Recall global memory
        state.memoryGetValue( at: memTag)
    }
    
    
    func setDependencyList( _ mr: MemoryRec ) {
        
        if mr.symTag.isComputedMemoryTag {
            
            if let macro = getLocalMacro(mr.symTag.localTag) {
                
                for op in macro.opSeq {
                    
                    if let evt = op as? MacroEvent,
                       let tag = evt.event.mTag {
                        
                        if evt.event.kc == .rcl {
                            
                            if let depMem = getMemory(tag) {
                                
                                if depMem.dependantList.firstIndex( where: { $0 == mr.symTag } ) == nil {
                                    
                                    depMem.dependantList.append(mr.symTag)
                                }
                            }
                        }
                    }
                }
                
                // Evaluate the new computed memory
                let (result, _) = playMacroSeq( macro.opSeq.seq, in: activeModule )
                let tv = result == KeyPressResult.stateChange ?  state.Xtv : untypedZero
                
                // Restore state of stack
                popState()
                
                setMemoryValue( at: mr.symTag, to: tv )
                
                changed()
                saveDocument()
            }
        }
    }
    
    
    
    func getAllMemoryTagsReferenced( by macroTag: SymbolTag ) -> Set<SymbolTag> {
        
        /// ** Get All Memory Tags Refereced **
        /// Recursive search finds all memories referenced directly or indirectly
        
        if let mr = activeModule.getLocalMacro(macroTag) {
            
            var memSet = Set<SymbolTag>( getReferencedMemoryTags( in: mr ) )
            
            for tag in memSet {
                
                if tag.isComputedMemoryTag {
                    
                    // Recursive call to add all memories referenced by this tag
                    let subSet = getAllMemoryTagsReferenced( by: tag)
                    
                    memSet.formUnion(subSet)
                }
            }
            
            return memSet
        }
        else {
            return []
        }
    }
    
    
    func getDependantList( for memTag: SymbolTag ) -> [SymbolTag] {
        
        /// ** Get Dependant List **
        /// Return list of memories that depend on memTag or empty list if invalid tag
        
        getMemory(memTag)?.dependantList ?? []
    }
    
    
    func getReferencedMemoryTags( in mr: MacroRec ) -> [SymbolTag] {
        
        /// ** Get Referenced Memory Tags **
        /// Get a list of all memory tags recalled by this macro
        
        var tagList: [SymbolTag] = []
        
        for op in mr.opSeq {
            
            if let evt = op as? MacroEvent,
               let tag = evt.event.mTag {
                
                if evt.event.kc == .rcl {
                    
                    // Add only Recall references
                    tagList.append(tag)
                }
            }
        }
        
        return tagList
    }
    
    
    func getTopologicalSortSeq( startTags: [SymbolTag] ) -> [SymbolTag] {
        
        /// ** Get Topological Sort Sequence **
        /// Use depth first search to produce a list of computed tags that will evaluate in proper sequence
        
        enum VisitState {
            case unvisited
            case visiting
            case visited
        }
        
        var result: [SymbolTag] = []
        
        var state: [SymbolTag : VisitState] = [:]
        
        
        func dfs( _ node: SymbolTag ) -> Bool {
            
            switch state[node, default: .unvisited] {
                
            case .visiting:
                // Found a cycle
                return false
                
            case .visited:
                return true
                
            case .unvisited:
                break
            }
            
            state[node] = .visiting
            
            let dependants = getDependantList( for: node )
            
            for subNode in dependants {
                if dfs(subNode) == false {
                    return false
                }
            }
            
            // Post order insert
            state[node] = .visited
            result.append(node)
            return true
        }
        
        // Run depth first search from each node in starting tags
        for tag in startTags {
            
            if state[tag, default: .unvisited] == .unvisited {
                if dfs(tag) == false {
                    return []
                }
            }
        }
        
        return result.reversed()
    }
    
    
    func recomputeMemories( updateSeq: [SymbolTag] ) {
        
        /// ** Recompute Memories **
        /// Re-evaluate all the computed memories that were affected by the change
        /// using ordered sequence generated by topological sort algorithm above
        
        for upTag in updateSeq {
            
            if upTag.isComputedMemoryTag {
                if let macro = getLocalMacro(upTag) {
                    
                    let (result, _) = playMacroSeq( macro.opSeq.seq, in: activeModule )
                    
                    let tv = result == KeyPressResult.stateChange ?  state.Xtv : untypedZero
                    
                    // Restore state of stack
                    popState()
                    
                    state.memorySetValue( at: upTag, to: tv)
                }
            }
        }

    }
    
    
    func refreshAllComputedMemories() {
        
        var tagList: [SymbolTag] = []
        
        // Clear all dependant lists and build list of all memory tags
        for memRec in state.memory {
            
            memRec.dependantList.removeAll()
            
            tagList.append(memRec.symTag)
        }
        
        // Re-create all node edges, or dependant lists
        for mr in state.memory {
            
            if mr.symTag.isComputedMemoryTag {
                
                if let macro = getLocalMacro(mr.symTag) {
                    
                    for op in macro.opSeq {
                        
                        if let evt = op as? MacroEvent,
                           let tag = evt.event.mTag {
                            
                            if evt.event.kc == .rcl {
                                
                                if let depMem = getMemory(tag) {
                                    
                                    if depMem.dependantList.contains( mr.symTag ) == false {
                                        
                                        depMem.dependantList.append(mr.symTag)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Do a complete topological sort and then re-eval all computed memories in proper seq
        let sortSeq = getTopologicalSortSeq( startTags: tagList)
        recomputeMemories(updateSeq: sortSeq)
    }
}
