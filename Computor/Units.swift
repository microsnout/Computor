//
//  units.swift
//  Computor
//
//  Created by Barry Hall on 2024-09-03.
//

import Foundation
import OSLog

let logU = Logger(subsystem: "com.microsnout.calculator", category: "units")

// Standard predefined unit types, .user indicates dynamically defined new type
// UnitId value is Int equal to rawValue but can exceed .user
//
enum StdUnitId: Int {
    case untyped = 0, angle, length, area, volume, velocity, acceleration, time
    case mass, weight, pressure, capacity, temp
    case user = 1000
}

// Starting value for UnitIds of type .user
let userIdBase:Int = 1000

typealias UnitId = Int
typealias TypeId = Int


// Common UnitId values as Int
let uidUntyped = StdUnitId.untyped.rawValue
let uidUser = StdUnitId.user.rawValue


struct TypeTag: Hashable & Codable {
    var uid : UnitId
    var tid : TypeId
    
    func isType( _ uid: UnitId ) -> Bool {
        return self.uid == uid
    }
    
    func isType( _ uid: StdUnitId ) -> Bool {
        /// This func can determine if a tag is a specific predefined type or a user type but not which user type
        if uid == .user && self.uid >= userIdBase {
            return true
        }
        return self.uid == uid.rawValue
    }
    
    var symbol: String? {
        if let def = TypeDef.typeDict[self] {
            // Get symbol from definition
            return def.symbol
        }
        else if uid == uidUntyped {
            // Untyped numbers have no symbol
            return nil
        }
        else {
            // Unknown type
            return self.description
        }
    }
    
    init( _ uid: UnitId, _ tid: TypeId = 0 ) {
        self.uid = uid
        self.tid = tid
    }
    
    init( _ uid: StdUnitId, _ tid: TypeId = 0 ) {
        self.uid = uid.rawValue
        self.tid = tid
    }
}

extension TypeTag: CustomStringConvertible {
    var description: String {
        if self.isType(.user) {
            return "{User\(self.uid - userIdBase):\(self.tid)}"
        }
        return "{\(StdUnitId( rawValue: uid) ?? .untyped) :\(tid)}"
    }
}

func uid2Str( _ uid: UnitId ) -> String {
    if uid >= userIdBase {
        return "User\(uid - userIdBase)"
    }
    return "\(StdUnitId( rawValue: uid) ?? .untyped)"
}

extension String {
    init( uid: UnitId ) {
        self.init( uid2Str(uid))
    }
}

typealias UnitCode = [(uid: UnitId, exp: Int)]
typealias TypeCode = [(tid: TypeTag, exp: Int)]

typealias UnitSignature = String
typealias TypeSignature = String


enum UnitCodeKeys: String, CodingKey {
    case uid
    case exp
}

enum TypeCodeKeys: String, CodingKey {
    case tid
    case exp
}


func toUnitCode( from: UnitSignature ) -> UnitCode {
    ///
    /// UnitSignature -> UnitCode
    ///
    var uc: UnitCode = []
    
    if ( from.isEmpty || from == "1" ) {
        return uc
    }
    
    // Positive Negative exponent parts
    let pn = from.split( separator: "/")
    
    // if count is 2 there is a list of negative exponent factors or denomenator units 'm/s' -> 'm', 's'
    let pstr = pn[0]
    let nstr = pn.count > 1 ? pn[1] : ""
    
    // Multipication symbol separated factors 'N·m'
    let pFactors = pstr.split( separator: "·")
    
    for pf in pFactors {
        // Exponent symbol is present if exp is not 1
        let bits = pf.split( separator: "^")
       
        if let unit = UnitDef.fromSym( String(bits[0]) ) {
            let exp: Int = bits.count > 1 ? Int(bits[1])! : 1
            uc.append( (unit.uid, exp) )
        }
    }
    
    if !nstr.isEmpty {
        // Same process for factors after the / except all exponents are negated
        let nFactors = nstr.split( separator: "·")
        
        for nf in nFactors {
            let bits = nf.split( separator: "^")
            let sym = String(bits[0])
            
            if let unit = UnitDef.fromSym(sym) {
                let exp: Int = bits.count > 1 ? Int(bits[1])! : 1
                uc.append( (unit.uid, -exp) )
            }
            else {
                logU.error( "Undefined unit symbol: \(sym) in signature: \(from)" )
            }
        }
    }

    return uc
}


