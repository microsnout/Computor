//
//  Symbol.swift
//  Computor
//
//  Created by Barry Hall on 2025-07-14.
//

import SwiftUI


typealias SymbolContinuationClosure = ( _ symTag: SymbolTag ) -> Void


struct NewSymbolPopup: View, KeyPressHandler {
    
    @EnvironmentObject var model: CalculatorModel
    @EnvironmentObject var keyData: KeyData
    
    @AppStorage(.settingsKeyCaptions)
    private var greekKeys = false
    
    @State private var charSet = CharSet.upper
    @State private var symName = ""
    @State private var symN    = 0
    
    // Can be 0 2 or 3, only one can be non-zero
    @State private var superPt = 0
    @State private var subPt   = 0
    
    @State private var symArray: [KeyCode] = []
    
    // Pre-existing symbol can be provided
    var tag: SymbolTag = SymbolTag(.null)
    var scc: SymbolContinuationClosure
    
    enum CharSet: Int {
        case upper = 0, lower, greek, digit
        
        var nextSet: CharSet {
            switch self {
            case .upper:    return .lower
            case .lower:    return .greek
            case .greek:    return .digit
            case .digit:    return .upper
            }
        }
        
        var nextSetZero: CharSet {
            switch self {
            case .upper:    return .lower
            case .lower:    return .greek
            case .greek:    return .upper
            case .digit:    return .upper
            }
        }
    }
    
    let setList: [CharSet] = [.upper, .lower, .greek, .digit]
    
    let padList: [PadSpec] = [psAlpha, psAlphaLower, psGreek, psDigits]
    
    let setLabels = ["ABC", "abc", "\u{03b1}\u{03b2}\u{03b3}", "123"]
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        if symN < 3 {
            // Max three char in symbol
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
    
    
    func getSymbolText() -> String {
        
        if symN == 0 {
            // Placeholder text
            return "ƒ{2.0}ç{GrayText}---"
        }
        
        if symN == 1 || (subPt == 0 && superPt == 0) {
            // No sub or superscripts
            let dash = symN == 1 ? "--" : (symN == 2 ? "-" : "")
            return "ƒ{2.0}\(symName)ç{GrayText}\(dash)"
        }
        
        let symA = Array(symName)
        
        if symN == 2 {
            assert( (subPt*superPt == 0) && (subPt+superPt == 2) )
            
            let op = subPt > 0 ? "_" : "^"
            
            return "ƒ{2.0}\(symA[0])\(op){\(symA[1])}ç{GrayText}\(op){-}"
        }
        
        if symN == 3 {
            assert( (subPt*superPt == 0) && (subPt+superPt >= 2) )
            
            // Sub or Super operator and starting point
            let op = subPt > 0 ? "_" : "^"
            let pt = subPt + superPt
            
            // Sub or superscript point starting at position 2 or 3
            return pt == 2 ? "ƒ{2.0}\(symA[0])\(op){\(symA[1])\(symA[2])}" : "ƒ{2.0}\(symA[0])\(symA[1])\(op){\(symA[2])}"
        }
        
        // Invalid
        assert(false)
        return ""
    }
    
    var body: some View {
        
        VStack {
            
            VStack {
                RichText( getSymbolText(), size: .normal, defaultColor: "BlackText").padding( [.top], 20 )
                
                KeypadView( padSpec: padList[charSet.rawValue], keyPressHandler: self )
                    .padding( [.leading, .trailing, .bottom] )
                
                HStack {
                    Button( "", systemImage: "arrowshape.left.arrowshape.right" ) {
                        // Don't include digits for the first letter
                        charSet = symN == 0 ? charSet.nextSetZero : charSet.nextSet
                    }
                    
                    HStack {
                        ForEach ( setList, id: \.self ) { cs in
                            Text( setLabels[cs.rawValue] )
                                .if ( cs == charSet ) { txt in
                                    // Add border around selected char set
                                    txt.overlay(
                                        RoundedRectangle( cornerRadius: 5).inset(by: -1).stroke(.blue, lineWidth: 1) )
                                }
                                .if ( symN == 0 && cs == CharSet.digit ) { txt in
                                    // Digits not allowed for first char
                                    txt.foregroundColor(.gray)
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
                            
                            if subPt+superPt == 3 {
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
                            
                            reset()
                            
                            // Process tag in parent view
                            scc( tag )
                        }
                    })
                    {
                        Image( systemName: "checkmark.diamond.fill" )
                    }
                    .accentColor( Color.green )
                    .disabled( symN == 0 )
                    
                }.padding( [.bottom], 20)
            }
        }
        .onAppear() {
            // Initialize provided tag specs
            let (str, arr, subPt, superPt) = tag.getSymSpecs()
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
