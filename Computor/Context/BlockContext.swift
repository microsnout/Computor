//
//  BlockRecord.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-03.
//
import SwiftUI


///
/// Block Recording context
///     For recording without execution of { block }
///
class BlockRecord : EventContext {
    
    var startIndex  = 0
    
    var nestedBlocks = 0
    var lastOpModal = false

    // **************************************************************** //


    override func onActivate(lastEvent: KeyEvent) {
        guard let model = self.model else { assert(false); return }
        
        // Start recording
        model.aux.recordModalBlock()
        
        // Enable the Close brace to teminate this block
        model.kstate.func2R = psFunctions2Rc
        
        // Remember the start of this block {...
        self.startIndex = model.getMacroIndex()
    }

    // **************************************************************** //

    
    override func onDeactivate(lastEvent: KeyEvent) {
        guard let model = self.model else { assert(false); return }
        
        model.aux.recordModalBlockEnd()
    }

    // **************************************************************** //


    override func getDisableSet( topKey: KeyCode ) -> Set<KeyCode> {
        // Disable Rec and Edit
        return [.clrFn, .recFn, .stopFn, .editFn]
    }

    // **************************************************************** //

    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        /// ** Event override **
        
        guard let model = self.model else { return KeyPressResult.null }
        
        guard let mr = model.aux.macroRec else {
            assert(false)
            return KeyPressResult.null
        }
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .editFn:
            return KeyPressResult.noOp
            
        case .closeBrace:
            // Disable braces
            if nestedBlocks > 0 {
                
                // One less open block
                nestedBlocks -= 1
                
                // Record the nested close brace
                model.recordKeyEvent(event)

                // Keep Close brace enabled
            }
            else {
                // Disable Open and Close brace
                model.kstate.func2R = psFunctions2R
                
                // Restore this block context if we delete back to this point
                markRollbackPoint( to: self )
                
                // Pop back to the modal function state
                model.popContext( event )
            }
            
            return KeyPressResult.recordOnly
            
        case .backUndo:
            if mr.opSeq.isEmpty {
                
                // Disable Open and Close brace
                model.kstate.func2R = psFunctions2R
                
                // Cancel both BlockRecord context and the ModalContext that spawned it
                model.popContext( event, runCCC: false )
                model.popContext( event, runCCC: false )
                return KeyPressResult.stateUndo
            }
            else {
                if startIndex == model.getMacroIndex() {
                    
                    // Remove last key event from recording
                    model.recordKeyEvent( event )
                    
                    // We have deleted the opening brace, return to modal function context
                    model.popContext( event )
                    
                    return KeyPressResult.stateUndo
                }
                else {
                    // Remove last key event from recording
                    if let lastOp = model.getLastOp() {
                        
                        if let lastKey = lastOp as? MacroEvent {
                            
                            switch lastKey.event.kc {
                                
                            case .closeBrace:
                                nestedBlocks += 1
                                lastOpModal = false
                                model.kstate.func2R = psFunctions2Rc

                            case .openBrace:
                                nestedBlocks -= 1
                                lastOpModal = true
                                model.kstate.func2R = psFunctions2Ro

                            case let kc where KeyCode.modalOpSet.contains(kc):
                                lastOpModal = false
                                model.kstate.func2R = psFunctions2Rc

                            default:
                                break
                            }
                        }
                    }
                    
                    // Delete last op
                    model.recordKeyEvent( event )
                    
                    return KeyPressResult.stateUndo
                }
            }
            
        default:
            if KeyCode.entryStartKeys.contains(event.kc) {
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.kc != .backUndo {
                        
                        // Grab the entered data value and record it
                        let tv = model.grabTextEntry()
                        model.recordValueEvent( tv )
                    }
                }
                return KeyPressResult.dataEntry
            }
            
            // Record the key event
            model.recordKeyEvent(event)
            model.aux.refresh.toggle()
            
            if KeyCode.modalOpSet.contains(event.kc) {
                
                // We have recorded a modal key like mapX
                lastOpModal = true
                
                // Enable Open Brace
                model.kstate.func2R = psFunctions2Ro
                
                return KeyPressResult.recordOnly
            }
            
            if lastOpModal && event.kc == .openBrace {
                
                // Found a nested modal block
                nestedBlocks += 1
                
                // Enable Close brace
                model.kstate.func2R = psFunctions2Rc
                
                return KeyPressResult.recordOnly
            }
            
            if lastOpModal {
                // Modal func is a single key not a block
                
                // Enable Close brace
                model.kstate.func2R = psFunctions2Rc
            }
            
            lastOpModal = false
            return KeyPressResult.recordOnly
        }
    }

    // **************************************************************** //

    
    override func enterValue(_ tv: TaggedValue) {
        
        guard let model = self.model else { return }
        
        model.recordValueEvent(tv)
        model.pushValue(tv)
    }
}



class BlockPlayback : EventContext {
    
    var nestedBlocks = 0
    var lastOpModal = false
    
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }

        switch event.kc {
            
        case .closeBrace:
            if nestedBlocks > 0 {
                nestedBlocks -= 1
                lastOpModal = false
            }
            else {
                // Pop back to the modal function state
                model.popContext( event )
            }
            
        case .openBrace:
            if lastOpModal {
                
                // Nested one level deeper
                nestedBlocks += 1
                lastOpModal = false
            }
            
        case let kc where KeyCode.modalOpSet.contains(kc):
            // This is a modal func like map-X
            lastOpModal = true

        default:
            lastOpModal = false
        }
        
        return KeyPressResult.noOp
    }
    
    
    override func enterValue(_ tv: TaggedValue) {
        // Do Nothing here - do not record the value or execute/push it
        // We are just accumulating the block {..} for later execution
    }
}


