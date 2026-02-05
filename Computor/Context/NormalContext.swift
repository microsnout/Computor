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
    
    var activeMarks: Int = 0
    
    override func getDisableSet( topKey: KeyCode ) -> Set<KeyCode> {
        
        guard let model = self.model else { return [] }
        
        // Always disable Stop in normal context - only Record context enables
        var disableSet: Set<KeyCode> = [.stopFn]
        
        if let tag = model.kstate.keyMap.tagAssignment(topKey),
           let (_, _) = model.getMacroFunction(tag) {
            
            // Disable Rec if there is already a macro - must Clear first
            disableSet.insert(.recFn)
        }
        else {
            // No macro exists, cannot Edit or Clear it
            disableSet.insert(.clrFn)
            disableSet.insert(.editFn)
        }

        return disableSet
    }

    
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
                
                let mod0 = model.db.getModZero()
                
                if let tag = model.kstate.keyMap.tagAssignment(kcFn),
                   let (mr, mfr) = model.db.getMacro( for: tag, localMod: mod0) {
                    
                    // This key has a macro sym assigned
                    model.aux.macroMod = mfr
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
            model.pushContext( RecordingContext( exeflag: true ), lastEvent: event )
            return KeyPressResult.macroOp
            
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
                    }
                }
                
                return KeyPressResult.dataEntry
            }
            
            // Dispatch and execute the entered key
            return model.execute( event )
        }
    }
}

