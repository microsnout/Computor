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
    
    var macroIndex  = 0
    
    var nestedBlocks = 0
    var lastOpModal = false
    
    override func onActivate(lastEvent: KeyEvent) {
        guard let model = self.model else { assert(false); return }
        
        // Start recording
        model.aux.recordModalBlock()
        
        // Enable the close brace key on keyboard
        model.kstate.func2R = psFunctions2Rc
    }
    
    
    override func onDeactivate(lastEvent: KeyEvent) {
        // guard let model = self.model else { assert(false); return }
        
        // model.aux.recordModalBlockEnd()
    }
    
    override func getDisableSet( topKey: KeyCode ) -> Set<KeyCode> {
        // Disable Rec and Edit
        return [.clrFn, .recFn, .stopFn, .editFn]
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        guard let mr = model.aux.macroRec else {
            assert(false)
            return KeyPressResult.null
        }
        
#if DEBUG
        print( "BlockRecord event: \(event.keyCode)")
#endif
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .editFn:
            return KeyPressResult.noOp
            
        case .closeBrace:
            // Disable braces
            if nestedBlocks > 0 {
                nestedBlocks -= 1
            }
            else {
                model.kstate.func2R = psFunctions2R
                
                // Restore the modal context and pass the .macro event
                model.saveRollback( to: mr.opSeq.count )
                
                // Pop back to the modal function state
                model.popContext( event )
            }
            
            return KeyPressResult.recordOnly
            
        case .backUndo:
            if mr.opSeq.isEmpty {
                model.kstate.func2R = psFunctions2R
                
                // Cancel both BlockRecord context and the ModalContext that spawned it
                model.popContext( event, runCCC: false )
                model.popContext( event, runCCC: false )
                return KeyPressResult.stateUndo
            }
            else {
                if macroIndex == model.markMacroIndex() {
                    
                    // Remove last key event from recording
                    model.recordKeyEvent( event )
                    
                    // We have deleted the opening brace, return to modal function context
                    model.popContext( event )
                    
                    return KeyPressResult.stateUndo
                }
                else {
                    // Remove last key event from recording
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
                
                lastOpModal = true
                
                // Enable Open Brace
                model.kstate.func2R = psFunctions2Ro
            }
            else if lastOpModal {
                
                if event.kc == .openBrace {
                    
                    nestedBlocks += 1
                }
                
                model.kstate.func2R = psFunctions2Rc
            }
            
            return KeyPressResult.recordOnly
        }
    }
    
    
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
}


