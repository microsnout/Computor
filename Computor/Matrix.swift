//
//  Matrix.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-26.
//
import Foundation
import OSLog

let logX = Logger(subsystem: "com.microsnout.calculator", category: "matrix")


extension TaggedValue {
    
    func renderMatrix() -> String {
        
        let ( _, rows, cols) = getShape()
        
        if cols > 1 {
            return "ç{Units}[ç{}\(rows)ç{Units} x ç{}\(cols)ç{Units}]ç{}"
        }
        
        var text = "ç{Units}[ç{}"
        
        for r in 1 ... rows {
            text.append( renderValueSimple(r))
            text.append( r == rows ? "ç{Units}]ç{}" : "ç{Units}, ç{}")
        }
        
        return text
    }
}


func installMatrix( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpCodes( [
        .seq:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isInteger else {
                    return nil
                }
                var s1 = s0
                let n = Int(floor(s0.X))
                let seq = 1 ... n
                
                s1.stack[regX].value.setShape( 1, n, 1 )
                
                for x in seq {
                    s1.stack[regX].value.set1( Double(x), x )
                }
                s1.stack[regX].value.vtp = .real
                return s1
            },
        
        .map:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isMatrix && s0.Xtv.cols == 1 else {
                    // Require a single column vector of any type
                    return nil
                }
                
                // Create a Reduce function obj capturing the value list and mode reference
                let mapFn = MapFunction( valueList: s0.Xtv, model: model)
                model.setModalFunction(mapFn)
                
                // No new state
                return nil
            },

        .reduce:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isMatrix && s0.Xtv.cols == 1 && s0.Ytv.isSimple else {
                    // Require a single column vector of any type and a simple/scalar constant
                    return nil
                }
                
                // Create a Reduce function obj capturing the value list and mode reference
                let reduceFn = ReduceFunction( valueList: s0.Xtv, model: model)
                model.setModalFunction(reduceFn)
                
                // No new state
                return nil
            },
    ])
}


struct MapFunction : ModalFunction {
    
    let valueList:  TaggedValue
    let model:      CalculatorModel
    
    var statusString: String? { "ç{Units}Map f(x)" }
    
    func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        
        // Start with empty output list
        let seqRows    = valueList.rows
        var resultList = TaggedValue()
        
        // Remove parameter value from stack
        model.state.stackDrop()

        for r in 1 ... seqRows {
            
            if let value = valueList.getValue( row: r) {
                
                model.enterValue( value )
                
                if model.keyPress( event ) == .stateChange {
                    
                    if r == 1 {
                        // Grab the first result to define the type tag and format for result
                        let firstValue = model.state.Xtv
                        let ss = firstValue.simpleSize
                        
                        // Establish size of result and add first value
                        resultList = firstValue
                        resultList.setShape(ss, seqRows)
                        resultList.setValue( firstValue, row: 1)
                    }
                    else {
                        // Add next value at correct row
                        resultList.setValue( model.state.Xtv, row: r )
                    }
                    
                    // Remove intermediate result
                    model.state.stackDrop()
                }
            }
            
            
        }
        
        // Push final result list
        model.enterValue(resultList)
        return KeyPressResult.stateChange
    }
}


struct ReduceFunction : ModalFunction {
    
    let valueList:     TaggedValue
    
    let model: CalculatorModel
    
    var statusString: String? { "ƒ{0.9}ç{Units}Reduce x:[] y:r_{0}" }
    
    func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        
        // Start with empty output list
        let seqRows    = valueList.rows
        
        // Remove value list parameter from stack, but not initial result
        model.state.stackDrop()

        for r in 1 ... seqRows {
            
            if let value = valueList.getValue( row: r) {
                
                model.enterValue( value )

                if model.keyPress( event ) != .stateChange {
                    return KeyPressResult.stateError
                }
            }
        }
        
        // Final result is already on stack X
        return KeyPressResult.stateChange
    }
}