func getUnitSig( _ uc: UnitCode ) -> UnitSignature {
    ///
    /// UnitCode -> UnitSignature
    ///     [(length, 1),(time,-2)] -> "length/time^2"
    ///
    if uc.isEmpty {
        return ""
    }
    let (_, exp0) = uc[0]
    var ss = exp0 < 0 ? "1/" : ""
    var negSeen: Bool = false
    var fn = 0

    for (uid, exp) in uc {
        
        if fn > 0 {
            if exp < 0 && !negSeen {
                ss.append("/")
                negSeen = true
            }
            else {
                ss.append( "·" )
            }
        }
        
        ss.append( uid2Str(uid) )
        
        if abs(exp) > 1 {
            ss.append( "^\(abs(exp))" )
        }
        fn += 1
    }
    return ss
}


func toTypeCode( from: TypeSignature ) -> TypeCode {
    ///
    ///  TypeSignature -> TypeCode
    ///
    var tc: TypeCode = []
    
    if ( from.isEmpty ) {
        return tc
    }
    
    let pn = from.split( separator: "/")
    
    let pstr = pn[0]
    let nstr = pn.count > 1 ? pn[1] : ""
    
    let pFactors = pstr.split( separator: "·")
    
    for pf in pFactors {
        let bits = pf.split( separator: "^")
       
        if let tag = TypeDef.symDict[ String(bits[0]) ] {
            let exp: Int = bits.count > 1 ? Int(bits[1])! : 1
            tc.append( (tag, exp) )
        }
    }
    
    if !nstr.isEmpty {
        let nFactors = nstr.split( separator: "·")
        
        for nf in nFactors {
            let bits = nf.split( separator: "^")
            let sym = String(bits[0]) 
            
            if let tag = TypeDef.symDict[sym] {
                let exp: Int = bits.count > 1 ? Int(bits[1])! : 1
                tc.append( (tag, -exp) )
            }
            else {
                logU.error( "Undefined unit symbol: \(sym) in signature: \(from)" )
            }
        }
    }

    return tc
}


func getTypeSig( _ tc: TypeCode ) -> TypeSignature {
    ///
    ///  TypeCode -> TypeSignature
    ///
    if tc.isEmpty {
        return ""
    }
    let (_, exp0) = tc[0]
    var ss = exp0 < 0 ? "1/" : ""
    var negSeen: Bool = false
    var fn = 0

    for (tt, exp) in tc {
        
        if fn > 0 {
            if exp < 0 && !negSeen {
                ss.append("/")
                negSeen = true
            }
            else {
                ss.append( "·" )
            }
        }
        
        if let def = TypeDef.typeDict[tt],
           let sym = def.sym
        {
            ss.append( sym )
        }
        else {
            ss.append( "\(tt.description)" )
        }
        
        if abs(exp) > 1 {
            ss.append( "^\(abs(exp))" )
        }
        fn += 1
    }
    return ss
}


func toUnitCode( from: TypeCode ) -> UnitCode {
    ///
    /// TypeCode -> UnitCode
    ///     Reduce (km, 1) to (length, 1),   (sec, -2) to (time, -2)
    ///
    return from.map( { (tag, exp) in (tag.uid, exp) } )
}


// *************************************** UnitDef ************************************************** //

struct UserUnitData: Codable {
    
    /// Data describing user defined UnitDefs
    /// This struct will be persisted to storage
    ///
    
    var defList: [UnitDef] = []
    var uidNext: UnitId = userIdBase
}


class UnitDef: Codable {
    var uid:    UnitId
    var sym:    String?
    var uc:     UnitCode
    
