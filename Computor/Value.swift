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


enum ValueType : Int, Codable, Hashable {
    case real = 0, rational, complex, vector, polar, vector3D, spherical
}

typealias ValueTypeSet = Set<ValueType>

enum ValueShape : Int, Codable {
    case simple = 0, matrix
}

let valueSize: [ValueType : Int] = [
    .real : 1,
    .rational : 2,
    .complex : 2,
    .vector : 2,
    .polar : 2,
    .vector3D : 3,
    .spherical : 3,
]

typealias Comp = Complex<Double>

// Constant multiplier used to store multiple integers in one 64 bit Int
fileprivate let M: Int = 1000000
fileprivate let K: Int = 1000
fileprivate let H: Int = 100

enum FormatStyle : Int, Codable {
    case decimal    = 0
    case scientific = 1
    case dms        = 2
}

enum PolarAngle : Int, Codable {
    case radians = 0
    case degrees = 1
    case dms     = 2
}


struct FormatRec: Codable {
    var frec: Int
    
    init( style: FormatStyle = FormatStyle.decimal, digits: Int = 4, minDig: Int = 0, polarAngle: PolarAngle = .radians ) {
        self.frec = polarAngle.rawValue + minDig * H + digits * H*H + style.rawValue * H*H*H
    }
}

extension FormatRec {
    
    func getFormat() -> ( FormatStyle, Int, Int, PolarAngle) {
        ( style, digits, minDigits, polarAngle )
    }
    
    mutating func setFormat( _ style: FormatStyle, _ digits: Int, _ minDig: Int, _ polarAngle: PolarAngle ) {
        self.frec = polarAngle.rawValue + minDig * H + digits * H*H + style.rawValue * H*H*H
    }

    var style: FormatStyle {
        get { FormatStyle( rawValue: frec / H / H / H % H ) ?? FormatStyle.decimal }
        set {
            let ( _, dig, minDig, angle) = getFormat()
            setFormat(newValue, dig, minDig, angle)
        }
    }
    
    var digits: Int {
        get { frec / H / H % H }
        set {
            let (style, _, minDig, angle) = getFormat()
            setFormat(style, newValue, minDig, angle)
        }
    }

    var minDigits: Int {
        get { frec / H % H }
        set {
            let (style, dig, _, angle) = getFormat()
            setFormat(style, dig, newValue, angle)
        }
    }
    
    var polarAngle: PolarAngle {
        get { PolarAngle( rawValue: frec % H ) ?? PolarAngle.radians }
        set {
            let (style, dig, minDig, _) = getFormat()
            setFormat(style, dig, minDig, newValue)
        }
    }
}


typealias MatrixShape = Int


enum RegisterSpec {
    case X( _ vt: ValueTypeSet, _ vs: ValueShape = .simple )
    case Y( _ vt: ValueTypeSet, _ vs: ValueShape = .simple )
    case Z( _ vt: ValueTypeSet, _ vs: ValueShape = .simple )
}


struct TaggedValue : RichRender & Codable {
    var vtp: ValueType
    var tag: TypeTag
    var fmt: FormatRec
    var mat: MatrixShape
    var reg: Double {
        get { storage[0] }
        set { storage[0] = newValue }
    }

    var uid: UnitId { self.tag.uid }
    var tid: TypeId { self.tag.tid }

    var size: Int { mat / M / M }
    var rows: Int { mat / M % M }
    var cols: Int { mat % M }
    
    private var storage: [Double] = [0.0]
    
    init( _ vtp: ValueType = .real, tag: TypeTag = tagUntyped, reg: Double = 0.0,
          format: FormatRec = FormatRec(), rows: Int = 1, cols: Int = 1 ) {
        self.vtp = vtp
        self.tag = tag
        self.fmt = format
        self.mat = 1 + M + M*M      // Size 1, 1 row, 1 col
        
        // Lookup simple value size
        let ss = valueSize[vtp] ?? 1
        
        setShape(ss, rows, cols)
        
        if isReal {
            storage[0] = reg
        }
    }
}


extension TaggedValue {
    
    var isMatrix: Bool   { self.rows > 1 || self.cols > 1 }
    var isSimple: Bool   { self.rows == 1 && self.cols == 1 }
    var isReal: Bool     { isSimple && vtp == .real }
    var isInteger: Bool  { isReal && isInt(reg) }
    var isComplex: Bool  { isSimple && vtp == .complex }
    var isRational: Bool { isSimple && vtp == .rational }
    var isVector: Bool   { isSimple && vtp == .vector }
    
    var valueShape: ValueShape { isSimple ? .simple : .matrix }
    
    var capacity: Int { self.size * self.rows * self.cols }
    
    func getShape() -> (Int, Int, Int) {
        return (self.size, self.rows, self.cols)
    }
    
