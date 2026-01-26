//
//  PlaybackContext.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-03.
//
import SwiftUI

///
/// Playback Context
///
class PlaybackContext : EventContext {
    
    let opSeq: ArraySlice<MacroOp>
    
    var currentIndex: Int
    
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .editFn:
            return KeyPressResult.noOp
            
        default:
            return model.execute( event )
        }
    }
    
    
    init( _ opSeq: ArraySlice<MacroOp> ) {
        self.opSeq = opSeq
        self.currentIndex = 0
    }
    
    
    func executeSequence() -> (KeyPressResult, Int) {
        
        guard let model = self.model else { return (KeyPressResult.null, 0) }
        
        for (i, op) in opSeq.enumerated() {
            
            self.currentIndex = i
            
            if op.execute(model) == KeyPressResult.stateError {
                
                return (KeyPressResult.stateError, i)
            }
        }
        
        self.currentIndex = 0

        return (KeyPressResult.stateChange, opSeq.count)
    }
}


///
/// Debug Context
///
class DebugContext : EventContext {
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .editFn:
            return KeyPressResult.noOp
            
        default:
            return model.execute( event )
        }
    }
}
