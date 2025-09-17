//
//  NormalContext.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-03.
//
import SwiftUI

///
/// Normal event context
///     Not recording, Not playing back macros, Not in data entry mode
///
class NormalContext : EventContext {
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.keyCode {
            
        case .clrFn:
            // Clear macro assigned to this Fn key
            // Delete macro if symbol tag matches key code
            if let kcFn = event.kcTop {
                
                model.clearRecordingFnKey(kcFn)
            }
            return KeyPressResult.macroOp
            
        case .editFn:
            if let kcFn = event.kcTop {
                
                if let tag = model.kstate.keyMap.tagAssignment(kcFn),
                   let mr = model.aux.macroMod.getMacro(tag) {
                    
                    // This key has a macro sym assigned
                    model.aux.loadMacro(mr)
                }
            }
            return KeyPressResult.macroOp
            
        case .stopFn, .openBrace, .closeBrace:
            return KeyPressResult.noOp
            
        case .recFn:
            if model.kstate.keyMap.isAssigned( event.kcTop ?? .null ) {
                // Already something assigned to this key
                return KeyPressResult.stateError
                // TODO: This is not indicating an error
            }
            fallthrough
                
        case .macroRecord:
            // Record menu from Fn key or record op from macro detail view
            model.pushContext( RecordingContext(), lastEvent: event )
            return KeyPressResult.macroOp
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.keyCode) {
                
                // Start data entry mode, save current state and lift stack to make room for new data
                model.pushState()
                model.state.stackLift()
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.keyCode ==  .back {
                        
                        // Data entry was cancelled by back/undo key
                        model.popState()
                    }
                    else {
                        
                        // Successful data entry, copy to X reg
                        model.acceptTextEntry()
                    }
                }
                
                return KeyPressResult.dataEntry
            }
            
            // Dispatch and execute the entered key
            return model.execute( event )
        }
    }
}

