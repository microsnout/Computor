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
    
    var openCount   = 0
    var macroIndex  = 0
    
    override func onActivate(lastEvent: KeyEvent) {
        guard let model = self.model else { assert(false); return }
        
        // Start recording 
        model.aux.recordModalBlock()
       
        // Save the starting macro index
        macroIndex = model.markMacroIndex()
        
        // Enable the close brace key on keyboard
        model.kstate.func2R = psFunctions2Rc
    }
    
    
    override func onDeactivate(lastEvent: KeyEvent) {
        guard let model = self.model else { assert(false); return }
        
        model.aux.recordModalBlockEnd()
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
            
        case .openBrace:
            openCount += 1
            model.recordKeyEvent(event)
            return KeyPressResult.recordOnly
            
        case .closeBrace:
            // Disable braces
            model.kstate.func2R = psFunctions2R
            
            if openCount == 0 {
                // Restore the modal context and pass the .macro event
                model.saveRollback( to: mr.opSeq.count )
                
                // Pop back to the modal function state
                model.popContext( event )
                return KeyPressResult.recordOnly
            }
            
            openCount -= 1
            
            // Record the close brace and continue
            model.recordKeyEvent(event)
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
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
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
            return KeyPressResult.recordOnly
        }
    }
    
    
    override func enterValue(_ tv: TaggedValue) {
        
        guard let model = self.model else { return }
        
        model.recordValueEvent(tv)
        model.pushValue(tv)
    }
}


