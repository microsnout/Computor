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
                text.append( "ç{Units}={, }ç{}" )
                count += simpleCount + 2
            }
        }
        
        if tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{Units}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                count += sym.count + 1
            }
        }

        return (text, count)
    }
}


func installMatrix( _ model: CalculatorModel ) {
    
    let allTypes: Set<ValueType> = [.real, .rational, .complex, .vector, .vector3D, .polar, .spherical]
    
    CalculatorModel.defineOpPatterns( .seq, [
        
        OpPattern( [ .X([.real]), .Y(allTypes), .Z(allTypes) ], where: { s0 in isInt(s0.X) } ) { s0 in
                       
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
            
            model.pauseStack()
            model.aux.pauseRecording()
            
            for r in seq {
                // Copy current result value to result array
                result.setValue(model.state.Xtv, row: r)
                
                // Increment X value by inc
                model.enterValue(inc)
                
                if model.keyPress( KeyEvent( kc: .plus)) != .stateChange {
                    // Addition error
                    model.aux.resumeRecording()
                    model.resumeStack()
                    return nil
                }
                
            }
            model.aux.resumeRecording()
            model.resumeStack()
            
            // Copy state, remove parameters and put result in X
            var s1 = s0
            s1.stackDrop()
            s1.stackDrop()
            s1.stack[regX].value = result
            return s1
       }
   ])
                       
    
    CalculatorModel.defineOpPatterns( .range, [
        
        OpPattern( [ .X([.real]) ], where: { s0 in isInt(s0.X) } ) { s0 in
            
            var s1 = s0
            let n = Int(floor(s0.X))
            let seq = 1 ... n
            
            s1.stack[regX].value.setShape( 1, n, 1 )
            
            for x in seq {
                s1.stack[regX].value.set1( Double(x), r: x )
            }
            s1.stack[regX].value.vtp = .real
            return s1
        }
    ])
    
    
    CalculatorModel.defineOpPatterns( .map, [
        
        OpPattern( [ .X(allTypes, .matrix) ], where: { s0 in s0.Xtv.cols == 1 } ) { s0 in
            
            // Create a Reduce function obj capturing the value list and mode reference
            let mapFn = MapFunction( valueList: s0.Xtv, model: model)
            model.setModalFunction(mapFn)
            
            // No new state
            return nil
        }
    ])
            
    
    CalculatorModel.defineOpPatterns( .reduce, [
        
        OpPattern( [ .X(allTypes, .matrix), .Y(allTypes, .simple) ], where: { s0 in s0.Xtv.cols == 1 } ) { s0 in
            
            // Create a Reduce function obj capturing the value list and mode reference
            let reduceFn = ReduceFunction( valueList: s0.Xtv, model: model)
            model.setModalFunction(reduceFn)
            
            // No new state
            return nil
        }
    ])


    // *** UNIT Conversions ***

    CalculatorModel.defineUnitConversions([
        
        ConversionPattern( [ .X( [.real, .vector, .complex, .polar, .vector3D, .spherical], .matrix) ] ) { s0, tagTo in
            
            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                var s1 = s0
            
                if s0.Xvtp == .polar || s0.Xvtp == .spherical {
                    s1.Xtv.transformValues() { value, s, r, c in
                        // Only scale the r value of polar types, not theta or phi
                        let newValue = seq.op(value)
                        return s == 1 ? newValue : value
                    }
                }
                else {
                    s1.Xtv.transformValues() { value, s, r, c in
                        let newValue = seq.op(value)
                        return newValue
                    }
                }
                
                s1.Xt = tagTo
                return s1
            }
            
            // Conversion not possible
            return nil
        },
    ])
    
    // *** Operator Patterns ***
    
    // Indexing operator [] uses .matrix keycode for now
    CalculatorModel.defineOpPatterns( .matrix, [
        
        // X must be integer, Y must be matrix, any type
        OpPattern( [ .X([.real]), .Y([.real, .rational, .complex, .vector, .polar, .vector3D, .spherical], .matrix) ],
                   where: { s0 in isInt(s0.X) } ) { s0 in
            
            let ( _, rows, _ ) = s0.Ytv.getShape()
            
            let n = Int(s0.X)
            
            guard n >= 1 && n <= rows else {
                return nil
            }
            
            guard let tv = s0.Ytv.getValue( row: n ) else {
                return nil
            }
            
            var s1 = s0
            s1.stackDrop()
            
            s1.Xtv = tv
            return s1
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
    
    override var statusString: String? { "ç{Units}Map ƒ()" }
    
    override func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        
        // Start with empty output list
        let seqRows    = valueList.rows
        var resultList = TaggedValue()
        
        // Remove parameter value from stack
        model.state.stackDrop()

        model.pauseStack()
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
                    model.resumeStack()
                    return KeyPressResult.stateError
                }
            }
        }
        model.aux.resumeRecording()
        model.resumeStack()


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
    
    override var statusString: String? { "ƒ{0.9}ç{Units}Reduce ƒ(,)" }
    
    override func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        
        // Start with empty output list
        let seqRows    = valueList.rows
        
        // Remove value list parameter from stack, but not initial result
        model.state.stackDrop()

        model.pauseStack()
        model.aux.pauseRecording()
        
        for r in 1 ... seqRows {
            
            if let value = valueList.getValue( row: r) {
                
                model.enterValue( value )

                if executeFn( event, model: model) != .stateChange {
                    model.aux.resumeRecording()
                    model.resumeStack()
                    return KeyPressResult.stateError
                }
            }
        }
        model.aux.resumeRecording()
        model.resumeStack()

        // Final result is already on stack X
        return KeyPressResult.stateChange
    }
}
