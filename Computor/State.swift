//
//  State.swift
//  Computor
//
//  Created by Barry Hall on 2024-09-28.
//

import Foundation
import OSLog

let logS = Logger(subsystem: "com.microsnout.calculator", category: "state")


// Register index values
let regX = 0, regY = 1, regZ = 2, regT = 3, stackSize = 16


typealias StateTest = ( _ s0: CalcState) -> Bool

struct RegisterPattern {
    var specList: [RegisterSpec]
    var stateTest: StateTest?
    
    init( _ specList: [RegisterSpec], _ stateTest: StateTest? = nil) {
        self.specList = specList
        self.stateTest = stateTest
    }
}


// Set to KeyCode for now...
struct SymbolTag: Hashable, Codable, Equatable {
    
    var tag: Int
}


extension SymbolTag {
    var kc: KeyCode { KeyCode(rawValue: tag) ?? KeyCode.noop }
    
    var isNull: Bool { self.kc == .null }
    
    var isSingleChar: Bool { tag < 1000 }
    
    func getSymbolText( symName: String, subPt: Int, superPt: Int ) -> String {
        
        let symN = symName.count
        let symA = Array(symName)
        
        if symN == 0 {
            // Placeholder text
            return "ç{GrayText}---"
        }
        
        if symN == 1 || (subPt == 0 && superPt == 0) {
            // No sub or superscripts
            return symName
        }
        
        if symN == 2 {
            assert( (subPt*superPt == 0) && (subPt+superPt == 2) )
            
            let op = subPt > 0 ? "_" : "^"
            
            return "\(symA[0])\(op){\(symA[1])}"
        }
        
        if symN == 3 {
            assert( (subPt*superPt == 0) && (subPt+superPt >= 2) )
            
            // Sub or Super operator and starting point
            let op = subPt > 0 ? "_" : "^"
            let pt = subPt + superPt
            
            // Sub or superscript point starting at position 2 or 3
            return pt == 2 ? "\(symA[0])\(op){\(symA[1])\(symA[2])}" : "\(symA[0])\(symA[1])\(op){\(symA[2])}"
        }
        
        // Invalid
        assert(false)
        return ""
    }
    
    func getSymSpecs() -> ( String, [KeyCode], Int, Int ) {
        
        if isNull {
            return ( "", [], 0, 0 )
        }
        
        if isSingleChar {
            let s = kc.str
            return ( String(s), [kc], 0, 0 )
        }
        else {
            var code = tag
            var symS = ""
            var kcA: [KeyCode] = []
            
            for _ in 1...3 {
                let y = code % 1000
                
                if y != 0 {
                    guard let kc = KeyCode( rawValue: y) else { assert(false) }
                    symS.append( kc.str )
                    kcA.append( kc )
                }
                
                code /= 1000
            }
            
            let superPt: Int = code % 10
            let subPt: Int   = code / 10
            
            return (symS, kcA, subPt, superPt)
        }
    }

    func getRichText() -> String {
        
        if isNull {
            return ""
        }
        
        if isSingleChar {
            let s = kc.str
            return s
        }
        else {
            var code = tag
            var symS = ""
            
            for _ in 1...3 {
                let y = code % 1000
                
                if y != 0 {
                    guard let kc = KeyCode( rawValue: y) else { assert(false) }
                    symS.append( kc.str )
                }
                
                code /= 1000
            }
            
            let superPt: Int = code % 10
            let subPt: Int   = code / 10
            
            return getSymbolText(symName: symS, subPt: subPt, superPt: superPt)
        }
    }
    
    init( _ kc: KeyCode = .null ) {
        
        if let fnTag = SymbolTag.getFnSym(kc) {
            
            self.tag = fnTag.tag
        }
        else {
            
            self.tag = kc.rawValue
        }
    }

    init( _ symA: [KeyCode], subPt: Int = 0, superPt: Int = 0 ) {
        assert( symA.count > 0 && symA.count <= 3 && subPt*superPt == 0 && subPt+superPt <= 3 && subPt+superPt != 1 )
        
        var tag: Int = 0
        var mul: Int = 1

        for kc in symA {
            
            tag += kc.rawValue * mul
            mul *= 1000
        }
        
        tag += (subPt*10 + superPt) * 1000000000
        
        self.tag = tag
    }
    
