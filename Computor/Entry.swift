//
//  Entry.swift
//  Computor
//
//  Created by Barry Hall on 2024-12-29.
//

import Foundation
import Numerics
import OSLog

let logE = Logger( category: "entry" )


class NumericEntry {
    
    // Entry state for one numeric entry
    // Contains a valid numeric entry if entryText is not empty
    // ExponentEntry is true if an exponent has been entered
    // decimalSeen is true if entryText contains a decimal point
    // negativeSign is true if entryText starts with a negaive sign
    // digitCount is number of digits in entryText - does not include exponent
    //
    var entryText: String
    var exponentText: String
    var exponentEntry: Bool
    var decimalSeen: Bool
    var negativeSign: Bool
    var digitCount: Int
    
    init() {
        entryText = ""
        exponentText = ""
        exponentEntry = false
        decimalSeen = false
        negativeSign = false
        digitCount = 0
    }
    
    func reset() {
        
        // Reset all states
        entryText = ""
        exponentText = ""
        exponentEntry = false
        decimalSeen = false
        negativeSign = false
        digitCount = 0
    }
    
    var validValue: Bool { digitCount > 0 }
    
    
    func getRealValue() -> Double? {
        
        var num: String = entryText
        
        // Remove all commas
        num.removeAll( where: { $0 == "," })

        if exponentEntry {
            /// Eliminate 'x10'
            num.removeLast(3)
            
            if !exponentText.isEmpty {
                
                /// Exponential entered
                num += "E" + exponentText
            }
        }
        
        return Double(num)
    }
}


struct EntryState {
    /// Defines the state of the data entry line while active
    ///
    
    // Data entry state
    var entryMode: Bool = false
    
    // Up to 3 comma separated numeric entries
    var entrySet: [NumericEntry] = (0..<3).map { _ in NumericEntry() }
    
    var ne: NumericEntry = NumericEntry()
    var nx: Int = 0
    
    let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    var nValues: Int {
        
        // Number of values in data entry is nx+1
        var n = nx+1
        
        if !entrySet[nx].validValue {
            // Last value invalid - like a comma with no digits following
            n -= 1
        }
        return n
    }
    
    
    func makeTaggedValue() -> TaggedValue? {
        
        /// Create a TaggedValue from data entry fields
        /// Multiple values produces a column matrix
        ///
        
        guard entryMode && entrySet[0].validValue else {
            // Not in data entry mode, no valid value
            return nil
        }
        
        let n = nValues
        
        var tv = TaggedValue( cols: n )
        
        for col in 1...n {
            
            if let value = entrySet[col-1].getRealValue() {
                tv.set1( value, c: col )
            }
        }
        return tv
    }

    // *** Data Entry Functions ***
    
    mutating func clearEntry() {
        entrySet[0].reset()
        entrySet[1].reset()
        entrySet[2].reset()
        
        nx = 0
        ne = entrySet[nx]
        
        entryMode = false
    }

    mutating func startTextEntry( _ kc: KeyCode ) {
        clearEntry()
        
        entryMode = true
        
        ne.entryText = (kc == .dot) ? "0." : String( kc.rawValue - KeyCode.d0.rawValue )
        ne.digitCount = 1
        ne.decimalSeen = ne.entryText.contains(".")
    }
    
    mutating func startExpEntry() {
        appendTextEntry("×10")
        ne.exponentText = ""
        ne.exponentEntry = true
    }
    
    mutating func flipTextSign() {
        
        if ne.entryText.starts( with: "-") {
            ne.entryText.removeFirst()
            ne.negativeSign = false
        }
        else {
            ne.entryText.insert( "-", at: ne.entryText.startIndex )
            ne.negativeSign = true
        }
    }
    