    enum CodingKeys : String, CodingKey {
        case uid, sym, uc
        
        enum UnitCodeKeys: String, CodingKey {
            case uid, exp
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container( keyedBy: CodingKeys.self )
        try container.encode(uid, forKey: .uid)
        try container.encode(sym, forKey: .sym)
        
        var ucListContainer = container.nestedUnkeyedContainer( forKey: .uc)
        
        try uc.forEach { ucF in
            var ucCont = ucListContainer.nestedContainer( keyedBy: CodingKeys.UnitCodeKeys.self)
            
            try ucCont.encode( ucF.uid, forKey: .uid )
            try ucCont.encode( ucF.exp, forKey: .exp )
            
        }
    }
    
    
    required init( from decoder: Decoder ) throws {
        let container = try decoder.container( keyedBy: CodingKeys.self)
        
        uid = try container.decode( UnitId.self, forKey: .uid)
        sym = try container.decodeIfPresent( String.self, forKey: .sym)
        
        var ucListContainer = try container.nestedUnkeyedContainer( forKey: .uc)
        
        var ucList: UnitCode = []
        
        while !ucListContainer.isAtEnd {
            
            let ucCont = try ucListContainer.nestedContainer( keyedBy: CodingKeys.UnitCodeKeys.self)
            
            let uid = try? ucCont.decode( UnitId.self, forKey: .uid)
            let exp = try? ucCont.decode( Int.self, forKey: .exp)
            
            if let u = uid,
               let e = exp {
                ucList.append( (u, e) )
            }
        }
        self.uc = ucList
    }

    
    static func getUserUnitId() -> UnitId {
        
        /// Allocate new UnitId for type .user
        
        let uid = UnitDef.uud.uidNext
        UnitDef.uud.uidNext += 1
        return uid
    }
    
    init( _ uid: StdUnitId, sym: String, usig: UnitSignature? = nil ) {
        if uid == .user {
            // For defining unit definitions for standard predefined units only, not .user
            logU.error("Cannot define .user UnitDef without signature")
            assert(false)
        }
        
        self.uid = uid.rawValue
        self.sym = sym
        
        if let sig = usig {
            self.uc = toUnitCode(from: sig)
        }
        else {
            self.uc = [(self.uid, 1)]
        }
    }
    
    init( _ usig: UnitSignature, uid: UnitId, sym: String? = nil ) {
        // Allocate new UnitId starting at .user, sym is optional, UnitCode produced from signature
        self.uid = uid
        self.sym = sym
        self.uc = toUnitCode( from: usig )
    }
    
    // Data and indexes for standard pre-defined units
    static private var stdDefList:  [UnitDef]                 = []
    static private var symDict:     [String : UnitDef]        = [:]
    static private var sigDict:     [UnitSignature : UnitDef] = [:]

    // Persisted data describing user defined units
    static var uud: UserUnitData = UserUnitData()
    
