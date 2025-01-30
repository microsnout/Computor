//
//  Value.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-26.
//
import Foundation
import OSLog

let logV = Logger(subsystem: "com.microsnout.calculator", category: "value")


enum ValueType : Int, Hashable {
    case real = 0, rational, complex, vector, polar
}

let valueSize: [ValueType : Int] = [
    .real : 1,
    .rational : 2,
    .complex : 2,
    .vector : 2,
    .polar : 2
]

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

typealias MatrixShape = Int


struct TaggedValue : RichRender {
    var vtp: ValueType
    var tag: TypeTag
    var fmt: FormatRec
    var mat: MatrixShape

    var storage: [Double] = [0.0]

    var simpleSize: Int { mat / 1000 / 1000 }
    var rows: Int { mat / 1000 % 1000 }
    var cols: Int { mat % 1000 }

    var reg: Double {
        get { storage[0] }
        set { storage[0] = newValue }
    }

    var isMatrix: Bool   { self.rows > 1 || self.cols > 1 }
    var isSimple: Bool   { self.rows == 1 && self.cols == 1 }
    var isReal: Bool     { isSimple && vtp == .real }
    var isInteger: Bool  { isReal && isInt(reg) }
    var isComplex: Bool  { isSimple && vtp == .complex }
    var isRational: Bool { isSimple && vtp == .rational }
    var isVector: Bool   { isSimple && vtp == .vector }
    
    private func storageIndex( _ ssx: Int = 1, row: Int, col: Int = 1 ) -> Int {
        let (ss, rows, _) = self.getShape()
        return (col-1)*ss*rows + (row-1)*ss + (ssx-1)
    }
    
    private func valueIndex( _ row: Int, _ col: Int = 1) -> Int {
        let (ss, rows, _) = getShape()
        return (col-1)*ss*rows + (row-1)*ss
    }
    
    func get1( _ r: Int = 1, _ c: Int = 1 ) -> Double? {
        let index = storageIndex( row: r, col: c)
        return storage[index]
    }

    mutating func set1( _ value: Double, _ r: Int = 1, _ c: Int = 1 ) {
        let index = storageIndex( row: r, col: c)
        storage[index] = value
    }

    func get2( _ r: Int = 1, _ c: Int = 1 ) -> (Double, Double) {
        let index = storageIndex( row: r, col: c)
        return (storage[index], storage[index+1])
    }
    
    mutating func set2( _ v1: Double, _ v2: Double, _ r: Int = 1, _ c: Int = 1 ) {
        let index = storageIndex( row: r, col: c)
        self.setShape(2)
        storage[index]   = v1
        storage[index+1] = v2
    }
    
    func getValue( row: Int = 1, col: Int = 1 ) -> TaggedValue? {
        let (ss, rows, cols) = getShape()
        
        if ( row > rows || col > cols ) {
            return nil
        }

        let index = valueIndex(row, col)
        var value = TaggedValue(self.vtp, tag: self.tag, format: self.fmt)
        
        for n in 0 ..< ss {
            value.storage[n] = self.storage[index+n]
        }
        return value
    }

    mutating func setValue( _ value: TaggedValue, row: Int = 1, col: Int = 1 ) {
        let (ss, rows, cols) = getShape()
        if ( row > rows || col > cols ) {
            return
        }

        let index = valueIndex(row, col)

        for n in 0 ..< ss {
            storage[index+n] = value.storage[n]
        }
    }
    
    var capacity: Int { self.simpleSize * self.rows * self.cols }
    
    func getShape() -> (Int, Int, Int) {
        return (self.simpleSize, self.rows, self.cols)
    }
    
    mutating func setShape( _ ss: Int = 1, _ rows: Int = 1, _ cols: Int = 1 ) {
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
    
    init( _ vtp: ValueType = .real, tag: TypeTag = tagUntyped, reg: Double = 0.0,
          format: FormatRec = FormatRec(), rows: Int = 1, cols: Int = 1 ) {
        self.vtp = vtp
        self.tag = tag
        self.fmt = format
        self.mat = 001001001
        
        // Lookup simple value size
        let ss = valueSize[vtp] ?? 1
        
        setShape(ss, rows, cols)
        
        if isReal {
            storage[0] = reg
        }
    }
    
    func renderDouble( _ reg: Double ) -> String {
        
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
            return text
        }
        
        return "Unknown Fmt"
    }
    
    func renderRichText() -> String {
        if isMatrix {
            let ( _, rows, cols) = getShape()
            return "ç{Units}[ç{}\(rows)ç{Units} x ç{}\(cols)ç{Units}]ç{}"
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
        
        var text = String()
        
        switch vtp {
        case .real:
            text.append( renderDouble(reg) )
            
        case .rational:
            let (num, den) = get2()
            text.append( renderDouble(num))
            text.append( "={/}" )
            text.append( renderDouble(den))

        case .complex:
            let (re, im) = get2()
            let neg = im < 0.0
            text.append( renderDouble(re))
            text.append( neg ? "ç{Units}={ - }ç{}" : "ç{Units}={ + }ç{}")
            text.append( renderDouble( neg ? -im : im))
            text.append("ç{Units}={i}ç{}")

        case .vector:
            let (x, y) = get2()
            text.append("ç{Units}\u{276c}ç{}")
            text.append( renderDouble(x))
            text.append( "ç{Units}={ ,}ç{}")
            text.append( renderDouble(y))
            text.append("ç{Units}\u{276d}ç{}")

        case .polar:
            let (x, y) = get2()
            text.append("ç{Units}\u{276c} r:ç{}")
            text.append( renderDouble(x))
            text.append( "ç{Units}={,} \u{03b8}:ç{}")
            text.append( renderDouble(y))
            text.append("ç{Units}\u{276d}ç{}")
        }

        if let sym = tag.symbol {
            text.append( "ƒ{0.8}={ }ç{Units}\(sym)ç{}ƒ{}" )
        }
        
        return text
    }
}


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
    
    func renderRichText() -> String {
        if let prefix = self.name {
            var text = "ƒ{0.8}ç{Frame}={\(prefix)  }ç{}ƒ{}"
            text.append( self.value.renderRichText() )
            return text
        }
        return value.renderRichText()
    }
}


let untypedZero: TaggedValue = TaggedValue( tag: tagUntyped)
