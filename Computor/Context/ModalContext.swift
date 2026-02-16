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
    
    var macroFn: ArraySlice<MacroOp> = ArraySlice<MacroOp>()
    var seqMark: SequenceMark        = SequenceMark()

    // **************************************************************** //


    override func onActivate( lastEvent: KeyEvent) {
        if let model = self.model {
            // We could be used within a recording context or a normal context
            withinRecContext = model.aux.recState.isRecording
            
            // Enable the open brace key on keyboard
            model.kstate.func2R = psFunctions2Ro
        }
    }

    // **************************************************************** //


    override func getDisableSet( topKey: KeyCode ) -> Set<KeyCode> {
        // Disable Rec and Edit
        return [.clrFn, .recFn, .stopFn, .editFn]
    }

    // **************************************************************** //


    // Key event handler for modal function
    func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        return KeyPressResult.null
    }

    // **************************************************************** //

    
    func runMacro( model: CalculatorModel ) -> KeyPressResult {
        
        /// ** Run Macro **
        /// Run the recorded modal macro macroFn {...}
        
        logM.debug( "Run Macro: \(String( describing: self.macroFn ))")
        
        let (result, _) = model.playMacroSeq( macroFn, in: model.currentMEC?.module ?? model.activeModule )
        return result
    }

    // **************************************************************** //

    
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

    // **************************************************************** //

    
    func normalEvent( _ event: KeyEvent ) -> KeyPressResult {
        
        /// ** Normal Event **
        ///
        
        guard let model = self.model else { return KeyPressResult.null }

        switch event.kc {
            
        case .openBrace:
            // Recording block {..} from normal context
            
            let mark = model.getSequenceMark()
            
            model.pushContext( BlockRecord(), lastEvent: event ) { endEvent in
                
                if endEvent.kc == .backUndo {
                    // We have backspaced the open brace, cancelling the block
                    // Stay in this context and wait for another function
                }
                else {
                    // The block must end on a close brace
                    assert( endEvent.kc == .closeBrace )
                    
                    self.macroFn = model.getModalSequence( from: mark )
                    
                    // Recorde the Close brace after we get the sequence so it is not included
                    model.recordKeyEvent(endEvent)

                    print( "MODAL CAPTURE: \(String( describing: self.macroFn))  from:\(mark.index)" )
                    
                    // Queue a .macro event to execute it
                    model.queueEvent( KeyEvent(.macro) )
                }
            }
            return KeyPressResult.modalFunction
            
        case .backUndo:
            // Disable braces
            model.kstate.func2R = psFunctions2R
            
            // Restore the Normal context
            model.popContext( event )
            
            model.popState()
            return KeyPressResult.stateUndo
            
        case .xy, .yz, .xz:
            // Allow re-arranging registers before modal execution
            return  model.execute( event )
            
        default:
            // Disable braces
            model.kstate.func2R = psFunctions2R
            
            // Restore the Normal context before executing the function
            model.popContext( event )
            
            // Save the calc state in case modalExecute returns error
            model.pushState()
            
            // ModalExecute runs with Undo stack paused
            model.pauseUndoStack()
            let result =  modalExecute( event )
            model.resumeUndoStack()

            if result == .stateError {
                model.popState()
            }
            
            model.autoswitchFixSci()
            return result
        }
    }

    // **************************************************************** //

    
    func playbackEvent( _ event: KeyEvent ) -> KeyPressResult {
        
        /// ** Playback Event **
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .openBrace:
            // Recording block {..} from normal context
            
            // Skip the openning brace
            let mark = model.getSequenceMark( offset: +1 )
            
            model.pushContext( BlockPlayback(), lastEvent: event ) { endEvent in
                
                let endMark = model.getSequenceMark()
                self.macroFn = model.getModalSequence( from: mark, to: endMark )

                print( "MODAL PLAYBACK: \(String( describing: self.macroFn))  from:\(mark.index) to:\(endMark.index)" )

                // Queue a .macro event to execute it
                model.queueEvent( KeyEvent(.macro) )
            }
            return KeyPressResult.stateChange
            
        default:
            // Restore the Normal context before executing the function
            model.popContext( event )
            
            // Save the calc state in case modalExecute returns error
            model.pushState()
            
            // ModalExecute runs with Undo stack paused
            model.pauseUndoStack()
            let result =  modalExecute( event )
            model.resumeUndoStack()
            
            if result == .stateError {
                model.popState()
            }
            
            model.autoswitchFixSci()
            return result
        }
    }

    // **************************************************************** //

    
    func recordingEvent( _ event: KeyEvent ) -> KeyPressResult {
        
        /// ** Recording Event **
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .openBrace:
            // Record the open brace of the block
            model.recordKeyEvent(event)
            
            // Get mark that does not include the open brace
            let mark = model.getSequenceMark()
            
            model.pushContext( BlockRecord(), lastEvent: event ) { endEvent in
                
                if endEvent.kc == .backUndo {
                    // We have backspaced the open brace, cancelling the block
                    // Stay in this context and wait for another function
                }
                else {
                    // Record the close brace of the block
                    model.recordKeyEvent(endEvent)

                    self.macroFn = model.getModalSequence( from: mark )
                    
                    print( "MODAL RECORD: \(String( describing: self.macroFn))  from:\(mark.index)" )
                    // Queue a .macro event to execute it
                    model.queueEvent( KeyEvent(.macro) )
                }
            }
            return KeyPressResult.modalFunction
            
        case .backUndo:
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
            if event.kc != .macro {
                
                // Save rollback point in case the single key func is backspaced
                markRollbackPoint(to: self)
                
                // Record the key
                model.recordKeyEvent( event )
            }

            // Restore the Normal context before executing the function
            model.popContext( event )
            
            // Save the calc state in case modalExecute returns error
            model.pushState()
            
            model.pauseUndoStack()
            let result =  modalExecute( event )
            model.resumeUndoStack()

            if result == .stateError {
                model.popState()
            }
            
            model.autoswitchFixSci()
            return result
        }
    }

    // **************************************************************** //
    
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        /// ** Event override **
        
#if DEBUG
        print( "ModalContext event: \(event.keyCode)")
#endif
        
        switch self.rootClass {
        case .Normal:
            return normalEvent(event)
            
        case .Playback:
            return playbackEvent(event)
            
        case .Recording:
            return recordingEvent(event)
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

    var block: ( _ model: CalculatorModel ) -> OpResult
    
    init( prompt: String, regLabels: [String]?, block: @escaping ( _ : CalculatorModel ) -> OpResult ) {
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
            
            let (opRes,opState) = self.block(model)
            
            if let newState = opState {
                model.pushState()
                model.state = newState
            }
            return opRes
            
        case .xy, .yz, .xz:
            model.pauseUndoStack()
            model.pauseRecording()
            
            // ModalExecute runs with Undo stack paused
            let result =  model.execute( event )
            
            if result == .stateError {
                model.popState()
            }
            
            model.resumeRecording()
            model.resumeUndoStack()
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