    // Index dictionarys for the unit definitions - not persisted, rebuild on loading
    static private var symUserDict:  [String : UnitDef]        = [:]
    static private var sigUserDict:  [UnitSignature : UnitDef] = [:]
    
    
    static func fromSym( _ sym: String ) -> UnitDef? {
        
        /// Lookup function for unit definition from symbol
        /// Searches user defs then pre defined defs
        
        if let def = UnitDef.symUserDict[sym] {
            // User defined Unit def
            return def
        }
        return UnitDef.symDict[sym]
    }
    
    
    static func fromSig( _ usig: UnitSignature ) -> UnitDef? {
        
        /// Lookup function for unit definition from unit signature
        /// Searches user defs then pre defined defs
        
        if let def = UnitDef.sigUserDict[usig] {
            // User defined Unit def
            return def
        }
        return UnitDef.sigDict[usig]
    }
    
    
    static func defineUnit( _ uid: StdUnitId, _ usig: UnitSignature? = nil ) {
        let sym = String( describing: uid )
        let def = UnitDef( uid, sym: sym, usig: usig)
        
        UnitDef.stdDefList.append(def)

       // Add def to index by UnitId, Symbol and UnitSignature
        UnitDef.symDict[sym] = def
        UnitDef.sigDict[ getUnitSig(def.uc)] = def
    }
    
    
    static func defineUserUnit( _ usig: UnitSignature, uid uidProvided: UnitId? = nil, sym: String? = nil ) -> UnitDef {
        
        let uid = uidProvided ?? UnitDef.getUserUnitId()
        
        // Next uid must be greater than provided one
        UnitDef.uud.uidNext = max( UnitDef.uud.uidNext, uid+1 )
        
        let def = UnitDef(usig, uid: uid, sym: sym)
        
        UnitDef.uud.defList.append(def)
        
        // Add def to index by UnitSignature
        UnitDef.sigUserDict[usig] = def
        
        // Add def to index by Symbol if there is one
        if let symbol = sym {
            UnitDef.symUserDict[symbol] = def
        }
        
#if DEBUG
        print( "User UnitDef: '\(uid)' - > \(def)" )
#endif

        return def
    }
    
    
    static func reIndexUserUnits() {
        
        /// Rebuild the two index dictionarys after the User Unit Data has been reloaded
        
        UnitDef.symUserDict  = [:]
        UnitDef.sigUserDict  = [:]
        
        for def in UnitDef.uud.defList {
            
            if let sym = def.sym {
                // This definition has a symbol
                UnitDef.symUserDict[sym] = def
            }
            
            // Unit signature index
            let usig = getUnitSig(def.uc)
            UnitDef.sigUserDict[usig] = def
            
#if DEBUG
            print( "reIndexUserUnit: \(def)" )
#endif
        }
    }
    
    static func buildStdUnitData() {
        
        /// Define all the standard units
        
        UnitDef.defineUnit( .time )
        UnitDef.defineUnit( .mass )
        UnitDef.defineUnit( .temp )
        UnitDef.defineUnit( .angle )
        UnitDef.defineUnit( .length )
        UnitDef.defineUnit( .weight )
        UnitDef.defineUnit( .capacity )
        UnitDef.defineUnit( .area,          "length^2" )
        UnitDef.defineUnit( .volume,        "length^3" )
        UnitDef.defineUnit( .velocity,      "length/time" )
        UnitDef.defineUnit( .acceleration,  "length/time^2" )
        UnitDef.defineUnit( .pressure,      "weight/length^2" )
        
#if DEBUG
        // UnitDef
        print( "Predefined Unit Definitions:")
        for def in UnitDef.stdDefList {
            print( "UnitDef: \(def)" )
        }
#endif
    }
}

#if DEBUG
extension UnitDef: CustomStringConvertible {
    var description: String {
        return "<\(uid2Str(self.uid)):\(String( describing: sym)):'\(getUnitSig(uc))'>"
    }
}
#endif

// ***************************************************************************************** //


struct UserTypeDef : Codable {
    var tid:  TypeId
    var uid:  UnitId
    var tsig: TypeSignature
    
    init( _ tid: TypeId, _ uid: UnitId, _ tsig: TypeSignature) {
        self.tid = tid
        self.uid = uid
        self.tsig = tsig
    }
}


class TypeDef {
    var uid:   UnitId
    var tid:   TypeId
    var tc:    TypeCode
    var kc:    KeyCode?
    var sym:   String?
    var ratio: Double
    var delta: Double
    
    static var tidNext: TypeId = 0
    
    static var tidUserNext: TypeId = 1000

    static func getNewTid() -> TypeId {
        // Allocate next type id
        let tid = TypeDef.tidNext
        tidNext += 1
        return tid
    }

    static func getNewUserTid() -> TypeId {
        // Allocate next type id
        let tid = TypeDef.tidUserNext
        tidUserNext += 1
        return tid
    }
    
    init() {
        self.uid = StdUnitId.untyped.rawValue
        self.tid = 0
        self.tc  = []
        self.kc  = nil
        self.sym = nil
        self.ratio = 1.0
        self.delta = 0.0
    }
    
