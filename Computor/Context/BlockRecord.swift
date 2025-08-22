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
    var fnRecording = false
    
    override func onActivate(lastEvent: KeyEvent) {
        guard let model = self.model else { assert(false); return }
        
        if model.aux.isRec {
            // Already recording an Fn key
            // Remember that we were recording on enty - record the open brace
            model.aux.recordModal()
            fnRecording = true
        }
        else {
            // Start recording but remember we were not on entry
            fnRecording = false
            model.aux.recordModal()
        }
        
        // Save the starting macro index
        macroIndex = model.markMacroIndex()
        
        // Enable the close brace key on keyboard
        model.kstate.func2R = psFunctions2Rc
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
            
        case .back:
            if mr.opSeq.isEmpty {
                model.kstate.func2R = psFunctions2R
                
                // Cancel both BlockRecord context and the ModalContext that spawned it
                model.aux.modalRecStop()
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
                    
                    if exitEvent.kc != .back {
                        
                        // Grab the entered data value and record it
                        let tv = model.grabTextEntry()
                        model.recordValueEvent( tv )
                    }
                }
                return KeyPressResult.dataEntry
            }
            
            // Record the key event
            model.recordKeyEvent(event)
            return KeyPressResult.recordOnly
        }
    }
    
    
    override func enterValue(_ tv: TaggedValue) {
        
        guard let model = self.model else { return }
        
        model.recordValueEvent(tv)
        model.pushValue(tv)
    }
}


