//
//  Symbol.swift
//  Computor
//
//  Created by Barry Hall on 2025-07-14.
//

import SwiftUI


struct SymbolTag: Hashable, Codable, Equatable, CustomStringConvertible {
    
    var tag: UInt64
}


typealias SymbolSet = Set<SymbolTag>


func symCodeToKeyCode( _ symCode: UInt64 ) -> KeyCode? {
    
    if Int(symCode) >= KeyCode.symbolCharEnd.rawValue {
        return nil
    }
    let kc = KeyCode( rawValue:  Int(symCode) + KeyCode.symbolCharNull.rawValue )
    return kc
}


func keyCodeToSymCode( _ kc: KeyCode ) -> UInt64 {
    
    if kc.rawValue > KeyCode.symbolCharNull.rawValue && kc.rawValue < KeyCode.symbolCharEnd.rawValue {
        
        let code = UInt64(kc.rawValue - KeyCode.symbolCharNull.rawValue)
        return code
    }
    return 0
}


extension SymbolTag {
    
    // Starting mod values for User modules and builtin system modules
    
    // User Modules 0 .. 99
    static let firstUserMod  = 0
    
    // System Modules 100 .. 199
    static let firstSysMod = 100
    
    // Special Module codes
    static let localMemMod = 200
    static let keycodeMod  = 201
    
    var isNull:  Bool { self == SymbolTag.Null  }
    var isBlank: Bool { self == SymbolTag.Blank }
    var isModal: Bool { self == SymbolTag.Modal }

    var length: Int {
        var chrs: UInt64 = self.tag & Const.Symbol.chrMask
        
        if chrs == 0 { return 0 }
        
        for n in 1 ..< Const.Symbol.maxChars {
            chrs >>= Const.Symbol.charBits
            if chrs & Const.Symbol.byteMask == 0 {
                return n
            }
        }
        return Const.Symbol.maxChars
    }
    
    var isShortSym: Bool { self.length < 4 }
    
    var isSingleChar: Bool { (tag & Const.Symbol.firstCharMask != 0) && (tag & ~Const.Symbol.firstCharMask == 0) }
    
    var mod: Int { Int(tag >> Const.Symbol.modShift & Const.Symbol.byteMask) }
    
    var isUserMod: Bool { self.mod < 100 }
    var isSysMod: Bool { self.mod >= 100 }
    
    // Local to current module
    var isLocalTag: Bool { self.mod == 0 }
    
    // Local memory tag - no conflict with macro symbols
    var isLocalMemoryTag: Bool { self.mod == SymbolTag.localMemMod }
    
    // KeyCode tag - representing one general KeyCode value
    var isKeycodeTag: Bool { self.mod == SymbolTag.keycodeMod }
    
    func getKeycode() -> KeyCode? {
        if self.isKeycodeTag {
            // Extract general KeyCode, not just a sym char
            let code = (tag & Const.Symbol.modMask)
            return KeyCode( rawValue: Int(code))
        }
        return nil
    }

    var description: String { self.getRichText() }
    
    func getSymbolText( symName: String, subPt: Int, superPt: Int ) -> String {
        
        if self.isKeycodeTag {
            let code = (tag & Const.Symbol.modMask)
            let kc = KeyCode( rawValue: Int(code))
            return kc?.str ?? ""
        }
        
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
        
        // symN is 4...6
        assert( (subPt*superPt == 0) && (subPt+superPt >= 2) )
        assert( symN <= 6 )
        
        let op = subPt > 0 ? "_" : "^"
        let pt = subPt + superPt
        
        var str = "\(symA[0])"
        var x = 1

        while x < pt-1 {
            
            str += String(symA[x])
            x += 1
        }
        
        str += "\(op){"
        
        while x < symN {
            
            str += String(symA[x])
            x += 1
        }
        str += "}"
        return str
    }
    

