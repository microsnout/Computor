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
    
    func renderMatrix() -> (String, Int) {
        
        let maxStrCount = 30
        
        let ( _, rows, cols) = getShape()
        
        if cols > 1 {
            let rowStr = String(rows)
            let colStr = String(cols)
            let text = "ç{Units}[ç{}\(rowStr)ç{Units} x ç{}\(colStr)ç{Units}]ç{}"
            return (text, rowStr.count + colStr.count + 5)
        }
        
        var text  = "ç{Units}[ç{}"
        var count = 1
        
        for r in 1 ... rows {
            let (simpleStr, simpleCount) = renderValueSimple(r)
            
            if count + simpleCount > maxStrCount {
                text.append( "ç{Units}={..]}ç{}" )
                return (text, count + 3)
            }
            text.append(simpleStr)
            
            if r == rows {
                text.append( "ç{Units}]ç{}" )
                count += simpleCount + 1
            }
            else {
                text.append( "ç{Units}, ç{}" )
                count += simpleCount + 2
            }
        }
        
        return (text, count)
    }
}


func installMatrix( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpCodes( [
        .seq:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isInteger && s0.Ytv.isSimple && s0.Ztv.isSimple else {
                    return nil
                }
                // Copy parameters n and inc from s0
                let n = Int(floor(s0.X))
                let seq = 1 ... n
                let inc = s0.Ytv

                // Copy intial value from s0 and create result array of size n
                var result = s0.Ztv
                let ss = result.size
                result.setShape( ss, n, 1 )
                
                // Remove N and increment value from stack
                model.state.stackDrop()
                model.state.stackDrop()
                
                model.undoStack.pause()
                model.aux.pauseRecording()
                
                for r in seq {
                    // Copy current result value to result array
                    result.setValue(model.state.Xtv, row: r)
                    
                    // Increment X value by inc
                    model.enterValue(inc)
                    
                    if model.keyPress( KeyEvent( kc: .plus)) != .stateChange {
                        // Addition error
                        model.aux.resumeRecording()
                        model.undoStack.resume()
                        return nil
                    }
                    
                }
                model.aux.resumeRecording()
                model.undoStack.resume()

                // Copy state, remove parameters and put result in X
                var s1 = s0
                s1.stackDrop()
                s1.stackDrop()
                s1.stack[regX].value = result
                return s1
            },
        
        .range:
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


class MapFunction : ModalFunction {
    
    let valueList:  TaggedValue
    let model:      CalculatorModel
    
    init(valueList: TaggedValue, model: CalculatorModel) {
        self.valueList = valueList
        self.model = model
    }
    
    override var statusString: String? { "ç{Units}Map f(x)" }
    
    override func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        
        // Start with empty output list
        let seqRows    = valueList.rows
        var resultList = TaggedValue()
        
        // Remove parameter value from stack
        model.state.stackDrop()

        model.undoStack.pause()
        model.aux.pauseRecording()
        
        for r in 1 ... seqRows {
            
            if let value = valueList.getValue( row: r) {
                
                model.enterValue( value )
                
                if executeFn( event, model: model) == .stateChange {
                    
                    if r == 1 {
                        // Grab the first result to define the type tag and format for result
                        let firstValue = model.state.Xtv
                        let ss = firstValue.size
                        
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
                else {
                    model.aux.resumeRecording()
                    model.undoStack.resume()
                    return KeyPressResult.stateError
                }
            }
        }
        model.aux.resumeRecording()
        model.undoStack.resume()


        // Push final result list
        model.enterValue(resultList)
        return KeyPressResult.stateChange
    }
}


class ReduceFunction : ModalFunction {
    
    let valueList:     TaggedValue
    
    let model: CalculatorModel
    
    init(valueList: TaggedValue, model: CalculatorModel) {
        self.valueList = valueList
        self.model = model
    }
    
    override var statusString: String? { "ƒ{0.9}ç{Units}Reduce x:[] y:r_{0}" }
    
    override func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        
        // Start with empty output list
        let seqRows    = valueList.rows
        
        // Remove value list parameter from stack, but not initial result
        model.state.stackDrop()

        model.undoStack.pause()
        model.aux.pauseRecording()
        
        for r in 1 ... seqRows {
            
            if let value = valueList.getValue( row: r) {
                
                model.enterValue( value )

                if executeFn( event, model: model) != .stateChange {
                    model.aux.resumeRecording()
                    model.undoStack.resume()
                    return KeyPressResult.stateError
                }
            }
        }
        model.aux.resumeRecording()
        model.undoStack.resume()

        // Final result is already on stack X
        return KeyPressResult.stateChange
    }
}
