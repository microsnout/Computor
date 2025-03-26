//
//  Macro.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-31.
//

import SwiftUI
import OSLog

let logMac = Logger(subsystem: "com.microsnout.calculator", category: "model")


protocol MacroOp {
    func execute( _ model: CalculatorModel ) -> KeyPressResult

    func getRichText( _ model: CalculatorModel ) -> String
    
    func getPlainText() -> String
}


typealias CodableMacroOp = MacroOp & Codable


struct MacroKey: CodableMacroOp {
    var event: KeyEvent
    
    func execute( _ model: CalculatorModel ) -> KeyPressResult {
        return model.keyPress( event )
    }
    
    func getRichText( _ model: CalculatorModel ) -> String {
        if let key = Key.keyList[event.kc] {
            
            // TODO: Need to combine aux with kc to produce .Sto A
            if var keyText = key.text {
                if let kcAux = event.kcAux {
                    keyText += " "
                    keyText += String( describing: kcAux )
                }
                return keyText
            }
            
            return model.getKeyText(event.kc) ?? "??"
        }
        return "??"
    }
    
    func getPlainText() -> String {
        return String( describing: event.kc )
    }
    
    init( _ event: KeyEvent ) {
        self.event = event
    }
}

struct MacroValue: CodableMacroOp {
    var tv: TaggedValue
    
    func execute( _ model: CalculatorModel ) -> KeyPressResult {
        model.enterValue(tv)
        return KeyPressResult.stateChange
    }
    
    func getRichText( _ model: CalculatorModel ) -> String {
        let (str, _) = tv.renderRichText()
        return str
    }
    
    func getPlainText() -> String {
        return String( tv.reg )
    }
}


struct MacroOpSeq: Codable {
    
    var opSeq = [MacroOp]()
    
    mutating func clear() {
        self.opSeq = []
    }
    
    enum CodingKeys: String, CodingKey {
        case opSeq
    }
    
    func encode( to encoder: Encoder ) throws {
        var c = encoder.container( keyedBy: CodingKeys.self )
        
        var opC = c.nestedUnkeyedContainer( forKey: .opSeq)
        
        for op in opSeq {
            
            if let key = op as? MacroKey {
                try opC.encode(key)
            }
            else if let value = op as? MacroValue {
                try opC.encode(value)
            }
        }
    }
    
    func getDebugText() -> String {
        if opSeq.isEmpty {
            return "[]"
        }
        
        var str = "["
        let end = opSeq.last
        
        for s in opSeq.dropLast() {
            str += s.getPlainText()
            str += ", "
        }
        
        str += end?.getPlainText() ?? ""
        str += "]"
        return str
    }

    init( from decoder: Decoder) throws {
        
        let c = try decoder.container( keyedBy: CodingKeys.self)
        
        var opC = try c.nestedUnkeyedContainer( forKey: .opSeq)
        
        while !opC.isAtEnd {
            
            if let key = try? opC.decode( MacroKey.self) {
                opSeq.append(key)
            }
            else if let value = try? opC.decode( MacroValue.self) {
                opSeq.append(value)
            }
        }
    }
    
    init( _ opSeq: [MacroOp] = [] ) {
        self.opSeq = opSeq
    }
}