    func getSymSpecs() -> ( String, [KeyCode], Int, Int, Int ) {
        
        if isNull || isBlank || isModal {
            return ( "", [], 0, 0, mod )
        }
        
        if isSingleChar {
            let code = self.tag & Const.Symbol.byteMask
            let kc = symCodeToKeyCode(code) ?? KeyCode.null
            let s = kc.str
            return ( String(s), [kc], 0, 0, mod )
        }
        else {
            // Eliminate mod from tag
            var code = (tag & Const.Symbol.modMask)
            var symS = ""
            var kcA: [KeyCode] = []
            
            for _ in 1...Const.Symbol.maxChars {
                let y = code & Const.Symbol.byteMask
                
                if y != 0 {
                    let kc = symCodeToKeyCode(y) ?? KeyCode.null
                    symS.append( kc.str )
                    kcA.append( kc )
                }
                
                code >>= Const.Symbol.charBits
            }
            
            let superPt: Int = Int( code & Const.Symbol.superMask )
            let subPt: Int   = Int( code >> Const.Symbol.superBits & Const.Symbol.superMask )
            
            return (symS, kcA, subPt, superPt, mod)
        }
    }
    
    func getRichText() -> String {
        
        if isNull || isBlank || isModal {
            return ""
        }
        
        if isSingleChar {
            let code = self.tag & Const.Symbol.byteMask
            let kc = symCodeToKeyCode(code) ?? KeyCode.null
            let s = kc.str
            return s
        }
        else {
            // Eliminate mod value from tag
            var code = (tag & Const.Symbol.modMask)
            var symS = ""
            
            for _ in 1...Const.Symbol.maxChars {
                let y = code & Const.Symbol.byteMask

                if y != 0 {
                    let kc = symCodeToKeyCode(y) ?? KeyCode.null
                    symS.append( kc.str )
                }
                
                code >>= Const.Symbol.charBits
            }
            
            let superPt: Int = Int( code & Const.Symbol.superMask )
            let subPt: Int   = Int( code >> Const.Symbol.superBits & Const.Symbol.superMask )
            
            return getSymbolText(symName: symS, subPt: subPt, superPt: superPt)
        }
    }
    
    
    init( _ localTag: SymbolTag, mod: Int ) {
        
        // Create a remote reference tag by adding a module index
        let modValue = UInt64(mod)
        self.tag = localTag.tag & Const.Symbol.modMask | modValue << Const.Symbol.modShift
    }
    
    
    var localTag: SymbolTag { SymbolTag(self, mod: 0) }

    
    init( _ kc: KeyCode = .null ) {
        
        /// Create a SymbolTag from a KeyCode
        /// If kc is F1..F6, lookup encoded symbol version
        /// if other kc, just store the kd rawValue
        
        if let fnTag = SymbolTag.getKeyCodeSym(kc) {
            
            // Split .F1 KeyCode to [.F, .d1]
            self.tag = fnTag.tag
        }
        else if kc.rawValue > KeyCode.symbolCharNull.rawValue && kc.rawValue < KeyCode.symbolCharEnd.rawValue {
            self.tag = keyCodeToSymCode(kc)
        }
        else {
            // Encode a general key code
            self.tag = UInt64(kc.rawValue + SymbolTag.keycodeMod)
        }
    }
   
    
    init( _ symA: [KeyCode], subPt: Int = 0, superPt: Int = 0, mod: Int = 0 ) {
        
        /// Create SymbolTag
        
        // Symbol Format - decimal digits in an Int
        //   mm s S aaa bbb ccc
        //   mm  - mod, module index
        //   s   - subPt
        //   S   - superPt
        //   aaa - rightmost sym KeyCode
        //   bbb - middle sym
        //   ccc - first sym
        
        assert( symA.count > 0 && symA.count <= Const.Symbol.maxChars )
        assert( subPt*superPt == 0 && subPt+superPt <= Const.Symbol.maxChars && subPt+superPt != 1 )
        assert( mod >= 0 && mod < 100 )
        
        var tag: UInt64 = 0
        
        for kc in symA.reversed() {
            
            let code = keyCodeToSymCode(kc)
            tag <<= Const.Symbol.charBits
            tag |= code
        }
        
        tag |= UInt64(mod) << Const.Symbol.modShift
        tag |= UInt64(subPt) << Const.Symbol.subShift
        tag |= UInt64(superPt) << Const.Symbol.superShift
        
        self.tag = tag
    }
    
    // ****** Static Fields
    
