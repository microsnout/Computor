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
            
            // Push a new local variable store
            model.currentLVF = LocalVariableFrame( model.currentLVF )
        }
        else if lastEvent.kc == .macroRecord {
            
            // Get unnamed macro if there is one
            if let mr = model.macroMod.getMacro( SymbolTag(.null) ) {
                
                // Start recording unnamed macro
                model.aux.record(mr)
            }
            else {
                // Create new macro rec
                let mr = MacroRec()
                model.macroMod.saveMacro(mr)
                model.aux.record(mr)
            }
            
            
            // Push a new local variable store
            model.currentLVF = LocalVariableFrame( model.currentLVF )
        }
    }
    
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        print( "RecordingContext event: \(event.keyTag)")
#endif
        
        switch event.keyTag.kc {
            
        case .clrFn:
            model.clearMacroFunction( SymbolTag(kcFn) )
            model.aux.recordStop()
            model.popContext( event )
            
            // Pop the local variable storage, restoring prev
            model.currentLVF = model.currentLVF?.prevLVF
            return KeyPressResult.cancelRecording
            
        case .editFn, .recFn, .openBrace, .closeBrace:
            return KeyPressResult.noOp
            
        case .F1, .F2, .F3, . F4, .F5, .F6:
            if model.isRecordingKey(event.keyTag.kc) {
                
                // Consider this fn key a stopFn command
                fallthrough
            }
            else if model.macroMod.getMacro( event.keyTag ) == nil {
                
                // No op any undefined keys
                return KeyPressResult.noOp
            } else {
                
                model.recordKeyEvent( event )
                return model.execute( event )
            }
            
        case .stopFn, .macroStop:
            model.saveConfiguration()
            model.aux.recordStop()
            model.popContext( event )
            
            // Pop the local variable storage, restoring prev
            model.currentLVF = model.currentLVF?.prevLVF
            return KeyPressResult.macroOp
            
        case .back:
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
            
            if CalculatorModel.entryStartKeys.contains(event.keyTag.kc) {
                
                // Start data entry mode, save current state and lift stack to make room for new data
                model.pushState()
                model.state.stackLift()
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.keyTag.kc ==  .back {
                        
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


