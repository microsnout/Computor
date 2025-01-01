//
//  State.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2024-09-28.
//

import Foundation
import Numerics
import OSLog

let logS = Logger(subsystem: "com.microsnout.calculator", category: "state")


// Standard HP calculator registers
let stackPrefixValues = ["X", "Y", "Z", "T"]

// Register index values
let regX = 0, regY = 1, regZ = 2, regT = 3, stackSize = 4

enum FormatStyle : UInt {
    
    // These values match raw values with NumberFormater.Style
    case none = 0
    case decimal = 1
    case scientific = 4
    
    // These are custom extension values
    case complex = 100
    case vector  = 101
    case polar   = 102
    case angleDMS = 110
}

struct FormatRec {
    var style: FormatStyle = .decimal
    var digits: Int = 4
    var minDigits: Int = 0
}

struct TaggedValue {
    var tag: TypeTag
    var reg: Double
    var fmt: FormatRec
    
    var uid: UnitId { self.tag.uid }
    var tid: TypeId { self.tag.tid }
    
    func isUnit( _ uid: UnitId ) -> Bool {
        return self.tag.uid == uid
    }
    
    init( _ tag: TypeTag, _ reg: Double = 0.0, format: FormatRec = FormatRec() ) {
        self.tag = tag
        self.reg = reg
        self.fmt = format
    }
}

let untypedZero: TaggedValue = TaggedValue(tagUntyped)
let valueNone: TaggedValue = TaggedValue(tagNone)

struct NamedValue {
    var name: String?
    var value: TaggedValue
    
    func isType( _ tt: TypeTag ) -> Bool {
        return value.tag == tt
    }
    
    init(_ name: String? = nil, value: TaggedValue ) {
        self.name = name
        self.value = value
    }
}

struct RegisterRow: RowDataItem {
    var prefix: String?
    var register: String
    var regAddon: String?
    var exponent: String?
    var expAddon: String?
    var suffix: String?
}

struct CalcState {
    /// Defines the exact state of the calculator at a given time
    ///
    var stack: [NamedValue] = stackPrefixValues.map { NamedValue( $0, value: untypedZero) }
    var lastX: TaggedValue = untypedZero
    var noLift: Bool = false
    var memory = [NamedValue]()
    
    static let defaultDecFormat: FormatRec = FormatRec( style: .decimal, digits: 4 )
    static let defaultSciFormat: FormatRec = FormatRec( style: .scientific, digits: 4 )

    
    mutating func convertX( toTag: TypeTag ) -> Bool {
        if let seq = unitConvert( from: Xt, to: toTag ) {
            Xtv = TaggedValue( toTag, seq.op(X) )
            return true
        }
        
        // Failed to find conversion
        return false
    }
    
    private func regRow( _ nv: NamedValue ) -> RegisterRow {
        if nv.isType(tagNone) {
            return RegisterRow( prefix: nv.name, register: "-")
        }
        
        let fmt = nv.value.fmt
        
        if fmt.style == .angleDMS {
            // Degrees Minutes Seconds angle display
            let neg = nv.value.reg < 0.0 ? -1.0 : 1.0
            let angle = abs(nv.value.reg) + 0.0000001
            let deg = floor(angle)
            let min = floor((angle - deg) * 60.0)
            let sec = ((angle - deg)*60.0 - min) * 60.0
            
            let str = String( format: "%.0f\u{00B0}%.0f\u{2032}%.*f\u{2033}", neg*deg, min, floor(sec) == sec ? 0 : 2, sec  )
            
            return RegisterRow(
                prefix: nv.name,
                register: str)
        }
        else if let nfStyle = NumberFormatter.Style(rawValue: fmt.style.rawValue) {
            
            let nf = NumberFormatter()
            nf.numberStyle = nfStyle
            nf.minimumFractionDigits = fmt.minDigits
            nf.maximumFractionDigits = fmt.digits
            
            let str = nf.string(for: nv.value.reg) ?? ""
            
            let strParts = str.split( separator: "E" )
            
            if strParts.count == 2 {
                return RegisterRow(
                    prefix: nv.name,
                    register: String(strParts[0]) + "x10",
                    exponent: String(strParts[1]),
                    suffix: nv.value.tag.symbol)
            }
            else {
                return RegisterRow(
                    prefix: nv.name,
                    register: String(strParts[0]),
                    suffix: nv.value.tag.symbol)
            }
        }
        else {
            return RegisterRow( prefix: nv.name, register: "Unknown Fmt Style" )
        }
    }
    
    func stackRow( _ index: Int ) -> RegisterRow {
        return regRow( self.stack[index] )
    }
    
    func memoryRow( _ index: Int ) -> RegisterRow {
        guard index >= 0 && index < self.memory.count else {
            return RegisterRow( register: "Error" )
        }
        
        return regRow( self.memory[index] )
    }
    
    var memoryList: [RegisterRow] {
        get {
            (0 ..< self.memory.count).map { self.memoryRow($0) }
        }
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
        set { self.Xt = newValue.tag; self.X = newValue.reg; self.Xfmt = newValue.fmt }
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
        set { self.Yt = newValue.tag; self.Y = newValue.reg; self.Yfmt = newValue.fmt }
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
        set { self.Zt = newValue.tag; self.Z = newValue.reg; self.Zfmt = newValue.fmt }
    }

    var T: Double {
        get { stack[regT].value.reg }
        set { stack[regT].value.reg = newValue }
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
