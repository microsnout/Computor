//
//  ModalContext.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-03.
//
import SwiftUI

///
/// Modal Context
///     For modal functions like map and reduce, to wait for a function parameter, either single key or { }
///
class ModalContext : EventContext {
    
    var withinRecContext = false
    
    // String to display while modal function is active
    var statusString: String? { nil }
    
    var macroFn: MacroOpSeq = MacroOpSeq()
    
    override func onActivate( lastEvent: KeyEvent) {
        if let model = self.model {
            // We could be used within a recording context or a normal context
            withinRecContext = model.previousContext is RecordingContext
            
            // Enable the open brace key on keyboard
            model.kstate.func2R = psFunctions2Ro
        }
    }
    
    // Key event handler for modal function
    func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        return KeyPressResult.null
    }
    
    func runMacro( model: CalculatorModel ) -> KeyPressResult {
        
        logM.debug( "Run Macro: \(String( describing: self.macroFn.getDebugText() ))")
        
        // Push a new local variable store
        model.currentLVF = LocalVariableFrame( model.currentLVF )
        
        for op in macroFn {
            if op.execute( model ) == KeyPressResult.stateError {
                
                logM.debug( "Run Macro: ERROR")
                
                // Pop the local variable storage, restoring prev
                model.currentLVF = model.currentLVF?.prevLVF
                
                return KeyPressResult.stateError
            }
        }
        
        // Pop the local variable storage, restoring prev
        model.currentLVF = model.currentLVF?.prevLVF
        
        return KeyPressResult.stateChange
    }
    
    func executeFn( _ event: KeyEvent ) -> KeyPressResult {
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        // print( "ModalContext executeFn: \(event.keyCode)")
#endif
        
        switch event.kc {
            
        case .macro:
            return runMacro(model: model)
            
        default:
            return model.keyPress(event)
        }
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        print( "ModalContext event: \(event.keyCode)")
#endif
        
        switch event.kc {
            
        case .openBrace:
            // Start recording, don't record the open brace at top level
            if withinRecContext {
                
                // Record the open brace of the block
                model.recordKeyEvent(event)
                
                // Save start index to recording for extracting block {..}
                let from = model.markMacroIndex()
                
                model.pushContext( BlockRecord(), lastEvent: event ) { endEvent in
                    
                    if endEvent.kc == .back {
                        // We have backspaced the open brace, cancelling the block
                        // Stay in this context and wait for another function
                    }
                    else {
                        // There must be an active macro rec if withinRecContext is true
                        guard let mr = model.aux.macroRec else { assert(false) }
                        
                        // Before recording closing brace, extract the macro
                        self.macroFn = MacroOpSeq( [any MacroOp](mr.opSeq[from...]) )
                        
                        // Now record the closing brace of the block
                        model.recordKeyEvent( endEvent )
                        
                        model.aux.modalRecStop()
                        
                        // Queue a .macro event to execute it
                        model.queueEvent( KeyEvent(.macro) )
                    }
                }
                return KeyPressResult.recordOnly
            }
            else {
                // Recording block {..} from normal context
                
                model.pushContext( BlockRecord(), lastEvent: event ) { _ in
                    
                    guard let mr = model.aux.macroRec else { assert(false) }
                    
                    // Capture the block macro
                    self.macroFn = mr.opSeq
                    
                    // Stop recording the Block {}
                    model.aux.modalRecStop()
                    
                    // Queue a .macro event to execute it
                    model.queueEvent( KeyEvent(.macro) )
                }
                return KeyPressResult.stateChange
            }
            
        case .back:
            // Disable braces
            model.kstate.func2R = psFunctions2R
            
            // Restore the Normal context
            model.popContext( event )
            
            model.popState()
            
            return KeyPressResult.stateUndo
            
            
        default:
            // Disable braces
            model.kstate.func2R = psFunctions2R
            
            // Check for single key function (not a block) within a recording context
            if event.kc != .macro && model.previousContext is RecordingContext {
                
                // We are recording so the macro rec must exist
                guard let mr = model.aux.macroRec else { assert(false) }
                
                // Save rollback point in case the single key func is backspaced
                model.saveRollback( to: mr.opSeq.count )
                
                // Record the key
                model.recordKeyEvent( event )
            }
            
            // Restore either the Normal context before executing the function
            model.popContext( event )
            
            // Save the calc state in case modalExecute returns error
            model.pushState()
            
            model.pauseUndoStack()
            model.pauseRecording()
            
            // ModalExecute runs with Undo stack paused
            let result =  modalExecute( event )
            
            if result == .stateError {
                model.popState()
            }
            
            model.resumeRecording()
            model.resumeUndoStack()
            model.autoswitchFixSci()
            return result
        }
    }
    
    override func onModelSet() {
        // Display status string while in modal state
        model?.status.statusMid = statusString
    }
    
    override func onDeactivate( lastEvent: KeyEvent ) {
        // Remove status string
        model?.status.statusMid = nil
    }
}


class ModalConfirmationContext: EventContext {
    
    var prompt: String
    
    var regLabels: [String]?

    var block: ( _ model: CalculatorModel ) -> KeyPressResult
    
    init( prompt: String, regLabels: [String]?, block: @escaping ( _ : CalculatorModel ) -> KeyPressResult ) {
        self.prompt = prompt
        self.regLabels = regLabels
        self.block = block
    }

    var statusString: String? { self.prompt }

    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        print( "ModalConfirmation event: \(event.keyCode)")
#endif
        
        switch event.kc {
            
        case .enter:
            model.popContext( event )
            let result = self.block(model)
            return result
            
        default:
            // Return to invoking context
            model.popContext( event )
            
            // Let the newly restored context handle this event
            return KeyPressResult.resendEvent
        }
    }


    override func onModelSet() {
        
        guard let model = self.model else { assert(false); return }
        
        // Display status string while in modal state
        model.status.statusMid = statusString
        
        if let labels = regLabels {
            model.status.setRegisterLabels(labels)
        }
    }
    
    override func onDeactivate( lastEvent: KeyEvent ) {
        
        guard let model = self.model else { assert(false); return }
        
        // Remove status string
        model.status.statusMid = nil
        model.status.clearRegisterLabels()
    }
}
