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
}

struct MacroKey: MacroOp {
    var kc: KeyCode
    
    func execute( _ model: CalculatorModel ) -> KeyPressResult {
        return model.keyPress( KeyEvent( kc: kc) )
    }
    
    func getRichText( _ model: CalculatorModel ) -> String {
        if let key = Key.keyList[kc] {
            return key.text ?? model.getKeyText(kc) ?? "??"
        }
        return "??"
    }
}

struct MacroValue: MacroOp {
    var tv: TaggedValue
    
    func execute( _ model: CalculatorModel ) -> KeyPressResult {
        model.enterValue(tv)
        return KeyPressResult.stateChange
    }
    
    func getRichText( _ model: CalculatorModel ) -> String {
        return tv.renderRichText()
    }
}

