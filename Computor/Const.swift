//
//  Constant.swift
//  Computor
//
//  Created by Barry Hall on 2025-10-23.
//
import Foundation


enum Const {
    
    enum Str {
        // Text strings used in UI
        
        static let appName = "Computor"
        
        static let record = "ç{StatusRedText}RECç{}"
    }
    
    enum Model {
        // Specifications for CalculatorModel
        
        static let stackSize = 16
    }
    
    enum Limit {
        // Upper or Lower limits
        
        static let modNameLen = 6
    }
    
    enum UI {
        static let auxFrameHeight = 24.0
    }
    
    enum Placeholder {
        static let caption = "ç{GrayText}-caption-ç{}"
    }
    
    enum Icon {
        // System Names from SF Symbols app
        
        static let document = "candybarphone"
        
        static let bulletList = "list.bullet"
        static let gridList   = "square.grid.2x2"
        
        static let chevronDn = "chevron.down"
        static let chevronUp = "chevron.up"
        
        // ** Unused **
        static let detail = "list.bullet.circle"
        static let gridBox = "square.grid.3x3.square"
    }
    
    enum LibMod {
        // System Library module codes - not for User modules
        
        static let stdlib = SymbolTag.firstSysMod + 0
    }
}