    init( _ uid: StdUnitId, _ kc: KeyCode, sym: String, _ ratio: Double, delta: Double = 0.0 ) {
        self.uid = uid.rawValue
        self.tid = TypeDef.getNewTid()
        self.sym = sym
        self.ratio = ratio
        self.delta = delta
        self.tc = [(TypeTag(uid, tid), 1)]
        self.kc = kc
    }

    init( tid: TypeId, uid: UnitId, tsig: TypeSignature ) {
        self.tid = tid
        self.uid = uid
        self.ratio = 1.0
        self.delta = 0
        self.tc = toTypeCode( from: tsig)
        self.kc = nil
    }
    
    var symbol: String {
        if let str = self.sym {
            return str
        }
        else {
            return getTypeSig(self.tc)
        }
    }
    
    static var typeDict: [TypeTag : TypeDef]       = [tagUntyped : TypeDef()]
    static var symDict:  [String : TypeTag]        = [:]
    static var sigDict:  [TypeSignature : TypeTag] = [:]
    static var kcDict:   [KeyCode : TypeTag]       = [:]
    
    static func clearTypeData() {
        TypeDef.typeDict = [tagUntyped : TypeDef()]
        TypeDef.symDict  = [:]
        TypeDef.sigDict  = [:]
        TypeDef.kcDict   = [:]
        TypeDef.tidNext  = 0
    }
    
    static var userTypeDefs: [UserTypeDef] = []
    
