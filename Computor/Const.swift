//
//  Constant.swift
//  Computor
//
//  Created by Barry Hall on 2025-10-23.
//
import Foundation


enum Const {
    
    enum Str {
        
        static let appName = "Computor"
        
        static let record = "ç{StatusRedText}RECç{}"
    }
    
    enum Model {
        
        static let stackSize = 16
    }
    
    enum Limit {
        static let modNameLen = 6
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
}
