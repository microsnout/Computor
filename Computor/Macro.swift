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


struct MacroEvent: CodableMacroOp {
    var event: KeyEvent
    
    func execute( _ model: CalculatorModel ) -> KeyPressResult {
        return model.keyPress( event )
    }
    
    func getRichText( _ model: CalculatorModel ) -> String {
        
        guard let key = Key.keyList[event.kc] else {
            // All keys must be in keyList
            assert(false)
            return "??"
        }
        
        if key.kc == .lib {
            
            if let mTag = event.mTag {
                
                if let (_, mfr) = model.db.getMacro( for: mTag, localMod: model.aux.macroMod ) {
                    
                    if mfr == model.aux.macroMod {
                        
                        // Local to this module
                        return mTag.getRichText()
                    }
                    
                    // Remote module reference
                    var text = mfr.name
                    text += "ç{ModText}/ç{}"
                    text += mTag.getRichText()
                    return text
                }
                else {
                    // Macro not found
                    return "ç{StatusRedText}\(mTag.getRichText())ç{}"
                }
            }
            else {
                // Bad macro event
                assert(false)
                return "ç{StatusRedText}Lib ?ç{}"
            }
        }
        else if var keyText = key.text {
            
            // Key has custom text string
            
            if let mTag = event.mTag {
                
                // Add sub key parm to op, like adding .A to .Sto
                keyText += " "
                keyText += mTag.getRichText()
            }
            return keyText
        }
        
        return model.getKeyText(event.kc) ?? "??"
    }
    
    
    func getPlainText() -> String {
        return String( describing: event.keyCode )
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


struct MacroOpSeq: Codable, Sequence {
    
    private var opList = [MacroOp]()
    
    var count: Int { opList.count }
    
    var isEmpty: Bool { opList.isEmpty }
    
    var last: MacroOp? { opList.last }
    
    var indices: Range<Int> { opList.indices }
    
    var endIndex: Int { opList.endIndex }
    
    mutating func clear() { self.opList = [] }

    mutating func append( _ op: MacroOp ) { opList.append(op) }
    
    mutating func removeLast() { opList.removeLast() }
    
    subscript(index:Int) -> MacroOp {
        get { return opList[index] }
        set(newOp) { opList[index] = newOp }
    }

    subscript( r: PartialRangeFrom<Int> ) -> ArraySlice<MacroOp> {
        get { return opList[r] }
    }
    
    func makeIterator() -> IndexingIterator<[any MacroOp]> {
        return opList.makeIterator()
    }
    
    // ***
    
    enum CodingKeys: String, CodingKey {
        case opSeq
    }
    
    func encode( to encoder: Encoder ) throws {
        var c = encoder.container( keyedBy: CodingKeys.self )
        
        var opC = c.nestedUnkeyedContainer( forKey: .opSeq)
        
        for op in opList {
            
            if let key = op as? MacroEvent {
                try opC.encode(key)
            }
            else if let value = op as? MacroValue {
                try opC.encode(value)
            }
        }
    }
    
    func getDebugText() -> String {
        if opList.isEmpty {
            return "[]"
        }
        
        var str = "["
        let end = opList.last
        
        for s in opList.dropLast() {
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
            
            if let key = try? opC.decode( MacroEvent.self) {
                opList.append(key)
            }
            else if let value = try? opC.decode( MacroValue.self) {
                opList.append(value)
            }
        }
    }
    
    init( _ opSeq: [MacroOp] = [] ) {
        self.opList = opSeq
    }
}