    static func tagOf( _ sym: String ) -> TypeTag {
        // Required tag lookup or else bug
        guard let tag = TypeDef.symDict[sym] else {
            fatalError()
        }
        return tag
    }
    
    
    static func defineStdType( _ uid: StdUnitId, _ kc: KeyCode, _ sym: String, _ ratio: Double, delta: Double = 0.0 ) {
        
        let def = TypeDef(uid, kc, sym: sym, ratio, delta: delta)
        let tag = TypeTag(uid, def.tid)
        
        TypeDef.typeDict[tag] = def
        TypeDef.symDict[sym] = tag
        TypeDef.sigDict[sym] = tag
        TypeDef.kcDict[kc] = tag
    }
    
    
    static func addUserType( tid: TypeId,  uid: UnitId, _ tsig: TypeSignature ) -> TypeDef {
        
        TypeDef.tidUserNext = max( TypeDef.tidUserNext, tid+1 )
        
        let def = TypeDef( tid: tid, uid: uid, tsig: tsig)
        let tag = TypeTag(def.uid, def.tid)
        
        TypeDef.typeDict[tag] = def
        TypeDef.sigDict[tsig] = tag
        
        return def
    }
    
    
    static func redefineUserTypes() {
        
        for utd in TypeDef.userTypeDefs {
            _ = TypeDef.addUserType( tid: utd.tid, uid: utd.uid, utd.tsig)
        }
    }

    
    static func defineUserType( tid tidProvided: TypeId? = nil, uid: UnitId, _ tsig: TypeSignature ) {
        
        let tid = tidProvided ?? TypeDef.getNewUserTid()
        
        TypeDef.tidUserNext = max( TypeDef.tidUserNext, tid+1 )
        
        _ = addUserType( tid: tid, uid: uid, tsig)
        
        TypeDef.userTypeDefs.append( UserTypeDef(tid, uid, tsig) )
    }
    
    
    static func buildStdTypeData() {
        
        defineStdType( .length, .metre,  "m",1)
        defineStdType( .length, .mm, "mm",   1000)
        defineStdType( .length, .cm, "cm",   100)
        defineStdType( .length, .km, "km",   0.001)
        
        defineStdType( .length, .inch, "in",   1000/25.4)
        defineStdType( .length, .ft,   "ft",   1000/(12*25.4))
        defineStdType( .length, .yd,   "yd",   1000/(36*25.4))
        defineStdType( .length, .mi,   "mi",   1000/(5280*12*25.4))

        // Angular units
        defineStdType( .angle,  .rad,  "rad",  1)
        defineStdType( .angle,  .deg,  "deg",  180/Double.pi)
        defineStdType( .angle,  .minA, "minA", 180/Double.pi * 60.0)

        defineStdType( .time,  .second,   "sec",  1.0)
        defineStdType( .time,  .min,   "min",  1.0/60)
        defineStdType( .time,  .hr,    "hr",   1.0/(60*60))
        defineStdType( .time,  .day,   "day",  1.0/(24*60*60))
        defineStdType( .time,  .yr,    "yr",   1.0/(365*24*60*60))
        defineStdType( .time,  .ms,    "ms",   1000.0)
        defineStdType( .time,  .us,    "\u{03BC}s", 1000000.0)

        defineStdType( .mass,  .kg,    "kg",   1)
        defineStdType( .mass,  .gram,  "g",    1000.0)
        defineStdType( .mass,  .mg,    "mg",   1000*1000.0)
        defineStdType( .mass,  .tonne, "tn",   0.001)

        defineStdType( .mass, .lb,    "lb",   2.2046226218488)
        defineStdType( .mass, .oz,    "oz",   2.2046226218488 * 16.0)
        defineStdType( .mass, .ton,   "ton",  2.2046226218488 / 2000.0)
        defineStdType( .mass, .stone, "st",   2.2046226218488 / 14.0)
        
        defineStdType( .capacity, .mL,    "mL",        1.0)
        defineStdType( .capacity, .liter, "L",         1.0/1000)
        defineStdType( .capacity, .floz,  "fl-oz",     1.0/29.5735295625)
        defineStdType( .capacity, .cup,   "cup",       1.0/(29.5735295625 * 8))
        defineStdType( .capacity, .pint,  "pint",      1.0/(29.5735295625 * 16))
        defineStdType( .capacity, .quart,  "quart",    1.0/(29.5735295625 * 32))
        defineStdType( .capacity, .us_gal,"US-gal",    1.0/(29.5735295625 * 128))
        defineStdType( .capacity, .gal,   "gal",       1.0/(1000 * 4.54609))

        defineStdType( .temp, .degC,    "C",    1.0)
        defineStdType( .temp, .degF,    "F",    9.0/5.0, delta: 32)
        
        #if DEBUG
        print( "\nType Definitions:")
        for (tt, def) in TypeDef.typeDict {
            print( "\(tt) -> \(def)")
        }
        #endif
    }
}


#if DEBUG
extension TypeDef: CustomStringConvertible {
    var description: String {
        return "<\(String(describing: uid)):\(String( describing: sym)) tid:\(tid)>"
    }
}
#endif


func normalizeUnitCode( _ uc: inout UnitCode ) {
    
    uc.sort { (xUC, yUC) in
        let (xUid, xExp) = xUC
        let (yUid, yExp) = yUC
        
        if xExp*yExp < 0 {
            return xExp > yExp
        }
        
        return xUid < yUid
    }
}


func normalizedUC( _ uc: UnitCode ) -> UnitCode {
    var ucV = uc
    normalizeUnitCode(&ucV)
    return ucV
}


func normalizeTypeCode( _ tc: inout TypeCode ) {
    
    tc.sort { (xTC, yTC) in
        let (xTT, xExp) = xTC
        let (yTT, yExp) = yTC
        
        if xExp*yExp < 0 {
            return xExp > yExp
        }
        
        return xTT.uid < yTT.uid
    }
}


protocol UnitConversionOp {
    func op( _ x: Double ) -> Double
    
    func opRev( _ x: Double ) -> Double
}

struct OffsetOp : UnitConversionOp {
    let offset: Double
    
    init( _ offset: Double ) {
        self.offset = offset
    }
    
    func op( _ x: Double ) -> Double {
        return x + offset
    }
    
    func opRev( _ x: Double ) -> Double {
        return x - offset
    }
}

struct ScaleOp : UnitConversionOp {
    let scale: Double
    
