//
//  Entry.swift
//  Computor
//
//  Created by Barry Hall on 2024-12-29.
//

import Foundation
import Numerics
import OSLog

let logE = Logger(subsystem: "com.microsnout.calculator", category: "entry")


struct EntryState {
    /// Defines the state of the data entry line while active
    ///
    
    // Data entry state
    var entryMode: Bool = false
    var exponentEntry: Bool = false
    var decimalSeen: Bool = false
    var negativeSign: Bool = false
    var digitCount: Int = 0
    var entryText: String = ""
    var exponentText: String = ""
    
    let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    
    func makeTaggedValue() -> TaggedValue? {
        /// Create a TaggedValue from data entry fields
        ///
        guard entryMode else {
            // Not in data entry mode, no valid value
            return nil
        }
        
        var num: String = entryText
        
        if exponentEntry {
            /// Eliminate 'x10'
            num.removeLast(3)
        }
        
        // Remove all commas
        num.removeAll( where: { $0 == "," })

        var tv = TaggedValue()
        
        if exponentEntry && !exponentText.isEmpty {
            /// Exponential entered
            let str: String = num + "E" + exponentText
            
            guard let value = Double(str) else {
                return nil
            }
            
            tv.reg = value
            tv.tag = tagUntyped
            tv.fmt = CalcState.defaultSciFormat
        }
        else {
            guard let value = Double(num) else {
                return nil
            }
            
            tv.reg = value
            tv.tag = tagUntyped
            tv.fmt = CalcState.defaultDecFormat
        }
        
        return tv
    }

    // *** Data Entry Functions ***
    
    mutating func clearEntry() {
        entryMode = false
        exponentEntry = false
        decimalSeen = false
        negativeSign = false
        digitCount = 0
        entryText.removeAll(keepingCapacity: true)
        exponentText.removeAll(keepingCapacity: true)
    }

    mutating func startTextEntry( _ kc: KeyCode ) {
        clearEntry()
        entryMode = true
        entryText = (kc == .dot) ? "0." : String( kc.rawValue - KeyCode.key0.rawValue )
        digitCount = 1
        decimalSeen = entryText.contains(".")
    }
    
    mutating func startExpEntry() {
        appendTextEntry("×10")
        exponentText = ""
        exponentEntry = true
    }
    
    mutating func flipTextSign() {
        if entryText.starts( with: "-") {
            entryText.removeFirst()
            negativeSign = false
        }
        else {
            entryText.insert( "-", at: entryText.startIndex )
            negativeSign = true
        }
    }
    
    mutating func recommaEntry() {
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
    
    mutating func appendTextEntry(_ str: String ) {
        if str == "." {
            if !decimalSeen {
                entryText += str
                decimalSeen = true
            }
        }
        else if digits.contains(str) {
            entryText += str
            digitCount += 1
            recommaEntry()
        }
        else {
            entryText += str
        }
        
        let txt = self.entryText
        logE.debug( "AppendTextEntry: '\(str)' -> '\(txt)'")
    }
    
    mutating func appendExpEntry(_ str: String ) {
        self.exponentText += str
        
        let txt = self.exponentText
        logE.debug( "AppendExponentEntry: '\(str)' -> '\(txt)'")
    }
    
    mutating func backspaceEntry() {
        if !entryText.isEmpty {
            let ch = entryText.removeLast()
            
            if ch == "." {
                decimalSeen = false
            }
            else if digits.contains(ch) {
                digitCount -= 1
                recommaEntry()
            }
            
            if entryText.isEmpty || entryText == "-" {
                clearEntry()
            }
        }
    }
    
    
    mutating func entryModeKeypress(_ keyCode: KeyCode ) -> KeyPressResult {
        if exponentEntry {
            switch keyCode {
            case .key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9:
                // Append a digit to exponent
                if exponentText.starts( with: "-") && exponentText.count < 4 || exponentText.count < 3 {
                    appendExpEntry( String(keyCode.rawValue))
                }

            case .dot, .eex:
                // No op
                break
                
            case .sign:
                if exponentText.starts( with: "-") {
                    exponentText.removeFirst()
                }
                else {
                    exponentText.insert( "-", at: exponentText.startIndex )
                }

            case .back:
                if exponentText.isEmpty {
                    exponentEntry = false
                    entryText.removeLast(3)
                }
                else {
                    exponentText.removeLast()
                }
                
            default:
                // No op
                break

            }
        }
        else {
            switch keyCode {
            case .key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9:
                // Append a digit
                appendTextEntry( String(keyCode.rawValue - KeyCode.key0.rawValue))
                
            case .dot:
                appendTextEntry(".")
                
            case .eex:
                startExpEntry()

            case .sign:
                flipTextSign()

            case .back:
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