    mutating func setShape( _ ss: Int = 1, _ rows: Int = 1, _ cols: Int = 1 ) {
        self.mat = cols + rows*M + ss*M*M
        
        self.storage = [Double]( repeating: 0.0, count: self.capacity )
    }
    
    mutating func setMatrix( _ vtp: ValueType, tag: TypeTag = tagUntyped, fmt: FormatRec = FormatRec(), rows: Int, cols: Int = 1 ) {
        setShape( valueSize[vtp] ?? 1, rows, cols )
        self.vtp = vtp
        self.tag = tag
        self.fmt = fmt
    }
    
    func valueInRange( _ ssV: Int = 1, _ rowV: Int = 1, _ colV: Int = 1 ) -> Bool {
        let (ss, rows, cols) = getShape()
        
        return ssV <= ss && rowV <= rows && colV <= cols
    }
    
    func isType( _ tt: TypeTag ) -> Bool {
        return tag == tt
    }

    func isUnit( _ uid: UnitId ) -> Bool {
        return self.tag.uid == uid
    }

    private func storageIndex( _ ssx: Int = 1, row: Int, col: Int = 1 ) -> Int {
        let (ss, rows, _) = self.getShape()
        return (col-1)*ss*rows + (row-1)*ss + (ssx-1)
    }
    
    private func valueIndex( _ row: Int, _ col: Int = 1) -> Int {
        let (ss, rows, _) = getShape()
        return (col-1)*ss*rows + (row-1)*ss
    }
    
    func get1( r: Int = 1, c: Int = 1 ) -> Double {
        let index = storageIndex( row: r, col: c)
        return storage[index]
    }

    func get2( r: Int = 1, c: Int = 1 ) -> (Double, Double) {
        let index = storageIndex( row: r, col: c)
        return (storage[index], storage[index+1])
    }

    func get3( r: Int = 1, c: Int = 1 ) -> (Double, Double, Double) {
        let index = storageIndex( row: r, col: c)
        return (storage[index], storage[index+1], storage[index+2])
    }

    mutating func set1( _ value: Double, r: Int = 1, c: Int = 1 ) {
        let index = storageIndex( row: r, col: c)
        storage[index] = value
    }
    
    mutating func set2( _ v1: Double, _ v2: Double, r: Int = 1, c: Int = 1 ) {
        let index = storageIndex( row: r, col: c)
        storage[index]   = v1
        storage[index+1] = v2
    }

    mutating func set3( _ v1: Double, _ v2: Double, _ v3: Double, r: Int = 1, c: Int = 1 ) {
        let index = storageIndex( row: r, col: c)
        storage[index]   = v1
        storage[index+1] = v2
        storage[index+2] = v3
    }
    
    // Get and Set Real, Rational, Complex, Vector, polar, vector3D, spherical
    
    func getReal() -> Double { get1() }
    
    mutating func setReal( _ value: Double,
                             tag: TypeTag = tagUntyped,
                             fmt: FormatRec = CalcState.defaultDecFormat ) {
        setShape(1)
        self.vtp = .real
        self.reg = value
        self.tag = tag
        self.fmt = fmt
    }

    func getComplex( _ r: Int = 1, _ c: Int = 1 ) -> Comp {
        switch vtp {
        case .complex:
            let (re, im) = get2( r: r, c: c)
            return Comp(re, im)
            
        case .real:
            let (re, im) = (reg, 0.0)
            return Comp(re, im)
            
        case .rational:
            let (num, den) = get2( r: r, c: c)
            return Comp( num/den, 0.0)
            
        default:
            return Comp(0, 0)

        }
    }

    mutating func setComplex( _ z: Comp,
                              tag: TypeTag = tagUntyped,
                              fmt: FormatRec = CalcState.defaultDecFormat) {
        setShape(2)
        self.vtp = .complex
        self.tag = tag
        self.fmt = fmt
        set2( z.real, z.imaginary)
    }
    
    func getVector() -> (Double, Double) {
        switch vtp {
        case .vector, .complex:
            let (x, y) = get2()
            return (x, y)
            
        case .polar:
            let (r, w) = get2()
            return polar2rect(r,w)
            
        default:
            return (0.0, 0.0)
        }
    }

    func getVector3D() -> (Double, Double, Double) {
        switch vtp {
        case .vector3D:
            let (x, y, z) = get3()
            return (x, y, z)
            
        case .spherical:
            let (r, w, p) = get3()
            return spherical2rect(r,w,p)
            
        default:
            return (0.0, 0.0, 0.0)
        }
    }
    
    mutating func setVector( _ x: Double, _ y: Double,
                               tag: TypeTag = tagUntyped,
                               fmt: FormatRec = CalcState.defaultDecFormat) {
        setShape(2)
        self.vtp = .vector
        self.tag = tag
        self.fmt = fmt
        set2( x,y )
    }