    init( _ scale: Double ) {
        self.scale = scale
    }
    
    func op( _ x: Double ) -> Double {
        return x * scale
    }
    
    func opRev( _ x: Double ) -> Double {
        return x / scale
    }
}

struct ConversionSeq : UnitConversionOp {
    var opSeq: [UnitConversionOp]
    
    init( _ seq: [UnitConversionOp] ) {
        self.opSeq = seq
    }
    
    init( _ ratio: Double ) {
        self.opSeq = [ ScaleOp(ratio) ]
    }
    
    func op( _ x: Double ) -> Double {
        var y = x
        for s in opSeq {
            y = s.op(y)
        }
        return y
    }

    func opRev( _ x: Double ) -> Double {
        var y = x
        for s in opSeq.reversed() {
            y = s.opRev(y)
        }
        return y
    }
}


func unitConvert( from: TypeTag, to: TypeTag ) -> ConversionSeq? {
    if from.uid == uidUntyped {
        // An untyped value can convert to anything - no change in value
        return ConversionSeq(1.0)
    }
    
    if from.uid != to.uid {
        // Cannot convert incompatible units like angles and areas
        return nil
    }
    
    if let defF = TypeDef.typeDict[from],
       let defT = TypeDef.typeDict[to]
    {
        return ConversionSeq( defT.ratio / defF.ratio )
    }
    
    // Failed to find definitions for both types, conversion not possible
    return nil
}


func typeAddable( _ tagA: TypeTag, _ tagB: TypeTag ) -> Double? {
    /// typeAddable( )
    /// Determine if it is possible to add (or subtract) B to/from A
    /// Return the value conversion ratio to be applied to B to make it compatible with A
    ///
    if tagA == tagUntyped && tagB != tagUntyped {
        // Cannot convert B operand back to untyped
        return nil
    }
    
    if tagA == tagB || tagB == tagUntyped {
        // A is same as B or B is untyped and can be tagged same as A
        // No value conversion, one to one
        return 1.0
    }
    
    // Unit signatures must match
    if let aDef = TypeDef.typeDict[tagA],
       let bDef = TypeDef.typeDict[tagB]
    {
        let ucA = toUnitCode(from: aDef.tc)
        let ucB = toUnitCode(from: bDef.tc)
        
        if  getUnitSig(ucA) != getUnitSig(ucB) {
            // Incompatible types
            return nil
        }
        
        var ratio: Double = 1.0

        for (aFac, bFac) in zip( aDef.tc, bDef.tc) {
            let (aTag, aExp) = aFac
            let (bTag, bExp) = bFac
            
            if let afDef = TypeDef.typeDict[aTag],
               let bfDef = TypeDef.typeDict[bTag]
            {
                // Convert B value to A units
                ratio /= pow(bfDef.ratio, Double(bExp))
                ratio *= pow(afDef.ratio, Double(aExp))
            }
            else {
                // Unknown type factor
                return nil
            }
        }
        
        // Return resulting value ratio
        return ratio
    }
    else {
        // Unkown types
        return nil
    }
}


func typeProduct( _ tagA: TypeTag, _ tagB: TypeTag, quotient: Bool = false ) -> (TypeTag, Double)? {
    /// typeProduct( )
    /// Produce type code of product A*B or quotient A/B
    /// Returns new resulting type code and ratio to convert value
    ///
    if tagB == tagUntyped {
        return (tagA, 1.0)
    }
    
    if tagA == tagUntyped {
        if !quotient {
            // Product of untyped * typed
            return (tagB, 1.0)
        }
        
        // quotient of untyped/typed, fall through to compute inverse of type
    }
    
    if let defA = TypeDef.typeDict[tagA],
       let defB = TypeDef.typeDict[tagB]
    {
        // Obtain type code sequences for both operands
        let tcA = defA.tc
        var tcB = defB.tc
        
        var tcQ: TypeCode = []
        
        let sign: Int = quotient ? -1 : 1
        
        var ratio: Double = 1.0
        
        // For each unit factor in A
        for (ttA, expA) in tcA {
            if let x = tcB.firstIndex( where: { (ttB, expB) in ttB == ttA } ) {
                // There is a matching unit in B, combine the exponents and add to result if exp is nonzero
                let (_, expB) = tcB[x]
                let exp = expA + sign*expB
                if exp != 0 {
                    tcQ.append( (ttA, exp) )
                }
                tcB.remove(at: x)
            }
            else if let y = tcB.firstIndex ( where: { (ttB, expB) in ttB.uid == ttA.uid } ) {
                // A and B are compatible types like cm and km
                let (ttB, expB) = tcB.remove(at: y)
                
                if let defA = TypeDef.typeDict[ttA],
                   let defB = TypeDef.typeDict[ttB]
                {
                    // Compute the ratio of the compatible types cm/km, add to result is nonzero exp
                    let exp = expA + sign*expB
                    if exp != 0 {
                        tcQ.append( (ttA, exp) )
                    }
                    ratio *= sign == 1 ? defA.ratio/defB.ratio : defB.ratio/defA.ratio
                }
            }
            else {
                // Unit ttA does not appear in B, keep it in the result
                tcQ.append( (ttA, expA) )
            }
        }
        
        // Append remaining elements of B that did not appear in A
        for (tagB, expB) in tcB {
            tcQ.append( (tagB, sign*expB) )
        }
        
        normalizeTypeCode(&tcQ)
        
        if let tagQ = lookupTypeTag(tcQ) {
            return (tagQ, ratio)
        }
        else {
            // No tag for resulting type
            return nil
        }
        
    }
    return  nil
}


func typeExponent( _ tagY: TypeTag, x: Int ) -> TypeTag? {
    
    if let yDef = TypeDef.typeDict[tagY] {
        let tcY: TypeCode = yDef.tc
        var tcQ: TypeCode = []
        
        for (tag, exp) in tcY {
            tcQ.append( (tag, exp*x) )
        }
        
        normalizeTypeCode(&tcQ)
        return lookupTypeTag(tcQ)
    }
    
    // Undefined type Y
    return nil
}


func typeNthRoot( _ tagY: TypeTag, n: Int ) -> TypeTag? {
    
    if let yDef = TypeDef.typeDict[tagY] {
        let tcY: TypeCode = yDef.tc
        var tcQ: TypeCode = []
        
        for (tag, exp) in tcY {
            if exp % n != 0 {
                return nil
            }
            tcQ.append( (tag, exp/n) )
        }
        
        normalizeTypeCode(&tcQ)
        return lookupTypeTag(tcQ)
    }
    
    // Undefined type Y
    return nil
}


func lookupTypeTag( _ tc: TypeCode ) -> TypeTag? {
    /// lookupTypeTag( TypeCode ) -> TypeTag
    /// Find a type tag for the provided type code sequence
    ///
    if tc.isEmpty {
        // An untyped value has no units
        return tagUntyped
    }
    
    let tsig = getTypeSig(tc)
    
    if let tag = TypeDef.sigDict[tsig] {
        // Matching tag is already defined
        return tag
    }
    else {
        // Find the unit signature from type code, 
        // [(km,1),(sec,-1)] -> [(length,1),(time,-1)] -> "length/time"
        //
        let uc = toUnitCode( from: tc )
        let usig = getUnitSig(uc)
        
        if let unit = UnitDef.fromSig(usig) {
            // Unit def already exists, add type def
            TypeDef.defineUserType( uid: unit.uid, tsig)
        }
        else {
            let unit = UnitDef.defineUserUnit(usig)
            TypeDef.defineUserType( uid: unit.uid, tsig)
        }
        
        return TypeDef.sigDict[tsig]
    }
}


// Common tag values
let tagUntyped = TypeTag(.untyped)
let tagRad     = TypeDef.tagOf("rad")
let tagDeg     = TypeDef.tagOf("deg")
let tagMinA    = TypeDef.tagOf("minA")