    mutating func recommaEntry() {
        
        // Func is a noop if data entry contains a decimal point
        if !ne.decimalSeen {
            if ne.negativeSign {
                // Temporarily remove the negative sign
                ne.entryText.removeFirst()
            }
            
            // Remove all commas
            ne.entryText.removeAll( where: { $0 == "," })
            
            if ne.digitCount > 3 {
                // Work with string as array
                var seq = Array(ne.entryText)
                
                let commaCount = (ne.digitCount - 1) / 3
                
                for ix in 1...commaCount {
                    // The next line is crazy but it works
                    seq.insert(",", at: (ne.digitCount-1) % 3 + 1 + (ix-1)*4 )
                }
                
                // restore the data string from array
                ne.entryText = String(seq)
            }
            
            if ne.negativeSign {
                // reinsert the negative sign if required
                ne.entryText.insert( "-", at: ne.entryText.startIndex )
            }
        }
    }
    
    mutating func appendTextEntry(_ str: String ) {
        if str == "." {
            if !ne.decimalSeen {
                ne.entryText += str
                ne.decimalSeen = true
            }
        }
        else if digits.contains(str) {
            ne.entryText += str
            ne.digitCount += 1
            recommaEntry()
        }
        else {
            ne.entryText += str
        }
        
        let txt = self.ne.entryText
        logE.debug( "AppendTextEntry: '\(str)' -> '\(txt)'")
    }
    
    mutating func appendExpEntry(_ str: String ) {
        self.ne.exponentText += str
        
        let txt = self.ne.exponentText
        logE.debug( "AppendExponentEntry: '\(str)' -> '\(txt)'")
    }
    
    mutating func backspaceEntry() {
        
        if ne.entryText.isEmpty {
            
            if nx > 0 {
                
                // Remove comma - which is not really there - and return to last value
                ne.reset()
                nx -= 1
                ne = entrySet[nx]
            }
        }
        else {
            let ch = ne.entryText.removeLast()
            
            if ch == "." {
                ne.decimalSeen = false
            }
            else if digits.contains(ch) {
                ne.digitCount -= 1
                recommaEntry()
            }
            
            if ne.entryText.isEmpty || ne.entryText == "-" {
                
                if nx == 0 {
                    // Cancel Entry mode
                    clearEntry()
                }
                else {
                    // Remove comma - which is not really there - and return to last value
                    ne.reset()
                    nx -= 1
                    ne = entrySet[nx]
                }
            }
        }
    }
    
    
    mutating func entryModeKeypress(_ keyCode: KeyCode ) -> KeyPressResult {
        
        if keyCode == .comma {
            
            // Must have a valid numeric value but not 2 to add another
            if ne.entryText.isEmpty || nx == 2 {
                return KeyPressResult.dataEntry
            }
            
            // We have one or two values, can add more
            nx += 1
            ne = entrySet[nx]
            ne.reset()
            return KeyPressResult.dataEntry
        }
        
        if ne.exponentEntry {
            switch keyCode {
            case .d0, .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9:
                // Append a digit to exponent
                if ne.exponentText.starts( with: "-") && ne.exponentText.count < 4 || ne.exponentText.count < 3 {
                    appendExpEntry( String(keyCode.rawValue - KeyCode.d0.rawValue ))
                }

            case .dot, .eex:
                // No op
                break
                
            case .chs:
                if ne.exponentText.starts( with: "-") {
                    ne.exponentText.removeFirst()
                }
                else {
                    ne.exponentText.insert( "-", at: ne.exponentText.startIndex )
                }

            case .backUndo:
                if ne.exponentText.isEmpty {
                    ne.exponentEntry = false
                    ne.entryText.removeLast(3)
                }
                else {
                    ne.exponentText.removeLast()
                }
                
            default:
                // No op
                break

            }
        }
        else {
            switch keyCode {
            case .d0, .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9:
                // Append a digit
                appendTextEntry( String(keyCode.rawValue - KeyCode.d0.rawValue))
                
            case .d000:
                // Append 3 zeros
                appendTextEntry( String("0") )
                appendTextEntry( String("0") )
                appendTextEntry( String("0") )

            case .dot:
                appendTextEntry(".")
                
            case .eex:
                startExpEntry()

            case .chs:
                flipTextSign()

            case .backUndo:
                backspaceEntry()
                
                if !entryMode {
                    // The backspace has deleted the last digit entry - we cancel entry mode
                    return KeyPressResult.cancelEntry
                }

            default:
                // No op
                break
            }
        }
        
        return KeyPressResult.dataEntry
    }
}
