//
//  RecordingContext.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-03.
//
import SwiftUI


///
/// Recording Context
///
class RecordingContext : EventContext {
    
    var kcFn = KeyCode.null
    
    override func onActivate(lastEvent: KeyEvent) {
        
        guard let model = self.model else { return }
        
        if let kcFn = lastEvent.kcTop {
            
            // Start recording the indicated Fn key
            self.kcFn = kcFn
            
            model.startRecordingFnKey(kcFn)
        }
        else if lastEvent.kc == .macroRecord {
            
            // Get current macro from macro detail view
            if let mr = model.aux.macroRec {
                
                // Start recording
                model.aux.record(mr, in: model.aux.macroMod)
            }
            else {
                // There must be a valid macroRec when the .macroRecord event is received
                assert(false)
            }
        }
        
        // Push a new local variable store
        model.currentLVF = LocalVariableFrame( model.currentLVF )
    }
    
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        print( "RecordingContext event: \(event.keyCode)")
#endif
        
        switch event.keyCode {
            
        case .clrFn:
            model.aux.recordStop()
            model.clearRecordingFnKey(kcFn)
            model.popContext( event )
            
            // Pop the local variable storage, restoring prev
            model.currentLVF = model.currentLVF?.prevLVF
            return KeyPressResult.cancelRecording
            
        case .editFn, .recFn, .openBrace, .closeBrace:
            return KeyPressResult.noOp
            
        case .F1, .F2, .F3, . F4, .F5, .F6:
            if model.isRecordingKey(event.keyCode) {
                
                // Consider this fn key a stopFn command
                fallthrough
            }
            else if !model.kstate.keyMap.isAssigned(event.keyCode) {
                
                // No op any undefined keys
                return KeyPressResult.noOp
            } else {
                
                model.recordKeyEvent( event )
                return model.execute( event )
            }
            
        case .stopFn, .macroStop:
            model.aux.macroMod.saveModule()
            model.aux.recordStop()
            model.popContext( event )
            
            // Pop the local variable storage, restoring prev
            model.currentLVF = model.currentLVF?.prevLVF
            return KeyPressResult.macroOp
            
        case .backUndo:
            guard let mr = model.aux.macroRec else {
                assert(false)
                break
            }
            
            if mr.opSeq.isEmpty {
                
                // Cancel the recording
                model.aux.recordStop()
                model.popContext( event )
                
                // Pop the local variable storage, restoring prev
                model.currentLVF = model.currentLVF?.prevLVF
                return KeyPressResult.cancelRecording
            }
            else {
                // First remove last key
                model.recordKeyEvent( event )
                
                if let ctx = model.getRollback( to: mr.opSeq.count ) {
                    
                    // Rollback, put modal function context and block record back
                    model.rollback(ctx)
                }
                
                // Execute the .back command to undo the state
                return model.execute( event )
            }
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.keyCode) {
                
                // Start data entry mode, save current state and lift stack to make room for new data
                model.pushState()
                model.state.stackLift()
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.keyCode ==  .backUndo {
                        
                        // Data entry was cancelled by back/undo key
                        model.popState()
                    }
                    else {
                        // Successful data entry, copy to X reg
                        model.acceptTextEntry()
                        
                        // Record the value and key when returning to a recording context
                        model.recordValueEvent( model.state.Xtv )
                    }
                }
                return KeyPressResult.dataEntry
            }
            
            // Record key and execute it
            let result = model.execute( event )
            if result != .stateError {
                model.recordKeyEvent( event )
            }
            return result
        }
    }
}


