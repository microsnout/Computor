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
    
    // Used if recording F1..F6
    var kcFn: KeyCode
    
    var exeflag: Bool
    
    // Context chains to restore to in event of deleting a modal func or close brace
    var rollbackPoints: [SequenceMark]
    
    
    init( exeflag: Bool) {
        self.kcFn = KeyCode.null
        self.exeflag = exeflag
        self.rollbackPoints = []
    }
    
    override var rootClass: ContextRootClass { .Recording }
    
    override func markRollbackPoint( to ctx: EventContext ) {
        
        guard let model = self.model else { return }
        
        // Return to context ctx if we delete recording back to this index
        self.rollbackPoints.append( SequenceMark( context: ctx, index: model.aux.macroRec?.opSeq.count ?? 0 ) )
    }
    
    override func getRollbackPoint() -> SequenceMark? {
        
        guard let model = self.model else { return nil }
        
        let mrIndex = model.aux.macroRec?.opSeq.count ?? -1
        
        if let mark = self.rollbackPoints.first( where: { $0.index == mrIndex } ) {
            
            // Found a valid rollback point, remove from list and return it
            self.rollbackPoints.removeAll(where: { $0.index == mrIndex } )
            return mark
        }
        return nil
    }

    override func onActivate(lastEvent: KeyEvent) {
        
        /// ** On Activate Recording Context **
        
        guard let model = self.model else { return }
        
        if let kc = lastEvent.kcTop {
            
            // Start recording the indicated Fn key
            self.kcFn = kc
            
            model.startRecordingFnKey(kcFn)
        }
        else if lastEvent.kc == .macroRecord {
            
            // Get current macro from macro detail view
            if let mr = model.aux.macroRec {
                
                // Start recording
                model.aux.record(mr)
            }
            else {
                // There must be a valid macroRec when the .macroRecord event is received
                assert(false)
            }
        }
        
        // A Disable
        SubPadSpec.disableAllFnSubmenu( except: self.kcFn )

        // Push a new local variable store
        model.pushLocalVariableFrame()
    }
    
    
    override func onDeactivate(lastEvent: KeyEvent) {
        
        /// ** On Deactivate Recording Context **
        
        guard let model = self.model else { return }
        
        // B Re-enable
        SubPadSpec.enableAllFnSubmenu()
        
        // Remove local variable frame that was added by onActivate
        model.popLocalVariableFrame()
    }
    
    
    override func getDisableSet( topKey: KeyCode ) -> Set<KeyCode> {
        // Disable Rec and Edit
        return [.recFn, .editFn]
    }
    

    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        print( "RecordingContext event: \(event.keyCode)")
#endif
        
        switch event.keyCode {
            
        case .clrFn:
            model.clearRecordingFnKey(kcFn)
            model.popContext( event )
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
            
        case .stopFn:
            model.macroStop()
            return KeyPressResult.macroOp
            
        case .macroStop:
            // Restore normal context
            model.popContext( KeyEvent(.macroStop) )
            return KeyPressResult.macroOp

        case .backUndo:
            guard let mr = model.aux.macroRec else {
                assert(false)
                break
            }
            
            if mr.opSeq.isEmpty {
                
                // Cancel the recording
                model.aux.auxRecorderStop()
                model.popContext( event )
                return KeyPressResult.cancelRecording
            }
            else {
                // First remove last key
                model.recordKeyEvent( event )
                
                if let mark = getRollbackPoint() {
                    
                    // Rollback, put modal function context and block record back
                    model.rollbackContext(to: mark.context)
                }
                
                // Execute the .back command to undo the state
                return model.execute( event )
            }
            
        default:
            
            if KeyCode.entryStartKeys.contains(event.keyCode) {
                
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
            let result = exeflag ? model.execute( event ) : KeyPressResult.noOp
            
            if result != .stateError {
                model.recordKeyEvent( event )
            }
            return result
        }
    }
}


