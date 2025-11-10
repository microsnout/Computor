//
//  Constant.swift
//  Computor
//
//  Created by Barry Hall on 2025-10-23.
//
import Foundation


enum Const {
    
    enum Log {
        static let model = false
    }
    
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
        // Height of of Aux display colored banners
        static let auxFrameHeight = 24.0
        
        // Width of code listing panel in macro detail view
        static let auxCodeListingWidth = 165.0
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
    
    enum Symbol {
        
        static let maxChars = 6
        
        static let charBits = 8
        
        static let superBits = 3
        
        static let superMask: UInt64 = 0x07
        
        static let modBits = 8
        
        static let superShift = Self.maxChars*Self.charBits

        static let subShift = Self.maxChars*Self.charBits + Self.superBits

        static let modShift = Self.maxChars*Self.charBits + 2*Self.superBits
        
        static let byteMask: UInt64 = 0xFF
        
        static let modMask: UInt64 = ~(0xFFFFFFFFFFFFFFFF << Self.modShift)
        
        static let firstCharMask: UInt64 = 0xFF
        
        static let chrMask: UInt64 = ~(0xFFFFFFFFFFFFFFFF << (Self.maxChars*Self.charBits))
    }
}