    static var fnSym: [ KeyCode : SymbolTag ] = [
        .F1 : SymbolTag( [.F, .d1]),
        .F2 : SymbolTag( [.F, .d2]),
        .F3 : SymbolTag( [.F, .d3]),
        .F4 : SymbolTag( [.F, .d4]),
        .F5 : SymbolTag( [.F, .d5]),
        .F6 : SymbolTag( [.F, .d6]),
        
        .U1 : SymbolTag( [.U, .d1]),
        .U2 : SymbolTag( [.U, .d2]),
        .U3 : SymbolTag( [.U, .d3]),
        .U4 : SymbolTag( [.U, .d4]),
        .U5 : SymbolTag( [.U, .d5]),
        .U6 : SymbolTag( [.U, .d6]),
    ]
    
    static func getKeyCodeSym( _ kc: KeyCode ) -> SymbolTag? {
        
        /// ** Get KeyCode Sym **
        
        if kc.isFuncKey {
            // Symbol associated with F1..F6 and U1..U6
            return SymbolTag.fnSym[kc]
        }
        
        if ( kc.isLowerAlpha || kc.isUpperAlpha || kc.isGreekAlpha ) {
            return SymbolTag( [kc] )
        }
        
        return nil
    }
    
    static var Null: SymbolTag { SymbolTag(.null) }
    static var Blank: SymbolTag { SymbolTag(.blankChar) }
    static var Modal: SymbolTag { SymbolTag(.modalChar) }
}


// *** SYMBOL EDIT POPUP ***

typealias SymbolContinuationClosure = ( _ symTag: SymbolTag ) -> Void


struct NewSymbolPopup: View, KeyPressHandler {
    
    @Environment(CalculatorModel.self) var model
    @Environment(KeyData.self) var keyData
    
    @State private var charSet = CharSet.upper
    @State private var symName = ""
    @State private var symN    = 0
    
    // Can be 0 2 or 3, only one can be non-zero
    @State private var superPt = 0
    @State private var subPt   = 0
    
    @State private var symArray: [KeyCode] = []
    
    // Pre-existing symbol can be provided
    var tag: SymbolTag = SymbolTag.Null
    
    var radius = 10.0
    var frameWidth = 0.0
    
    var scc: SymbolContinuationClosure
    
    enum CharSet: Int {
        case upper = 0, lower, greek, script, digit
        
        var nextSet: CharSet {
            switch self {
            case .upper:    return .lower
            case .lower:    return .greek
            case .greek:    return .script
            case .script:   return .digit
            case .digit:    return .upper
            }
        }
    }
    
    let setList: [CharSet] = [.upper, .lower, .greek, .script, .digit]
    
    let padList: [PadSpec] = [psAlpha, psAlphaLower, psGreek, psScript, psDigits]
    
