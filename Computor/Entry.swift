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

    func startTextEntry( _ kc: KeyCode ) {
        reset()
        entryText = (kc == .dot) ? "0." : String( kc.rawValue - KeyCode.d0.rawValue )
        digitCount = 1
        decimalSeen = entryText.contains(".")
    }
    
    
    func startExpEntry() {
        appendTextEntry("×10")
        exponentText = ""
        exponentEntry = true
    }

    func appendTextEntry(_ str: String ) {
        if str == "." {
            if !decimalSeen {
                entryText += str
                decimalSeen = true
            }
        }
        else if EntryState.digits.contains(str) {
            entryText += str
            digitCount += 1
            recommaEntry()
        }
        else {
            entryText += str
        }
    }
    
    
    func appendExpEntry(_ str: String ) {
        exponentText += str
    }

    
    func recommaEntry() {
        
        // Func is a noop if data entry contains a decimal point
        if !decimalSeen {
            if negativeSign {
                // Temporarily remove the negative sign
                entryText.removeFirst()
            }
            
            // Remove all commas
            entryText.removeAll( where: { $0 == "," })
            
            if digitCount > 3 {
                // Work with string as array
                var seq = Array(entryText)
                
                let commaCount = (digitCount - 1) / 3
                
                for ix in 1...commaCount {
                    // The next line is crazy but it works
                    seq.insert(",", at: (digitCount-1) % 3 + 1 + (ix-1)*4 )
                }
                
                // restore the data string from array
                entryText = String(seq)
            }
            
            if negativeSign {
                // reinsert the negative sign if required
                entryText.insert( "-", at: entryText.startIndex )
            }
        }
    }
    
    func flipTextSign() {
        
        if entryText.starts( with: "-") {
            entryText.removeFirst()
            negativeSign = false
        }
        else {
            entryText.insert( "-", at: entryText.startIndex )
            negativeSign = true
        }
    }

    
    func backspaceEntry() {
        
        let ch = entryText.removeLast()
        
        if ch == "." {
            decimalSeen = false
        }
        else if EntryState.digits.contains(ch) {
            digitCount -= 1
            recommaEntry()
        }
    }
}


// *************************************************************** //
    
    
struct EntryState {
    /// Defines the state of the data entry line while active
    ///
    
    // Data entry state
    var entryMode: Bool = false
    
    // Up to 3 comma separated numeric entries
    var entrySet: [NumericEntry] = (0..<3).map { _ in NumericEntry() }
    
    var ne: NumericEntry = NumericEntry()
    var nx: Int = 0
    
    static let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
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
        nx = 0
        ne = entrySet[nx]
        entrySet[0].reset()
        entrySet[1].reset()
        entrySet[2].reset()
        entryMode = false
    }

    mutating func startTextEntry( _ kc: KeyCode ) {
        clearEntry()
        ne.startTextEntry(kc)
        entryMode = true
    }
    
    
    mutating func appendTextEntry(_ str: String ) {
        
        ne.appendTextEntry(str)
        
        let txt = self.ne.entryText
        logE.debug( "AppendTextEntry: '\(str)' -> '\(txt)'")
    }
    
    mutating func appendExpEntry(_ str: String ) {
        ne.appendExpEntry(str)
        
        let txt = self.ne.exponentText
        logE.debug( "AppendExponentEntry: '\(str)' -> '\(txt)'")
    }
    
    mutating func backspaceEntry() {
        
        if ne.validValue == false {
            
            if nx > 0 {
                
                // Remove comma - which is not really there - and return to last value
                ne.reset()
                nx -= 1
                ne = entrySet[nx]
            }
        }
        else {
            ne.backspaceEntry()
            
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
                ne.startExpEntry()

            case .chs:
                ne.flipTextSign()

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


// Extensions to Calculator model needed for data entry
extension CalculatorModel {

    // *** Entry State control ***
    
    func acceptTextEntry() {
        if entry.entryMode {
            guard let tv = entry.makeTaggedValue() else  {
                assert(false)
                entry.clearEntry()
                return
            }
            
            // Store tagged value in X reg, Record data entry if recording and clear data entry state
            entry.clearEntry()
            
            // Keep new entered X value
            state.stack[regX] = tv
            state.lastX = tv
        }
    }
    
    
    func grabTextEntry() -> TaggedValue {
        
        guard let tv = entry.makeTaggedValue() else  {
            assert(false)
            entry.clearEntry()
            return untypedZero
        }
        
        // Return the value
        entry.clearEntry()
        return tv
    }
}
