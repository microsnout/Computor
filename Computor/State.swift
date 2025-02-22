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


typealias StateTest = ( _ s0: CalcState) -> Bool

struct RegisterPattern {
    var specList: [RegisterSpec]
    var stateTest: StateTest?
    
    init( _ specList: [RegisterSpec], _ stateTest: StateTest? = nil) {
        self.specList = specList
        self.stateTest = stateTest
    }
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
    
    mutating func setRealValue( reg index: Int = regX, _ value: Double,
                                tag: TypeTag = tagUntyped,
                                fmt: FormatRec = CalcState.defaultDecFormat ) {
        stack[index].value.setShape(1)
        stack[index].value.vtp = .real
        stack[index].value.reg = value
        stack[index].value.tag = tag
        stack[index].value.fmt = fmt
    }

    mutating func setVectorValue( reg index: Int = regX, _ x: Double, _ y: Double,
                                  tag: TypeTag = tagUntyped,
                                  fmt: FormatRec = CalcState.defaultDecFormat ) {
        stack[index].value.setShape(2)
        stack[index].value.vtp = .vector
        stack[index].value.set2(x,y)
        stack[index].value.tag = tag
        stack[index].value.fmt = fmt
    }

    mutating func setPolarValue( reg index: Int = regX, _ r: Double, _ w: Double,
                                 tag: TypeTag = tagUntyped,
                                 fmt: FormatRec = CalcState.defaultDecFormat )
    {
        stack[index].value.setShape(2)
        stack[index].value.vtp = .polar
        stack[index].value.set2(r,w)
        stack[index].value.tag = tag
        stack[index].value.fmt = fmt
    }

    mutating func setComplexValue( reg index: Int = regX, _ z: Comp,
                                   tag: TypeTag = tagUntyped,
                                   fmt: FormatRec = CalcState.defaultDecFormat )
    {
        stack[index].value.setShape(2)
        stack[index].value.vtp = .complex
        stack[index].value.set2( z.real, z.imaginary )
        stack[index].value.tag = tag
        stack[index].value.fmt = fmt
    }

    mutating func convertX( toTag: TypeTag ) -> Bool {
        if Xvtp != .real {
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
        for spec in pattern.specList {
            switch spec {
                
            case .X( let vt, let vs):
                if !vt.contains(Xvtp) || Xtv.valueShape != vs {
                    return false
                }
                
            case .Y( let vt, let vs):
                if !vt.contains(Yvtp) || Ytv.valueShape != vs {
                    return false
                }
                
            case .Z( let vt, let vs):
                if !vt.contains(Zvtp) || Ztv.valueShape != vs {
                    return false
                }
            }
        }
        
        if let test = pattern.stateTest {
            return test(self)
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
    
    var Xvtp: ValueType {
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
    
    var Yvtp: ValueType {
        get { stack[regY].value.vtp }
        set { stack[regY].value.vtp = newValue }
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
    
    var Zvtp: ValueType {
        get { stack[regZ].value.vtp }
        set { stack[regZ].value.vtp = newValue }
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
