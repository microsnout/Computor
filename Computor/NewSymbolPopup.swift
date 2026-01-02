//
//  NewSymbolPopup.swift
//  Computor
//
//  Created by Barry Hall on 2026-01-01.
//

import SwiftUI


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
    
    @State private var symAvailable: Bool = false
    
    // Pre-existing symbol can be provided
    var tag: SymbolTag = SymbolTag.Null
    var modCode: Int   = 0
    
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
            symAvailable = isAvailable()
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
        symAvailable = false
    }
    
    
    func isAvailable() -> Bool {
        
        let tag = SymbolTag( symArray, subPt: subPt, superPt: superPt, mod: modCode )
        
        if modCode == SymbolTag.globalMemMod {
            
            if let _ = model.getMemory(tag) {
                // Memory already exists with this tag
                return false
            }
        }
        else if let _ = model.getLocalMacro(tag) {
            // Macro already exists with this tag
            return false
        }
        
        // Tag is available
        return true
    }
    
    
    let dashStr: [String] = [
        "------", "-----", "----", "---", "--", "-", ""
    ]
    
    
    func getSymbolText() -> String {
        
        if symN == 0 {
            // Placeholder text
            return "ƒ{2.0}ç{GrayText}\(dashStr[0])ç{}"
        }
        
        if symN == 1 || (subPt == 0 && superPt == 0) {
            // No sub or superscripts
            return "ƒ{2.0}\(symName)ç{GrayText}\(dashStr[symN])ç{}"
        }
        
        let symA = Array(symName)
        
        if symN == 2 {
            assert( (subPt*superPt == 0) && (subPt+superPt == 2) )
            
            let op = subPt > 0 ? "_" : "^"
            
            return "ƒ{2.0}\(symA[0])\(op){\(symA[1])}ç{GrayText}\(op){\(dashStr[symN])}ç{}"
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
        return "ƒ{2.0}\(str)ç{GrayText}\(op){\(dashStr[symN])}ç{}"
    }
    
    var body: some View {
        
        let symText = (symN == 0 || symAvailable) ? getSymbolText() : "\(getSymbolText()) ƒ{0.8}[Not available]"
        
        VStack( alignment: .center ) {
            RichText( symText, size: .normal, defaultColor: "BlackText").padding( [.top], 20 )
            
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
                        symAvailable = isAvailable()
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
                        symAvailable = isAvailable()
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
                        symAvailable = isAvailable()
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
                        let tag = SymbolTag( symArray, subPt: subPt, superPt: superPt, mod: modCode )
                        
                        // Process tag in parent view
                        scc( tag )
                    }
                })
                {
                    Image( systemName: "checkmark.diamond.fill" )
                }
                .accentColor( Color.green )
                .disabled( !symAvailable || (subPt+superPt == 0) && (symName == "F1" || symName == "F2" || symName == "F3" || symName == "F4" || symName == "F5" || symName == "F6") )
                
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
