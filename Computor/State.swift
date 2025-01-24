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


enum ScalarType : Int {
    case real = 0, integer, rational, complex
}

enum FormatStyle : UInt {
    
    // These values match raw values with NumberFormater.Style
    case none = 0
    case decimal = 1
    case scientific = 4
    
    // These are custom extension values
    case complex = 100
    case polar   = 102
    case angleDMS = 110
}

struct FormatRec {
    var style: FormatStyle = .decimal
    var digits: Int = 4
    var minDigits: Int = 0
}

struct RegisterRow: RowDataItem {
    var prefix: String?
    var register: String
    var regAddon: String?
    var exponent: String?
    var expAddon: String?
    var suffix: String?
}

extension RowDataItem {
    
    func getRichText() -> String {
        var txt = String("")
        
        if let prefix = prefix {
            txt.append("ƒ{0.8}ç{Frame}={\(prefix)  }ç{}ƒ{}")
        }
        
        txt.append( "={\(register)}" )
        
        if let addon = regAddon {
            txt.append( "ç{CursorText}={\(addon)}ç{}" )
        }
        
        if let exp = exponent {
            txt.append( "^{\(exp)}" )
            
            if let expAddon = expAddon {
                txt.append( "ç{CursorText}^{\(expAddon)}ç{}" )
            }
        }
        
        if let suffix = suffix {
            txt.append( "ƒ{0.8}={ }ç{Units}\(suffix)ç{}ƒ{}" )
        }
        
        return txt
    }
}

typealias MatrixShape = Int


struct TaggedValue : RichRender {
    var stp: ScalarType
    var tag: TypeTag
    var fmt: FormatRec
    var mat: MatrixShape
    
    var scalarSize: Int { mat / 1000 / 1000 }
    var rows: Int { mat / 1000 % 1000 }
    var cols: Int { mat % 1000 }
    
    var isScalar: Bool { self.rows == 1 && self.cols == 1 }

    var reg: Double {
        get { storage[0] }
        set { storage[0] = newValue }
    }
    
    func get1( _ row: Int = 0, _ col: Int = 0 ) -> Double {
        let (ss, rows, _) = self.getShape()
        let index = (ss*rows)*col + ss*row
        return storage[index]
    }
    
    func get2( _ row: Int = 0, _ col: Int = 0 ) -> (Double, Double) {
        let (ss, rows, _) = self.getShape()
        let index = (ss*rows)*col + ss*row
        return (storage[index], storage[index+1])
    }
    
    mutating func set2( _ v1: Double, _ v2: Double, row: Int = 0, col: Int = 0 ) {
        let (ss, rows, _) = self.getShape()
        let index = (ss*rows)*col + ss*row
        self.setShape(2)
        storage[index]   = v1
        storage[index+1] = v2
    }

    var storage: [Double] = [0.0]
    
    var capacity: Int { self.scalarSize * self.rows * self.cols }
    
    func getShape() -> (Int, Int, Int) {
        return (self.scalarSize, self.rows, self.cols)
    }
    
    mutating func setShape( _ ss: Int = 1, rows: Int = 1, cols: Int = 1 ) {
        self.mat = cols + rows*1000 + ss*1000*1000
        
        self.storage = [Double]( repeating: 0.0, count: self.capacity )
    }
    
    var uid: UnitId { self.tag.uid }
    var tid: TypeId { self.tag.tid }
    
    func isType( _ tt: TypeTag ) -> Bool {
        return tag == tt
    }

    func isUnit( _ uid: UnitId ) -> Bool {
        return self.tag.uid == uid
    }
    
    init( _ tag: TypeTag, _ reg: Double = 0.0, format: FormatRec = FormatRec() ) {
        self.stp = .real
        self.tag = tag
        self.fmt = format
        self.mat = 1001
        
        storage[0] = reg
    }
    
