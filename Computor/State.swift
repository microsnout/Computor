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
let regX = 0, regY = 1, regZ = 2, regT = 3


typealias StateTest = ( _ s0: CalcState) -> Bool

struct RegisterPattern {
    var specList: [RegisterSpec]
    var stateTest: StateTest?
    
    init( _ specList: [RegisterSpec] = [], _ stateTest: StateTest? = nil) {
        self.specList = specList
        self.stateTest = stateTest
    }
}


struct CalcState: Codable {
    /// Defines the exact state of the calculator at a given time
    ///
    var stack  = [TaggedValue]( repeating: untypedZero, count: Const.Model.stackSize )
    var lastX  = untypedZero
    var noLift = false
    var memory = [MemoryRec]()
}


extension CalcState {
    
    static let stackRegNames = ["X", "Y", "Z"]

    static let defaultDecFormat: FormatRec = FormatRec( style: .decimal, digits: 4 )
    static let defaultSciFormat: FormatRec = FormatRec( style: .scientific, digits: 4 )
    
    func memoryAt( index: Int ) -> MemoryRec? {
        guard index >= 0 && index < memory.count else {
            return nil
        }
        return memory[index]
    }
    
    func memoryIndex( at tag: SymbolTag ) -> Int? {
        return memory.firstIndex( where: { tag == $0.symTag })
    }
    
    func memoryAt( at tag: SymbolTag ) -> MemoryRec? {
        return memory.first( where: { tag == $0.symTag } )
    }
    
    
    mutating func memorySetValue( at tag: SymbolTag, to tv: TaggedValue ) {
        
        if let index = memoryIndex(at: tag) {
            
            // Modify existing memory
            memory[index].tv = tv
        }
        else {
            // Add new memory
            memory.append( MemoryRec( tag: tag, tv: tv ) )
        }
    }
    
    
    func memoryGetValue( at tag: SymbolTag ) -> TaggedValue? {
        
        if let mr = memoryAt( at: tag) {
            return mr.tv
        }
        return nil
    }

    
    mutating func memorySetCaption( at tag: SymbolTag, to str: String? ) {
        
        if let index = memoryIndex(at: tag) {
            
            // Modify existing memory
            memory[index].caption = str
        }
    }
    
    mutating func memoryChangeSymbol( from oldTag: SymbolTag, to newTag: SymbolTag  ) {
        
        // Find memory with the old tag
        if let mr = memoryAt( at: oldTag ) {
            
            // Verify there is no memory with the new tag
            if memory.firstIndex( where: { newTag == $0.symTag } ) == nil {
                
                // Change the tag
                mr.symTag = newTag
            }
            
        }
    }
    
    mutating func deleteMemoryRecords( tags: SymbolSet ) {
        memory.removeAll( where: { tags.contains($0.symTag) } )
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

    mutating func stackDrop() {
        for rx in regX ..< Const.Model.stackSize-1 {
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
        
        for rx in stride( from: Const.Model.stackSize-1, to: regX, by: -1 ) {
            self.stack[rx] = self.stack[rx-1]
        }
    }

    mutating func stackRoll() {
        let xtv = self.Xtv
        stackDrop()
        let last = Const.Model.stackSize-1
        self.stack[last] = xtv
    }
    
    mutating func popRealX() -> Double {
        let x = self.X
        stackDrop()
        return x
    }

    mutating func popRealXY() -> (Double, Double) {
        let (x, y) = (self.X, self.Y)
        stackDrop()
        stackDrop()
        return (x,y)
    }
    
    mutating func popRealXYZ() -> (Double, Double, Double) {
        let (x, y, z) = (self.X, self.Y, self.Z)
        stackDrop()
        stackDrop()
        stackDrop()
        return (x,y,z)
    }

    mutating func popValueX() -> TaggedValue {
        let tv = self.Xtv
        stackDrop()
        return tv
    }
    
    mutating func pushValue(_ tv: TaggedValue) {
        stackLift()
        Xtv = tv
        noLift = false
    }
    
    mutating func pushRealValue( _ r: Double ) {
        let tv = TaggedValue( reg: r )
        pushValue(tv)
    }
}
