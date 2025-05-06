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
        
        let maxStrCount = 20
        
        let ( _, rows, cols) = getShape()
        
        if rows > 1 {
            let rowStr = String(rows)
            let colStr = String(cols)
            let text = "ç{Units}[ç{}\(rowStr)ç{Units} x ç{}\(colStr)ç{Units}]ç{}"
            return (text, rowStr.count + colStr.count + 5)
        }
        
        var text  = "ç{Units}[ç{}"
        var count = 1
        
        for c in 1 ... cols {
            let (simpleStr, simpleCount) = renderValueSimple( c: c )
            
            if count + simpleCount > maxStrCount {
                text.append( "ç{Units}={..]}ç{}" )
                count += 3
                break
            }
            text.append(simpleStr)
            
            if c == cols {
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
            result.setShape( ss, rows: 1, cols: n )
            
            // Remove N and increment value from stack
            model.state.stackDrop()
            model.state.stackDrop()
            
            model.pauseUndoStack()
            model.aux.pauseRecording()
            
            for c in seq {
                // Copy current result value to result array
                result.setValue(model.state.Xtv, c: c)
                
                // Increment X value by inc
                model.enterValue(inc)
                
                if model.keyPress( KeyEvent( kc: .plus)) != .stateChange {
                    // Addition error
                    model.aux.resumeRecording()
                    model.resumeUndoStack()
                    return nil
                }
                
            }
            model.aux.resumeRecording()
            model.resumeUndoStack()
            
            // Copy state, remove parameters and put result in X
            var s1 = s0
            s1.stackDrop()
            s1.stackDrop()
            s1.Xtv = result
            return s1
       }
   ])
                       
    
    CalculatorModel.defineOpPatterns( .range, [
        
        OpPattern( [ .X([.real]) ], where: { s0 in isInt(s0.X) } ) { s0 in
            
            var s1 = s0
            let n = Int(floor(s0.X))
            let seq = 1 ... n
            
            s1.stack[regX].setShape( 1, rows: 1, cols: n )
            
            for x in seq {
                s1.stack[regX].set1( Double(x), c: x )
            }
            s1.stack[regX].vtp = .real
            return s1
        }
    ])
    
    
    CalculatorModel.defineOpPatterns( .mapX, [
        
        OpPattern( [ .X(allTypes, .matrix) ], where: { s0 in s0.Xtv.rows == 1 } ) { s0 in
            
            // Create a Reduce function obj capturing the value list and mode reference
            let mapFn = MapFunctionX( valueList: s0.Xtv )
            
            model.pushContext( mapFn, lastEvent: KeyEvent( kc: .mapX) )
            
            // No new state - but don't return nil or it will flag an error
            return s0
        }
    ])

    
    CalculatorModel.defineOpPatterns( .mapXY, [
        
        OpPattern( [ .X(allTypes, .matrix), .Y(allTypes, .matrix) ], where: { s0 in s0.Xtv.rows == 1 && s0.Ytv.rows == 1 } ) { s0 in
            
            // Create a Reduce function obj capturing the value list and mode reference
            let mapFn = MapFunctionXY( valueListX: s0.Xtv, valueListY: s0.Ytv )
            
            model.pushContext( mapFn, lastEvent: KeyEvent( kc: .mapX) )
            
            // No new state - but don't return nil or it will flag an error
            return s0
        }
    ])
            
    
    CalculatorModel.defineOpPatterns( .reduce, [
        
        OpPattern( [ .X(allTypes, .matrix), .Y(allTypes, .simple) ], where: { s0 in s0.Xtv.rows == 1 } ) { s0 in
            
            // Create a Reduce function obj capturing the value list and mode reference
            let reduceFn = ReduceFunction( valueList: s0.Xtv )
            
            model.pushContext( reduceFn, lastEvent: KeyEvent( kc: .reduce) )
            
            // No new state - but don't return nil or it will flag an error
            return s0
        }
    ])

    
    CalculatorModel.defineOpPatterns( .addRow, [
        
        OpPattern( [ .X(allTypes, .any), .Y(allTypes, .any) ],
                   where: { s0 in s0.Xtv.cols == s0.Ytv.cols && s0.Xtv.vtp == s0.Ytv.vtp && s0.Xtv.rows == 1 } ) { s0 in
                       
                       let rowsY = s0.Ytv.rows
                       
                       var s1 = s0
                       s1.stackDrop()
                       
                       s1.Xtv.addRows( 1 )
                       s1.Xtv.copyRow( toRow: rowsY+1, from: s0.Xtv, atRow: 1 )
                       return s1
                   }
    ])


    CalculatorModel.defineOpPatterns( .addCol, [
        
        OpPattern( [ .X(allTypes, .any), .Y(allTypes, .any) ],
                   where: { s0 in s0.Xtv.rows == s0.Ytv.rows && s0.Xtv.vtp == s0.Ytv.vtp && s0.Xtv.cols == 1 } ) { s0 in
            
                       let colsY = s0.Ytv.cols
                       
                       var s1 = s0
                       s1.stackDrop()
                       
                       s1.Xtv.addColumns( 1 )
                       s1.Xtv.copyColumn( toCol: colsY+1, from: s0.Xtv, atCol: 1 )
                       return s1
        }
    ])
    
    
    CalculatorModel.defineOpPatterns( .dotProduct, [
        
        OpPattern( [.X([.real], .matrix), .Y([.real], .matrix)],
                   where: { $0.Xtv.isRowMatrix && $0.Ytv.isRowMatrix && $0.Xtv.cols == $0.Ytv.cols  } ) { s0 in
                       var s1 = s0
                       s1.stackDrop()
                       
                       let (_, _, cols) = s0.Xtv.getShape()
                       
                       var value = 0.0
                       
                       for col in 1 ... cols {
                           value += s0.Xtv.getReal( r: 1, c: col ) * s0.Ytv.getReal( r: 1, c: col )
                       }
                       s1.Xtv.setReal(value, tag: s0.Yt, fmt: s0.Yfmt )
                       return s1
                   },

        OpPattern( [.X([.real], .matrix), .Y([.real], .matrix)],
                   where: { $0.Xtv.isColMatrix && $0.Ytv.isColMatrix && $0.Xtv.rows == $0.Ytv.rows  } ) { s0 in
                       var s1 = s0
                       s1.stackDrop()

                       let (_, rows, _) = s0.Xtv.getShape()
                       
                       var value = 0.0
                       
                       for row in 1 ... rows {
                           value += s0.Xtv.getReal( r: row, c: 1 ) * s0.Ytv.getReal( r: row, c: 1 )
                       }
                       s1.Xtv.setReal(value, tag: s0.Yt, fmt: s0.Yfmt )
                       return s1
                   },
    ])
    
    
    CalculatorModel.defineOpPatterns( .times, [
        
        OpPattern( [.X([.real], .matrix), .Y([.real], .matrix)],
                   where: { $0.Xtv.rows == $0.Ytv.cols && $0.Xvtp == $0.Yvtp  } ) { s0 in
                       
                       var s1 = s0
                       s1.stackDrop()

                       let (ssx, xRows, xCols) = s0.Xtv.getShape()
                       let (ssy, yRows, yCols) = s0.Ytv.getShape()
                       assert( xRows == yCols && ssx == ssy )
                       
                       s1.Xtv.setShape(ssx, rows: yRows, cols: xCols)

                       for col in 1 ... xCols {
                           
                           for row in 1 ... yRows {
                               
                               var value = 0.0
                               
                               for n in 1 ... yCols {
                                   
                                   value += s0.Ytv.getReal( r: row, c: n ) * s0.Xtv.getReal( r: n, c: col )
                               }
                               
                               s1.Xtv.set1(value, r: row, c: col )
                           }
                       }
                       return s1
                   },
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
            
           let ( _, rows, cols ) = s0.Ytv.getShape()
            
           let n = Int(s0.X)
                       
           if rows > 1 {
               
               guard n >= 1 && n <= rows else {
                   return nil
               }
               
               var tv = TaggedValue( s0.Yvtp, tag: s0.Yt, format: s0.Yfmt, rows: 1, cols: cols )
               
               tv.copyRow( toRow: 1, from: s0.Ytv, atRow: n)
               
               var s1 = s0
               s1.stackDrop()
               s1.Xtv = tv
               return s1
           }
           else {
               
               guard n >= 1 && n <= cols else {
                   return nil
               }
               
               guard let tv = s0.Ytv.getValue( c: n ) else {
                   return nil
               }
               
               var s1 = s0
               s1.stackDrop()
               s1.Xtv = tv
               return s1
           }
            
        },
    ])
}