    mutating func setVector3D( _ x: Double, _ y: Double, _ z: Double,
                                 tag: TypeTag = tagUntyped,
                                 fmt: FormatRec = CalcState.defaultDecFormat) {
        setShape(3)
        self.vtp = .vector3D
        self.tag = tag
        self.fmt = fmt
        set3( x,y,z )
    }
    
    func getPolar() -> (Double, Double) {
        switch vtp {
        case .polar:
            let (r, w) = get2()
            return (r, w)
            
        case .vector:
            let (x, y) = get2()
            return rect2polar(x,y)
            
        default:
            return (0.0, 0.0)
        }
    }

    mutating func setPolar( _ r: Double, _ w: Double,
                              tag: TypeTag = tagUntyped,
                              fmt: FormatRec = CalcState.defaultDecFormat) {
        setShape(2)
        self.vtp = .polar
        self.tag = tag
        self.fmt = fmt
        set2( r,w )
    }

    func getSpherical() -> (Double, Double, Double) {
        switch vtp {
        case .spherical:
            let (r, w, p) = get3()
            return (r, w, p)
            
        case .vector3D:
            let (x, y, z) = get3()
            return rect2spherical(x,y,z)
            
        default:
            return (0.0, 0.0, 0.0)
        }
    }

    mutating func setSpherical( _ r: Double, _ w: Double, _ p: Double,
                                tag: TypeTag = tagUntyped,
                                fmt: FormatRec = CalcState.defaultDecFormat) {
        setShape(3)
        self.vtp = .spherical
        self.tag = tag
        self.fmt = fmt
        set3( r,w,p )
    }

    // Get and Set Tagged values from this tagged value - from matric to scalar
    
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
    
    mutating func transformValues( _ fn: (Double, Int, Int, Int) -> Double ) {
        let (ss, rows, cols) = getShape()
        
        for c in 1...cols {
            for r in 1...rows {
                for s in 1...ss {
                    let index = storageIndex(s, row: r, col: c)
                    let oldValue = storage[index]
                    let newValue = fn(oldValue, s, r, c)
                    storage[index] = newValue
                }
            }
        }
    }
    
    // Value string render functions
    
    func renderDouble( _ reg: Double ) -> (String, Int) {
        
        var text = String()

        // Use number formatter to render register value
        let nf = NumberFormatter()
        nf.numberStyle = fmt.style == .scientific ? NumberFormatter.Style.scientific : NumberFormatter.Style.decimal
        nf.minimumFractionDigits = Int(fmt.minDigits)
        nf.maximumFractionDigits = Int(fmt.digits)
        
        let str = nf.string( for: reg) ?? "<?>"
        
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
    
    func renderValueReal( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let value = get1( r: row, c: col)
        var (text, valueCount) = renderDouble(value)
        
        if isSimple && tag != tagUntyped {
            if tag == tagDeg {
                
                if fmt.style == .dms {
                    // Degrees Minutes Seconds angle display
                    let neg = reg < 0.0 ? -1.0 : 1.0
                    let angle = abs(reg) + 0.0000001
                    let deg = floor(angle)
                    let min = floor((angle - deg) * 60.0)
                    let sec = ((angle - deg)*60.0 - min) * 60.0
                    
                    let degStr = String( format: "%.0f", neg*deg )
                    let minStr = String( format: "%.0f", min )
                    let secStr = String( format: "%.0f", sec )
                    
                    let str   = String( format: "={\(degStr)\u{00B0}\(minStr)\u{2032}\(secStr)\u{2033}}" )
                    let count = degStr.count + minStr.count + secStr.count + 3
                    return (str, count)
                }
                else {
                    // Use degree symbol
                    text.append("\u{00B0}")
                    valueCount += 1
                }
            }
            else if let sym = tag.symbol {
                // Add unit symbol
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                valueCount += sym.count + 1
            }
        }
        return (text, valueCount)
    }

    func renderValueRational( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (num, den) = get2( r: row, c: col)
        let (numStr, numCount) = renderDouble(num)
        let (denStr, denCount) = renderDouble(den)
        
        var text = String()
        text.append(numStr)
        text.append( "={/}" )
        text.append(denStr)
        
        return (text, numCount + denCount + 1)
    }

    func renderValueComplex( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (re, im) = get2( r: row, c: col)
        let neg = im < 0.0
        let (reStr, reCount) = renderDouble(re)
        let (imStr, imCount) = renderDouble( neg ? -im : im )

        var unitCount = 0
        
        var text = String()
        text.append(reStr)
        text.append( neg ? "ç{Units} ={-} ç{}" : "ç{Units} ={+} ç{}")
        text.append(imStr)
        text.append("ç{Units}={i}ç{}")
        
        if isSimple && tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                unitCount += sym.count + 1
            }
        }