    let setLabels = ["ABC", "abc", "\u{03b1}\u{03b2}\u{03b3}", "\u{1D4D0}\u{1D4D1}\u{1D4D2}", "123"]
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        if symN < Const.Symbol.maxChars {
            let ch = event.kc.str
            symName.append(ch)
            symArray.append( event.kc )
        }
        return KeyPressResult.modalPopupContinue
    }
    
    
    func reset() {
        // Clear symbol name
        subPt = 0
        superPt = 0
        symN = 0
        symName = ""
        symArray = []
    }
    
    
    let dashStr: [String] = [
        "------", "-----", "----", "---", "--", "-", ""
    ]
    
    
    func getSymbolText() -> String {
        
        if symN == 0 {
            // Placeholder text
            return "ƒ{2.0}ç{GrayText}\(dashStr[0])"
        }
        
        if symN == 1 || (subPt == 0 && superPt == 0) {
            // No sub or superscripts
            return "ƒ{2.0}\(symName)ç{GrayText}\(dashStr[symN])"
        }
        
        let symA = Array(symName)
        
        if symN == 2 {
            assert( (subPt*superPt == 0) && (subPt+superPt == 2) )
            
            let op = subPt > 0 ? "_" : "^"
            
            return "ƒ{2.0}\(symA[0])\(op){\(symA[1])}ç{GrayText}\(op){\(dashStr[symN])}"
        }
        
        // symN is 4...6
        assert( (subPt*superPt == 0) && (subPt+superPt >= 2) )
        assert( symN <= Const.Symbol.maxChars )
        
        let op = subPt > 0 ? "_" : "^"
        let pt = subPt + superPt
        
        var str = "\(symA[0])"
        var x = 1
        
        while x < pt-1 {
            
            str += String(symA[x])
            x += 1
        }
        
        str += "\(op){"
        
        while x < symN {
            
            str += String(symA[x])
            x += 1
        }
        str += "}"
        return "ƒ{2.0}\(str)ç{GrayText}\(op){\(dashStr[symN])}"
    }
    
    var body: some View {
        
        VStack( alignment: .center ) {
            RichText( getSymbolText(), size: .normal, defaultColor: "BlackText").padding( [.top], 20 )
            
            KeypadView( padSpec: padList[charSet.rawValue], keyPressHandler: self )
                .padding( [.leading, .trailing, .bottom] )
            
            HStack {
                Button( "", systemImage: "arrowshape.left.arrowshape.right" ) {
                    charSet = charSet.nextSet
                }
                
                HStack {
                    ForEach ( setList, id: \.self ) { cs in
                        Text( setLabels[cs.rawValue] )
                            .if ( cs == charSet ) { txt in
                                // Add border around selected char set
                                txt.overlay(
                                    RoundedRectangle( cornerRadius: 5).inset(by: -1).stroke(.blue, lineWidth: 1) )
                            }
                    }
                }
            }.padding( [.bottom], 12)
            
            HStack( spacing: 20 ) {
                
                // CLEAR X
                Button( action: {
                    reset()
                })
                {
                    Image( systemName: "clear" )
                }
                .disabled( symN == 0 )
                
                // SUBSCRIPT DOWN
                Button( action: {
                    if symN >= 2 && subPt == 0 {
                        
                        if superPt != 0 {
                            // Return to flat text
                            superPt = 0
                        }
                        else {
                            // Add subscript point
                            subPt = symN
                        }
                    }
                })
                {
                    Image( systemName: "arrowshape.down" )
                }
                .disabled( symN < 2 || subPt > 0 )
                
                // SUPERSCRIPT UP
                Button( action: {
                    if symN >= 2 && superPt == 0 {
                        
                        if subPt != 0 {
                            // Return to flat text
                            subPt = 0
                        }
                        else {
                            // Add superscript point
                            superPt = symN
                        }
                    }
                })
                {
                    Image( systemName: "arrowshape.up" )
                }
                .disabled( symN < 2 || superPt != 0 )
                
                // DELETE LEFT
                Button( action: {
                    if symN > 0 {
                        symN -= 1
                        symName.removeLast()
                        symArray.removeLast()
                        
                        if subPt+superPt > symN {
                            // BugFix
                            subPt = 0
                            superPt = 0
                        }
                    }
                })
                {
                    Image( systemName: "delete.left" )
                }
                .disabled( symN == 0 )
                
                // OK  button, symbol selected
                Button( action: {
                    
                    if symN > 0 {
                        // Create symbol Tag
                        let tag = SymbolTag( symArray, subPt: subPt, superPt: superPt )
                        
                        // Process tag in parent view
                        scc( tag )
                    }
                })
                {
                    Image( systemName: "checkmark.diamond.fill" )
                }
                .accentColor( Color.green )
                .disabled( symN == 0 || (subPt+superPt == 0) && (symName == "F1" || symName == "F2" || symName == "F3" || symName == "F4" || symName == "F5" || symName == "F6") )
                
            }.padding( [.bottom], 20)
        }
        .frame( maxWidth: .infinity )
        .accentColor( .black )
        .background() {
            
            Color( "SuperLightGray")
                .cornerRadius(radius)
                .border(Color("Frame"), width: frameWidth)
                .padding( [.leading, .trailing], 20 )
                .padding( [.top, .bottom], 5 )
        }
        .onAppear() {
            // Initialize provided tag specs
            let (str, arr, subPt, superPt, _) = tag.getSymSpecs()
            self.symName = str
            self.symArray = arr
            self.subPt = subPt
            self.superPt = superPt
            self.symN = str.count
        }
        .onChange( of: symName, initial: true ) {
            symN = symName.count
            
            if symN == 0 {
                // Back to zero chars, first can't be a digit
                charSet = CharSet.upper
            }
            
            if symN < 2 {
                // Reset subscript/superscript points if only one char
                superPt = 0
                subPt = 0
            }
        }
    }
}