class MapFunctionX : ModalContext {
    
    let valueList:  TaggedValue
    
    init( valueList: TaggedValue ) {
        self.valueList = valueList
    }
    
    override var statusString: String? { "ç{Units}Map ƒ()" }
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "MapFunction keypress: \(event.kc)")
        
        // Start with empty output list
        let seqCols    = valueList.cols
        var resultList = TaggedValue()
        
        // Remove parameter value from stack
        model.state.stackDrop()
        
        for c in 1 ... seqCols {
            
            if let value = valueList.getValue( c: c) {
                
                model.enterValue( value )
                
                if executeFn( event ) == .stateChange {
                    
                    if c == 1 {
                        // Grab the first result to define the type tag and format for result
                        let firstValue = model.state.Xtv
                        let ss = firstValue.size
                        
                        // Establish size of result and add first value
                        resultList = firstValue
                        resultList.setShape(ss, cols: seqCols)
                        resultList.setValue( firstValue, c: 1)
                    }
                    else {
                        // Add next value at correct row
                        resultList.setValue( model.state.Xtv, c: c )
                    }
                    
                    // Remove intermediate result
                    model.state.stackDrop()
                }
                else {
                    return KeyPressResult.stateError
                }
            }
        }
        
        // Push final result list
        model.enterValue(resultList)
        return KeyPressResult.stateChange
    }
}


