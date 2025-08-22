//
//  EntryContext.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-03.
//
import SwiftUI

///
/// Entry event context
///
class EntryContext : EventContext {
    
    override func onActivate( lastEvent: KeyEvent ) {
        // Start data entry with a digit or a dot determined by the key that got us here
        model?.entry.startTextEntry( lastEvent.keyCode )
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        if !CalculatorModel.entryKeys.contains(event.keyCode) {
            
            // Return to invoking context, either Normal or Recording
            model.popContext( event )
            
            // Let the newly restored context handle this event
            return KeyPressResult.resendEvent
        }
        
        // Process data entry key event
        let keyRes = model.entry.entryModeKeypress(event.keyCode)
        
        if keyRes == .cancelEntry {
            // Exited entry mode
            // We backspace/undo out of entry mode
            model.popContext( event )
            return KeyPressResult.stateUndo
        }
        
        // Stay in entry mode
        return KeyPressResult.dataEntry
    }
}