    func renderRichText() -> String {
        if isType(tagNone) {
            return "-"
        }
        
        if fmt.style == .angleDMS {
            // Degrees Minutes Seconds angle display
            let neg = reg < 0.0 ? -1.0 : 1.0
            let angle = abs(reg) + 0.0000001
            let deg = floor(angle)
            let min = floor((angle - deg) * 60.0)
            let sec = ((angle - deg)*60.0 - min) * 60.0
            
            return String( format: "%.0f\u{00B0}%.0f\u{2032}%.*f\u{2033}", neg*deg, min, floor(sec) == sec ? 0 : 2, sec  )
        }
        
        if let nfStyle = NumberFormatter.Style(rawValue: fmt.style.rawValue) {
            var text = String()

            // Use number formatter to render register value
            let nf = NumberFormatter()
            nf.numberStyle = nfStyle
            nf.minimumFractionDigits = fmt.minDigits
            nf.maximumFractionDigits = fmt.digits
            let str = nf.string(for: reg) ?? ""
            
            // Separate mantissa from exponent
            let strParts = str.split( separator: "E" )
            
            text += "={\(strParts[0])}"
            
            if strParts.count == 2 {
                text += "x10"
                text += "^{\(strParts[1])}"
            }

            if let sym = tag.symbol {
                text.append( "ƒ{0.8}={ }ç{Units}\(sym)ç{}ƒ{}" )
            }
            return text
        }
        
        return "Unknown Fmt Style"
    }
    
    func getRegisterRow() -> RegisterRow {
        if isType(tagNone) {
            return RegisterRow( register: "-")
        }
        
        if fmt.style == .angleDMS {
            // Degrees Minutes Seconds angle display
            let neg = reg < 0.0 ? -1.0 : 1.0
            let angle = abs(reg) + 0.0000001
            let deg = floor(angle)
            let min = floor((angle - deg) * 60.0)
            let sec = ((angle - deg)*60.0 - min) * 60.0
            
            let str = String( format: "%.0f\u{00B0}%.0f\u{2032}%.*f\u{2033}", neg*deg, min, floor(sec) == sec ? 0 : 2, sec  )
            
            return RegisterRow( register: str)
        }
        else if let nfStyle = NumberFormatter.Style(rawValue: fmt.style.rawValue) {
            
            let nf = NumberFormatter()
            nf.numberStyle = nfStyle
            nf.minimumFractionDigits = fmt.minDigits
            nf.maximumFractionDigits = fmt.digits
            
            let str = nf.string(for: reg) ?? ""
            
            let strParts = str.split( separator: "E" )
            
            if strParts.count == 2 {
                return RegisterRow(
                    register: String(strParts[0]) + "x10",
                    exponent: String(strParts[1]),
                    suffix: tag.symbol)
            }
            else {
                return RegisterRow(
                    register: String(strParts[0]),
                    suffix: tag.symbol)
            }
        }
        else {
            return RegisterRow( register: "Unknown Fmt Style" )
        }
    }
    
    func getRichText() -> String {
        let row = getRegisterRow()
        
        return row.getRichText()
    }
}

let untypedZero: TaggedValue = TaggedValue(tagUntyped)
let valueNone: TaggedValue = TaggedValue(tagNone)

struct NamedValue : RichRender {
    var name: String?
    var value: TaggedValue
    
    func isType( _ tt: TypeTag ) -> Bool {
        return value.tag == tt
    }
    
    init(_ name: String? = nil, value: TaggedValue ) {
        self.name = name
        self.value = value
    }
    
    func getRegisterRow() -> RegisterRow {
        var rr = value.getRegisterRow()
        rr.prefix = name
        return rr
    }
    
    func getRichText() -> String {
        let row = getRegisterRow()
        
        return row.getRichText()
    }
    
    func renderRichText() -> String {
        if let prefix = self.name {
            var text = "ƒ{0.8}ç{Frame}={\(prefix)  }ç{}ƒ{}"
            text.append( self.value.renderRichText() )
            return text
        }
        return value.renderRichText()
    }
}

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
        if let seq = unitConvert( from: Xt, to: toTag ) {
            Xtv = TaggedValue( toTag, seq.op(X) )
            return true
        }
        
        // Failed to find conversion
        return false
    }
    
    func stackRow( _ index: Int ) -> RegisterRow {
        return self.stack[index].getRegisterRow()
    }
    
    func memoryRow( _ index: Int ) -> RegisterRow {
        guard index >= 0 && index < self.memory.count else {
            return RegisterRow( register: "Error" )
        }
        
        return self.memory[index].getRegisterRow()
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