class MapFunctionXY : ModalContext {
    
    let valueListX:  TaggedValue
    let valueListY:  TaggedValue

    init( valueListX: TaggedValue, valueListY: TaggedValue ) {
        self.valueListX = valueListX
        self.valueListY = valueListY
    }
    
    override var statusString: String? { "ç{Units}Map-xy ƒ(,)" }
    
    override func modalExecute( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "MapFunctionXY keypress: \(event.kc)")
        
        // Start with empty output list
        let seqCols    = min( valueListX.cols, valueListY.cols )
        var resultList = TaggedValue()
        
        // Remove parameters from stack
        model.state.stackDrop()
        model.state.stackDrop()

        for c in 1 ... seqCols {
            
            if let valueX = valueListX.getValue( c: c),
               let valueY = valueListY.getValue( c: c) {
                
                model.enterValue( valueY )
                model.enterValue( valueX )

                if executeFn( event ) == .stateChange {
                    
                    if c == 1 {
                        // Grab the first result to define the type tag and format for result
                        let firstValue = model.state.Xtv
                        let ss = firstValue.size
                        
                        // Establish size of result and add first value
                        resultList = firstValue
                        resultList.setShape(ss, cols: seqCols)
                        resultList.setValue( firstValue, c: 1)
                    }
                    else {
                        // Add next value at correct row
                        resultList.setValue( model.state.Xtv, c: c )
                    }
                    
                    // Remove intermediate result
                    model.state.stackDrop()
                }
                else {
                    return KeyPressResult.stateError
                }
            }
        }

        // Push final result list
        model.enterValue(resultList)
        return KeyPressResult.stateChange
    }
}


class ReduceFunction : ModalContext {
    
    let valueList:     TaggedValue
    
    init(valueList: TaggedValue ) {
        self.valueList = valueList
    }
    
    override var statusString: String? { "ƒ{0.9}ç{Units}Reduce ƒ(,)" }
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        // Start with empty output list
        let seqCols    = valueList.cols
        
        // Remove value list parameter from stack, but not initial result
        model.state.stackDrop()

        for c in 1 ... seqCols {
            
            if let value = valueList.getValue( c: c) {
                
                model.enterValue( value )

                if executeFn( event ) != .stateChange {
                    return KeyPressResult.stateError
                }
            }
        }

        // Final result is already on stack X
        return KeyPressResult.stateChange
    }
}
