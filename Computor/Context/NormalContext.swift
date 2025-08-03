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
            if let kcFn = event.kcTop {
                model.clearMacroFunction( SymbolTag(kcFn) )
                model.aux.clearMacroState()
            }
            return KeyPressResult.macroOp
            
        case .showFn:
            if let kcFn = event.kcTop {
                if let mr = model.macroMod.getMacro( SymbolTag(kcFn) ) {
                    model.aux.macroRec = mr
                    model.aux.activeView = .macroList
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

