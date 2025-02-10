//
//  State.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2024-09-28.
//

import Foundation
import OSLog

let logS = Logger(subsystem: "com.microsnout.calculator", category: "state")


// Standard HP calculator registers
let stackPrefixValues = ["X", "Y", "Z", "T", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]

// Register index values
let regX = 0, regY = 1, regZ = 2, regT = 3, stackSize = 16

struct FnRec {
    var caption: String
    var macro: [MacroOp] = []
}


struct CalcState {
    /// Defines the exact state of the calculator at a given time
    ///
    var stack: [NamedValue] = stackPrefixValues.map { NamedValue( $0, value: untypedZero) }
    var lastX: TaggedValue = untypedZero
    var noLift: Bool = false
    var memory = [NamedValue]()
    var fnList: [KeyCode : FnRec] = [:]

    static let defaultDecFormat: FormatRec = FormatRec( style: .decimal, digits: 4 )
    static let defaultSciFormat: FormatRec = FormatRec( style: .scientific, digits: 4 )

    mutating func convertX( toTag: TypeTag ) -> Bool {
        if Xstp != .real {
            // Don't assign units to vectors and complex
            return false
        }
        
        if let seq = unitConvert( from: Xt, to: toTag ) {
            Xtv = TaggedValue( tag: toTag, reg: seq.op(X) )
            return true
        }
        
        // Failed to find conversion
        return false
    }
    
    func patternMatch( _ pattern: RegisterPattern ) -> Bool {
        for spec in pattern {
            switch spec {
                
            case .X( let vt, let vs):
                if Xtv.vtp != vt || Xtv.valueShape != vs {
                    return false
                }
                
            case .Y( let vt, let vs):
                if Ytv.vtp != vt || Ytv.valueShape != vs {
                    return false
                }
                
            case .Z( let vt, let vs):
                if Ytv.vtp != vt || Ytv.valueShape != vs {
                    return false
                }
            }
        }
        return true
    }

    // *** *** ***

    var X: Double {
        get { stack[regX].value.reg }
        set { stack[regX].value.reg = newValue }
    }
    
    var Xt: TypeTag {
        get { stack[regX].value.tag }
        set { stack[regX].value.tag = newValue }
    }
    
    var Xfmt: FormatRec {
        get { stack[regX].value.fmt }
        set { stack[regX].value.fmt = newValue }
    }
    
    var Xtv: TaggedValue {
        get { stack[regX].value }
        set { self.stack[regX].value = newValue }
    }
    
    var Xstp: ValueType {
        get { stack[regX].value.vtp }
        set { stack[regX].value.vtp = newValue }
    }

    var Y: Double {
        get { stack[regY].value.reg }
        set { stack[regY].value.reg = newValue }
    }
    
    var Yt: TypeTag {
        get { stack[regY].value.tag }
        set { stack[regY].value.tag = newValue }
    }
    
    var Yfmt: FormatRec {
        get { stack[regY].value.fmt }
        set { stack[regY].value.fmt = newValue }
    }
    
    var Ytv: TaggedValue {
        get { stack[regY].value }
        set { self.stack[regY].value = newValue }
    }
    
    var Z: Double {
        get { stack[regZ].value.reg }
        set { stack[regZ].value.reg = newValue }
    }
    
    var Zt: TypeTag {
        get { stack[regZ].value.tag }
        set { stack[regZ].value.tag = newValue }
    }
    
    var Zfmt: FormatRec {
        get { stack[regZ].value.fmt }
        set { stack[regZ].value.fmt = newValue }
    }
    
    var Ztv: TaggedValue {
        get { stack[regZ].value }
        set { self.stack[regZ].value = newValue }
    }

    var T: Double {
        get { stack[regT].value.reg }
        set { stack[regT].value.reg = newValue }
    }
    
    mutating func set2( _ v1: Double, _ v2: Double, row: Int = 1, col: Int = 1 ) {
        self.stack[regX].value.set2( v1, v2, row, col)
    }
    
    mutating func setShape( _ ss: Int = 1, rows: Int = 1, cols: Int = 1 ) {
        stack[regX].value.setShape( ss, rows, cols)
    }

    mutating func stackDrop(_ by: Int = 1 ) {
        for rx in regX ..< stackSize-1 {
            self.stack[rx].value = self.stack[rx+1].value
        }
    }

    mutating func stackLift(_ by: Int = 1 ) {
        if self.noLift {
            logM.debug("stackLift: No-op")
            self.noLift = false
            return
        }
        
        logM.debug("stackLift: LIFT")
        for rx in stride( from: stackSize-1, to: regX, by: -1 ) {
            self.stack[rx].value = self.stack[rx-1].value
        }
    }

    mutating func stackRoll() {
        let xtv = self.Xtv
        stackDrop()
        let last = stackSize-1
        self.stack[last].value = xtv
    }
}
