//
//  Value.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-26.
//
import Foundation
import Numerics
import OSLog

let logV = Logger(subsystem: "com.microsnout.calculator", category: "value")


enum ValueType : Int, Hashable {
    case real = 0, rational, complex, vector, polar, polarDeg
}

typealias ValueTypeSet = Set<ValueType>

enum ValueShape : Int {
    case simple = 0, matrix
}

let valueSize: [ValueType : Int] = [
    .real : 1,
    .rational : 2,
    .complex : 2,
    .vector : 2,
    .polar : 2
]

typealias Comp = Complex<Double>

enum FormatStyle : UInt {
    
    // These values match raw values with NumberFormater.Style
    case none = 0
    case decimal = 1
    case scientific = 4
    
    // These are custom extension values
    case angleDMS = 110
}

struct FormatRec {
    var style: FormatStyle = .decimal
    var digits: Int = 4
    var minDigits: Int = 0
}

typealias MatrixShape = Int


enum RegisterSpec {
    case X( _ vt: ValueTypeSet, _ vs: ValueShape = .simple )
    case Y( _ vt: ValueTypeSet, _ vs: ValueShape = .simple )
    case Z( _ vt: ValueTypeSet, _ vs: ValueShape = .simple )
}

typealias RegisterPattern = [RegisterSpec]


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
    
    var valueShape: ValueShape { isSimple ? .simple : .matrix }
    
    private func storageIndex( _ ssx: Int = 1, row: Int, col: Int = 1 ) -> Int {
        let (ss, rows, _) = self.getShape()
        return (col-1)*ss*rows + (row-1)*ss + (ssx-1)
    }
    
    private func valueIndex( _ row: Int, _ col: Int = 1) -> Int {
        let (ss, rows, _) = getShape()
        return (col-1)*ss*rows + (row-1)*ss
    }
    
    func get1( _ r: Int = 1, _ c: Int = 1 ) -> Double {
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
    
    func getComplex( _ r: Int = 1, _ c: Int = 1 ) -> Comp {
        switch vtp {
        case .complex:
            let (re, im) = get2(r,c)
            return Comp(re, im)
            
        case .real:
            let (re, im) = (reg, 0.0)
            return Comp(re, im)
            
        case .rational:
            let (num, den) = get2(r,c)
            return Comp( num/den, 0.0)
            
        default:
            return Comp(0, 0)

        }
    }
    
    mutating func setReal( _ x: Double ) {
        vtp = .real
        setShape(1)
        set1(x)
    }

    mutating func setComplex( _ z: Comp ) {
            vtp = .complex
            setShape(2)
            set2( z.real, z.imaginary)
    }
    
    func getVector2D() -> (Double, Double) {
        switch vtp {
        case .vector:
            let (x, y) = get2()
            return (x, y)
            
        case .polar:
            let (r, w) = get2()
            return ( r * cos(w), r * sin(w) )
            
        case .polarDeg:
            let (r, d) = get2()
            let w = d * Double.pi / 180.0
            return ( r * cos(w), r * sin(w) )

        default:
            return (0.0, 0.0)
        }
    }
    
    mutating func setVector2D( _ x: Double, _ y: Double ) {
        vtp = .vector
        setShape(2)
        set2( x,y )
    }
    
    func getPolar2D() -> (Double, Double) {
        switch vtp {
        case .polar:
            let (r, w) = get2()
            return (r, w)
            
        case .polarDeg:
            let (r, d) = get2()
            return (r, d * Double.pi / 180.0)
            
        case .vector:
            let (x, y) = get2()
            return ( sqrt(x*x + y*y), atan(y/x) )
            
        default:
            return (0.0, 0.0)
        }
    }

    mutating func setPolar2D( _ r: Double, _ w: Double ) {
        vtp = .polar
        setShape(2)
        set2( r,w )
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
    
    func valueInRange( _ ssV: Int = 1, _ rowV: Int = 1, _ colV: Int = 1 ) -> Bool {
        let (ss, rows, cols) = getShape()
        
        return ssV <= ss && rowV <= rows && colV <= cols
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
    
    func renderDouble( _ reg: Double ) -> (String, Int) {
        
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
            
            var count = strParts[0].count
            
            if strParts.count == 2 {
                text += "x10"
                text += "^{\(strParts[1])}"
                
                count += strParts[1].count + 3
            }
            return (text, count)
        }
        
        return ("Unknown Fmt", 11)
    }
    
    func renderValueReal( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let value = get1( row, col)
        var (text, valueCount) = renderDouble(value)
        
        if tag != tagUntyped {
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                
                valueCount += sym.count + 1
            }
        }
        return (text, valueCount)
    }

    func renderValueRational( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (num, den) = get2( row, col)
        let (numStr, numCount) = renderDouble(num)
        let (denStr, denCount) = renderDouble(den)
        
        var text = String()
        text.append(numStr)
        text.append( "={/}" )
        text.append(denStr)
        
        return (text, numCount + denCount + 1)
    }

    func renderValueComplex( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (re, im) = get2( row, col)
        let neg = im < 0.0
        let (reStr, reCount) = renderDouble(re)
        let (imStr, imCount) = renderDouble( neg ? -im : im )

        var text = String()
        text.append(reStr)
        text.append( neg ? "ç{Units}={ - }ç{}" : "ç{Units}={ + }ç{}")
        text.append(imStr)
        text.append("ç{Units}={i}ç{}")
        
        return (text, reCount + imCount + 3)
    }
    
    func renderValueVector( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (x, y) = get2( row, col)
        let (xStr, xCount) = renderDouble(x)
        let (yStr, yCount) = renderDouble(y)
        
        var text = String()
        text.append("ç{Units}\u{276c}ç{}")
        text.append(xStr)
        text.append( "ç{Units}={ ,}ç{}")
        text.append(yStr)
        text.append("ç{Units}\u{276d}ç{}")
        
        return (text, xCount + yCount + 4)
    }
    
    func renderValuePolar( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (r, w) = get2( row, col)
        let (rStr, rCount) = renderDouble(r)
        let (wStr, wCount) = renderDouble(w)
        
        var unitCount = 0
        var text = String()
        
        text.append("ç{Units}\u{276c} r:ç{}")
        text.append(rStr)
        
        if tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                unitCount += sym.count + 1
            }
        }

        text.append( "ç{Units}={,} \u{03b8}:ç{}")
        text.append(wStr)
        
        if vtp == .polarDeg {
            text.append( "\u{00B0}" )
            unitCount += 1
        }
        
        text.append("ç{Units}\u{276d}ç{}")
        
        return (text, rCount + wCount + unitCount + 9)
    }
    
    func renderValueSimple( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        switch vtp {
        case .real:
            return renderValueReal(row, col)
            
        case .rational:
            return renderValueRational(row, col)

        case .complex:
            return renderValueComplex(row, col)

        case .vector:
            return renderValueVector(row, col)

        case .polar, .polarDeg:
            return renderValuePolar(row, col)
        }
    }

    func renderRichText() -> (String, Int) {
        if isMatrix {
            return renderMatrix()
        }
        
        if fmt.style == .angleDMS {
            // Degrees Minutes Seconds angle display
            let neg = reg < 0.0 ? -1.0 : 1.0
            let angle = abs(reg) + 0.0000001
            let deg = floor(angle)
            let min = floor((angle - deg) * 60.0)
            let sec = ((angle - deg)*60.0 - min) * 60.0
            
            let degStr = String( format: "%.0f", neg*deg )
            let minStr = String( format: "%.0f", min )
            let secStr = String( format: "%.*f", sec )
            
            let str   = String( format: "\(degStr)\u{00B0}\(minStr)\u{2032}\(secStr)\u{2033}" )
            let count = degStr.count + minStr.count + secStr.count + 3
            return (str, count)
            
//            let str = String( format: "%.0f\u{00B0}%.0f\u{2032}%.*f\u{2033}", neg*deg, min, floor(sec) == sec ? 0 : 2, sec  )
        }
        
        return renderValueSimple()
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
    
    func renderRichText() -> (String, Int) {
        if let prefix = self.name {
            var text = "ƒ{0.8}ç{Frame}={\(prefix)  }ç{}ƒ{}"
            let (valueStr, valueCount) = self.value.renderRichText()
            let count = valueCount + prefix.count + 2
            text += valueStr
            return (text, count)
        }
        return value.renderRichText()
    }
}


let untypedZero: TaggedValue = TaggedValue( tag: tagUntyped)