    // ******
    
    static var fnSym: [ KeyCode : SymbolTag ] = [
        .F1 : SymbolTag( [.F, .d1]),
        .F2 : SymbolTag( [.F, .d2]),
        .F3 : SymbolTag( [.F, .d3]),
        .F4 : SymbolTag( [.F, .d4]),
        .F5 : SymbolTag( [.F, .d5]),
        .F6 : SymbolTag( [.F, .d6]),
    ]
    
    static func getFnSym( _ kc: KeyCode ) -> SymbolTag? {
        SymbolTag.fnSym[kc]
    }
}


struct CalcState: Codable {
    /// Defines the exact state of the calculator at a given time
    ///
    var stack  = [TaggedValue]( repeating: untypedZero, count: stackSize )
    var lastX  = untypedZero
    var noLift = false
    var memory = [MemoryRec]()
}


extension CalcState {

    static let defaultDecFormat: FormatRec = FormatRec( style: .decimal, digits: 4 )
    static let defaultSciFormat: FormatRec = FormatRec( style: .scientific, digits: 4 )
    
    func memoryAt( index: Int ) -> MemoryRec? {
        guard index >= 0 && index < memory.count else {
            return nil
        }
        return memory[index]
    }
    
    func memoryIndex( at tag: SymbolTag ) -> Int? {
        return memory.firstIndex( where: { tag == $0.tag })
    }
    
    func memoryAt( tag: SymbolTag ) -> MemoryRec? {
        return memory.first( where: { tag == $0.tag } )
    }
    
    mutating func memorySetValue( at tag: SymbolTag, _ tv: TaggedValue ) {
        
        if let index = memoryIndex(at: tag) {
            // Modify existing memory
            memory[index].tv = tv
        }
        else {
            // Add new memory
            memory.append( MemoryRec( tag: tag, tv: tv ) )
        }
    }

    mutating func memorySetCaption( at tag: SymbolTag, _ str: String ) {
        
        if let index = memoryIndex(at: tag) {
            // Modify existing memory
            memory[index].caption = str
        }
    }
    
    mutating func setRealValue( reg index: Int = regX, _ value: Double,
                                tag: TypeTag = tagUntyped,
                                fmt: FormatRec = CalcState.defaultDecFormat ) {
        stack[index].setShape(1)
        stack[index].vtp = .real
        stack[index].reg = value
        stack[index].tag = tag
        stack[index].fmt = fmt
    }

    mutating func setVectorValue( reg index: Int = regX, _ x: Double, _ y: Double,
                                  tag: TypeTag = tagUntyped,
                                  fmt: FormatRec = CalcState.defaultDecFormat ) {
        stack[index].setShape(2)
        stack[index].vtp = .vector
        stack[index].set2(x,y)
        stack[index].tag = tag
        stack[index].fmt = fmt
    }

    mutating func setVector3DValue( reg index: Int = regX, _ x: Double, _ y: Double, _ z: Double,
                                    tag: TypeTag = tagUntyped,
                                    fmt: FormatRec = CalcState.defaultDecFormat ) {
        stack[index].setShape(3)
        stack[index].vtp = .vector3D
        stack[index].set3(x,y,z)
        stack[index].tag = tag
        stack[index].fmt = fmt
    }

    mutating func setPolarValue( reg index: Int = regX, _ r: Double, _ w: Double,
                                 tag: TypeTag = tagUntyped,
                                 fmt: FormatRec = CalcState.defaultDecFormat )
    {
        stack[index].setShape(2)
        stack[index].vtp = .polar
        stack[index].set2(r,w)
        stack[index].tag = tag
        stack[index].fmt = fmt
    }

    mutating func setComplexValue( reg index: Int = regX, _ z: Comp,
                                   tag: TypeTag = tagUntyped,
                                   fmt: FormatRec = CalcState.defaultDecFormat )
    {
        if z.imaginary == 0 {
            // Reduce to a real type
            setRealValue( z.real, tag: tag, fmt: fmt)
        }
        else {
            stack[index].setShape(2)
            stack[index].vtp = .complex
            stack[index].set2( z.real, z.imaginary )
            stack[index].tag = tag
            stack[index].fmt = fmt
        }
    }

