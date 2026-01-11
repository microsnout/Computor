//
//  Constant.swift
//  Computor
//
//  Created by Barry Hall on 2025-10-23.
//
import Foundation


enum Const {
    
    enum Log {
        // Enable or disable model logging
        static let model = true
    }
    
    enum Str {
        // Text strings used in UI
        
        static let appName = "Computor"
        
        static let record = "ç{StatusRedText}RECç{}"
        
        static let debug  = "ç{DebugText}DEBUGç{}"
    }
    
    enum Model {
        // Specifications for CalculatorModel
        
        static let stackSize = 16
        
        // Autosave after this many seconds of inactivity
        static let autosaveInterval = 10
        
        // Send clockTick event every second
        static let clockTick = 1.0
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
        static let xcaption = "-caption-"
    }
    
    enum Icon {
        // System Names from SF Symbols app
        
        static let plus     = "plus"
        static let trash    = "trash"
        static let document = "candybarphone"
        static let chart    = "chart.line.uptrend.xyaxis"
        
        static let bulletList = "list.bullet"
        static let gridList   = "square.grid.2x2"
        
        static let chevronRight = "chevron.right"
        static let chevronLeft  = "chevron.left"
        static let chevronDn    = "chevron.down"
        static let chevronUp    = "chevron.up"

        static let cntlModules  = "document.on.document"
        static let cntlUnits    = "ruler"
        static let cntlSettings = "slider.horizontal.3"
        static let cntlHelp     = "books.vertical"
        static let cntlDebug    = "wrench.and.screwdriver"
        
        // Macro Debug Controls
        static let play         = "play.fill"
        static let stop         = "stop.fill"
        static let record       = "record.circle.fill"
        static let playPause    = "playpause.circle"
        static let stepForward  = "forward.frame"
        static let stepBackward = "backward.frame"
        static let stepUndo     = "arrowshape.turn.up.left"
        static let recExecute   = "play.circle"
        static let recPlay      = "play.fill"
        static let recNoPlay    = "play.slash.fill"

        static let arrowUp      = "arrowshape.up"
        static let arrowDown    = "arrowshape.down"
        static let arrowLeft    = "arrowshape.left"
        static let arrowRight   = "arrowshape.right"

        // ** Unused **
        static let detail = "list.bullet.circle"
        static let gridBox = "square.grid.3x3.square"
        static let expand  = "arrow.down.backward.and.arrow.up.forward"
        static let shrink  = "arrow.down.right.and.arrow.up.left"
    }
    
    enum LibMod {
        // System Library module codes - not for User modules
        
        static let stdlib = SymbolTag.firstSysMod + 0
        static let cntlLib = SymbolTag.firstSysMod + 1
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
