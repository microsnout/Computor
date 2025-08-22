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
        
        switch event.keyTag.kc {
            
        case .clrFn:
            // Clear macro assigned to this Fn key
            // Delete macro if symbol tag matches key code
            
            if let kcFn = event.kcTop {
                
                // Lookup macro assigned to this key
                if let tag = model.kstate.keyMap.tagAssignment(kcFn) {
                    
                    guard let fnTag = SymbolTag.getFnSym(kcFn) else {
                        // There must be a tag representing this kc because we only get here by pressing F1..F6
                        assert(false)
                        return KeyPressResult.macroOp
                    }
                    
                    if tag == fnTag {
                        
                        // Macro assigned to this key has symbol matching key - delete it
                        model.clearMacroFunction(tag)
                    }
                    
                    // Remove the key mapping for this key
                    model.kstate.keyMap.clearKeyAssignment(kcFn)
                }
            }
            return KeyPressResult.macroOp
            
        case .editFn:
            if let kcFn = event.kcTop {
                
                if let tag = model.kstate.keyMap.tagAssignment(kcFn),
                   let mr = model.macroMod.getMacro(tag) {
                    
                    // This key has a macro sym assigned
                    model.aux.loadMacro(mr)
                }
            }
            return KeyPressResult.macroOp
            
        case .stopFn, .openBrace, .closeBrace:
            return KeyPressResult.noOp
            
        case .recFn, .macroRecord:
            // Record menu from Fn key or record op from macro detail view
            model.pushContext( RecordingContext(), lastEvent: event )
            return KeyPressResult.macroOp
            
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
                    }
                }
                
                return KeyPressResult.dataEntry
            }
            
            // Dispatch and execute the entered key
            return model.execute( event )
        }
    }
}