    mutating func setSphericalValue( reg index: Int = regX, _ r: Double, _ w: Double, _ p: Double,
                                     tag: TypeTag = tagUntyped,
                                     fmt: FormatRec = CalcState.defaultDecFormat )
    {
        stack[index].setShape(3)
        stack[index].vtp = .spherical
        stack[index].set3(r,w,p)
        stack[index].tag = tag
        stack[index].fmt = fmt
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
                if !vt.contains(Xvtp) ||  (vs != .any &&  Xtv.valueShape != vs) {
                    return false
                }
                
            case .Y( let vt, let vs):
                if !vt.contains(Yvtp) || (vs != .any &&  Ytv.valueShape != vs) {
                    return false
                }
                
            case .Z( let vt, let vs):
                if !vt.contains(Zvtp) || (vs != .any &&  Ztv.valueShape != vs) {
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
        get { stack[regX].reg }
        set { stack[regX].reg = newValue }
    }
    
    var Xt: TypeTag {
        get { stack[regX].tag }
        set { stack[regX].tag = newValue }
    }
    
    var Xfmt: FormatRec {
        get { stack[regX].fmt }
        set { stack[regX].fmt = newValue }
    }
    
    var Xtv: TaggedValue {
        get { stack[regX] }
        set { self.stack[regX] = newValue }
    }
    
    var Xvtp: ValueType {
        get { stack[regX].vtp }
        set { stack[regX].vtp = newValue }
    }

    var Y: Double {
        get { stack[regY].reg }
        set { stack[regY].reg = newValue }
    }
    
    var Yt: TypeTag {
        get { stack[regY].tag }
        set { stack[regY].tag = newValue }
    }
    
    var Yfmt: FormatRec {
        get { stack[regY].fmt }
        set { stack[regY].fmt = newValue }
    }
    
    var Ytv: TaggedValue {
        get { stack[regY] }
        set { self.stack[regY] = newValue }
    }
    
    var Yvtp: ValueType {
        get { stack[regY].vtp }
        set { stack[regY].vtp = newValue }
    }

    var Z: Double {
        get { stack[regZ].reg }
        set { stack[regZ].reg = newValue }
    }
    
    var Zt: TypeTag {
        get { stack[regZ].tag }
        set { stack[regZ].tag = newValue }
    }
    
    var Zfmt: FormatRec {
        get { stack[regZ].fmt }
        set { stack[regZ].fmt = newValue }
    }
    
    var Ztv: TaggedValue {
        get { stack[regZ] }
        set { self.stack[regZ] = newValue }
    }
    
    var Zvtp: ValueType {
        get { stack[regZ].vtp }
        set { stack[regZ].vtp = newValue }
    }

    var T: Double {
        get { stack[regT].reg }
        set { stack[regT].reg = newValue }
    }
    
    mutating func set1( _ v1: Double, r: Int = 1, c: Int = 1 ) {
        self.stack[regX].set1( v1, r: r, c: c)
    }

    mutating func set2( _ v1: Double, _ v2: Double, r: Int = 1, c: Int = 1 ) {
        self.stack[regX].set2( v1, v2, r: r, c: c)
    }
    
    mutating func setShape( _ ss: Int = 1, rows: Int = 1, cols: Int = 1 ) {
        stack[regX].setShape( ss, rows: rows, cols: cols)
    }

    mutating func stackDrop(_ by: Int = 1 ) {
        for rx in regX ..< stackSize-1 {
            self.stack[rx] = self.stack[rx+1]
        }
    }

    mutating func stackLift(_ by: Int = 1 ) {
        if self.noLift {
            logM.debug("stackLift: No-op")
            self.noLift = false
            return
        }
        
        // logM.debug("stackLift: LIFT")
        
        for rx in stride( from: stackSize-1, to: regX, by: -1 ) {
            self.stack[rx] = self.stack[rx-1]
        }
    }

    mutating func stackRoll() {
        let xtv = self.Xtv
        stackDrop()
        let last = stackSize-1
        self.stack[last] = xtv
    }
}