        return (text, reCount + imCount + 3 + unitCount)
    }
    
    
    func renderValueVector( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (x, y) = get2( r: row, c: col)
        let (xStr, xCount) = renderDouble(x)
        let (yStr, yCount) = renderDouble(y)
        
        var unitCount = 0
        
        var text = String()
        text.append("ç{Units}\u{276c}ç{}")
        text.append(xStr)
        text.append( "ç{Units}={ ,}ç{}")
        text.append(yStr)
        text.append("ç{Units}\u{276d}ç{}")
        
        if isSimple && tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                unitCount += sym.count + 1
            }
        }
        
        return (text, xCount + yCount + 4 + unitCount)
    }
    
    
    func renderValuePolar( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        ///
        /// RenderValuePolar
        ///     - Handles .polar
        ///
        var (r, w) = get2( r: row, c: col)
        
        if fmt.polarAngle == .degrees {
            w *= 180.0 / Double.pi
        }
        
        let (rStr, rCount) = renderDouble(r)
        let (wStr, wCount) = renderDouble(w)
        
        var unitCount = 0
        var text = String()
        
        text.append("ç{Units}\u{276c} r: ç{}" + rStr )
        
        if isSimple && tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                unitCount += sym.count + 1
            }
        }

        text.append( "ç{Units}={,} \u{03b8}: ç{}" + wStr )
        
        if fmt.polarAngle == .degrees {
            text.append( "\u{00B0}" )
            unitCount += 1
        }
        
        text.append("ç{Units}\u{276d}ç{}")
        
        return (text, rCount + wCount + unitCount + 11)
    }
    
    
    func renderValueVector3D( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        let (x, y, z) = get3( r: row, c: col)
        let (xStr, xCount) = renderDouble(x)
        let (yStr, yCount) = renderDouble(y)
        let (zStr, zCount) = renderDouble(z)

        var unitCount = 0
        
        var text = String()
        text.append("ç{Units}\u{276c}ç{}" + xStr)
        text.append( "ç{Units}={,} ç{}" + yStr)
        text.append( "ç{Units}={,} ç{}" + zStr)
        text.append("ç{Units}\u{276d}ç{}")
        
        if isSimple && tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                unitCount += sym.count + 1
            }
        }
        
        return (text, xCount + yCount + zCount + 6 + unitCount)
    }

    
    func renderValueSpherical( _ row: Int = 1, _ col: Int = 1 ) -> (String, Int) {
        ///
        /// RenderValuePolar
        ///     - Handles spherical
        ///
        var (r, theta, phi) = get3( r: row, c: col)
        
        if fmt.polarAngle == .degrees {
            theta *= 180.0 / Double.pi
            phi   *= 180.0 / Double.pi
        }
        
        let (rStr, rCount)         = renderDouble(r)
        let (thetaStr, thetaCount) = renderDouble(theta)
        let (phiStr, phiCount)     = renderDouble(phi)

        var unitCount = 0
        var text = String()
        
        text.append("ç{Units}\u{276c} r: ç{}" + rStr)
        
        if isSimple && tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                unitCount += sym.count + 1
            }
        }

        text.append( "ç{Units}={,} \u{03b8}: ç{}" + thetaStr )
        
        if fmt.polarAngle == .degrees {
            text.append( "\u{00B0}" )
            unitCount += 1
        }

        text.append( "ç{Units}={,} \u{03c6}: ç{}" + phiStr )
        
        if fmt.polarAngle == .degrees {
            text.append( "\u{00B0}" )
            unitCount += 1
        }
        
        text.append("ç{Units}\u{276d}ç{}")
        
        return (text, rCount + thetaCount + phiCount + unitCount + 16)
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

        case .polar:
            return renderValuePolar(row, col)

        case .vector3D:
            return renderValueVector3D(row, col)

        case .spherical:
            return renderValueSpherical(row, col)
        }
    }

    func renderRichText() -> (String, Int) {
        if isMatrix {
            return renderMatrix()
        }
        
        return renderValueSimple()
    }
}


struct NamedValue : RichRender, Codable {
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


extension TaggedValue {
    static func getSampleData() -> [TaggedValue] {
        var data = [TaggedValue]( repeating: TaggedValue(), count: 4)
        
        data[0].setReal( 3.14159 )
        data[1].setVector( 3.0, 4.0 )
        data[3].setComplex( Comp(1.0, -2.0))
        data[2].setPolar( 1.0, Double.pi/6, fmt: FormatRec( polarAngle: .degrees ))
        return data
    }
}


extension NamedValue {
    static let names = ["Pi", "Path", "Nav", "Voltage"]
    
    static func getSampleData() -> [NamedValue] {
        let values = TaggedValue.getSampleData()
        
        return zip(names, values).map() { (name, value) in
            NamedValue(name, value: value)
        }
    }
}
