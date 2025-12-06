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
