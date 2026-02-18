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
        
        if rows > 1 && cols > 1 {
            let rowStr = String(rows)
            let colStr = String(cols)
            let text = "ç{UnitText}[ç{}\(rowStr)ç{UnitText} x ç{}\(colStr)ç{UnitText}]ç{}"
            return (text, rowStr.count + colStr.count + 5)
        }
        
        var text  = "ç{UnitText}[ç{}"
        var count = 1
        
        if rows == 1 {
            // Row matrix
            
            for c in 1 ... cols {
                let (simpleStr, simpleCount) = renderValueSimple( c: c )
                
                if count + simpleCount > maxStrCount {
                    text.append( "ç{UnitText}={..]}ç{}" )
                    count += 3
                    break
                }
                text.append(simpleStr)
                
                if c == cols {
                    text.append( "ç{UnitText}]ç{}" )
                    count += simpleCount + 1
                }
                else {
                    text.append( "ç{UnitText}={, }ç{}" )
                    count += simpleCount + 2
                }
            }
        }
        else {
            // Column matrix
            
            for row in 1 ... rows {
                let (simpleStr, simpleCount) = renderValueSimple( r: row )
                
                if count + simpleCount > maxStrCount {
                    text.append( "ç{UnitText}={..]}ç{}" )
                    count += 3
                    break
                }
                text.append(simpleStr)
                
                if row == rows {
                    text.append( "ç{UnitText}]^{T}ç{}" )
                    count += simpleCount + 2
                }
                else {
                    text.append( "ç{UnitText}={, }ç{}" )
                    count += simpleCount + 2
                }
            }
        }
        
        if tag != tagUntyped {
            // Add unit string
            if let sym = tag.symbol {
                text.append( "ç{UnitText}={ }ƒ{0.9}\(sym)ƒ{}ç{}" )
                count += sym.count + 1
            }
        }

        return (text, count)
    }
}


extension CalculatorModel {
    
    func installMatrix() {
        
        let allTypes: Set<ValueType> = [.real, .rational, .complex, .vector, .vector3D, .polar, .spherical]
        
        defineOpPatterns( .dms, [
            
            OpPattern( [ .X([.real], .matrix) ], where: { $0.Xtv.capacity == 3 || $0.Xtv.capacity == 2  } ) { s0 in
                
                // Convert a row or column matrix of length 2 or 3 to a deg:min:sec value
                var s1 = s0
                var deg,min,sec,value: Double
                
                if s0.Xtv.capacity == 3 {
                    (deg, min, sec) = s0.Xtv.get3()
                    value = deg + min/60.0 + sec/3600.0
                }
                else {
                    (deg, min) = s0.Xtv.get2()
                    value = deg + min/60.0
                }
                
                let tagDeg = TypeDef.tagFromSym("deg") ?? tagUntyped
                s1.Xtv.setReal( value, tag: tagDeg, fmt: FormatRec( style: .dms) )
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .dm, [
            
            OpPattern( [ .X([.real], .matrix) ], where: { $0.Xtv.capacity == 2  } ) { s0 in
                
                // Convert a row or column matrix of length 2 to a deg:min value
                var s1 = s0
                
                let (deg, min) = s0.Xtv.get2()
                let  value = deg + min/60.0
                let tagDeg = TypeDef.tagFromSym("deg") ?? tagUntyped
                s1.Xtv.setReal( value, tag: tagDeg, fmt: FormatRec( style: .dm) )
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .seq, [
            
            OpPattern( [ .X([.real]), .Y(allTypes), .Z(allTypes) ], where: { s0 in isInt(s0.X) } ) { s0 in
                
                self.withModalConfirmation( prompt: "Sequence", regLabels: ["Number", "Inc", "Initial"] ) { model in
                    
                    // Copy parameters n and inc from s0
                    let s0 = model.state
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
                    model.pauseRecording()
                    
                    for c in seq {
                        // Copy current result value to result array
                        result.setValue(model.state.Xtv, c: c)
                        
                        // Increment X value by inc
                        model.enterValue(inc)
                        
                        if model.keyPress( KeyEvent(.plus)) != .stateChange {
                            // Addition error
                            model.resumeRecording()
                            model.resumeUndoStack()
                            return (KeyPressResult.stateError, nil)
                        }
                        
                    }
                    model.resumeRecording()
                    model.resumeUndoStack()
                    
                    // Copy state, remove parameters and put result in X
                    var s1 = s0
                    s1.stackDrop()
                    s1.stackDrop()
                    s1.Xtv = result
                    
                    return (KeyPressResult.stateChange, s1)
                }
            }
        ])
        
        
        defineOpPatterns( .range, [
            
            OpPattern( [ .X([.real]) ], where: { s0 in isInt(s0.X) } ) { s0 in
                
                var s1 = s0
                let n = Int(floor(s0.X))
                let seq = 1 ... n
                
                s1.stack[regX].setShape( 1, rows: 1, cols: n )
                
                for x in seq {
                    s1.stack[regX].set1( Double(x), c: x )
                }
                s1.stack[regX].vtp = .real
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .reduce, [
            
            OpPattern( [ .X(allTypes, .matrix), .Y(allTypes, .simple) ], where: { s0 in s0.Xtv.rows == 1 } ) { s0 in
                
                // Create a Reduce function obj capturing the value list and mode reference
                let reduceFn = ReduceFunction( valueList: s0.Xtv )
                
                self.pushContext( reduceFn, lastEvent: KeyEvent(.reduce) )
                
                // No new state - but don't return nil or it will flag an error
                return (KeyPressResult.modalFunction, nil)
            }
        ])
        
        
        defineOpPatterns( .addRow, [
            
            OpPattern( [ .X(allTypes, .any), .Y(allTypes, .any) ],
                       where: { s0 in s0.Xtv.cols == s0.Ytv.cols && s0.Xtv.vtp == s0.Ytv.vtp && s0.Xtv.rows == 1 } ) { s0 in
                           
                           let rowsY = s0.Ytv.rows
                           
                           var s1 = s0
                           s1.stackDrop()
                           
                           s1.Xtv.addRows( 1 )
                           s1.Xtv.copyRow( toRow: rowsY+1, from: s0.Xtv, atRow: 1 )
                           return (KeyPressResult.stateChange, s1)
                       }
        ])
        
        
        defineOpPatterns( .addCol, [
            
            OpPattern( [ .X(allTypes, .any), .Y(allTypes, .any) ],
                       where: { s0 in s0.Xtv.rows == s0.Ytv.rows && s0.Xtv.vtp == s0.Ytv.vtp && s0.Xtv.cols == 1 } ) { s0 in
                           
                           let colsY = s0.Ytv.cols
                           
                           var s1 = s0
                           s1.stackDrop()
                           
                           s1.Xtv.addColumns( 1 )
                           s1.Xtv.copyColumn( toCol: colsY+1, from: s0.Xtv, atCol: 1 )
                           return (KeyPressResult.stateChange, s1)
                       }
        ])
        
        
        defineOpPatterns( .dotProduct, [
            
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
                           return (KeyPressResult.stateChange, s1)
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
                           return (KeyPressResult.stateChange, s1)
                       },
        ])
        
        
        defineOpPatterns( .times, [
            
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
                           return (KeyPressResult.stateChange, s1)
                       },
            
            
            OpPattern( [.X([.real]), .Y([.real], .matrix)] ) { s0 in
                
                /// Multiply any matrix by a real scalar
                
                // Scalar value X
                let x = s0.X
                
                var s1 = s0
                s1.stackDrop()
                
                s1.Xtv.transformValues() { value, _, _, _ in
                    return x*value
                }
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .transpose, [
            
            OpPattern( [.X(allTypes, .matrix)] ) { s0 in
                
                var s1 = s0
                let (_, rows, cols) = s0.Xtv.getShape()
                
                var tr = TaggedValue( s0.Xvtp, tag: s0.Xt, format: s0.Xfmt, rows: cols, cols: rows )
                
                for row in 1 ... rows {
                    
                    for col in 1 ... cols {
                        
                        if let val = s0.Xtv.getValue( r: row, c: col ) {
                            tr.setValue( val, r: col, c: row)
                        }
                    }
                }
                
                s1.stack[regX] = tr
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .identity, [
            
            OpPattern( [.X([.real])], where: { isInt($0.X) } ) { s0 in
                
                var s1 = s0
                
                let n = getInt(s0.X) ?? 2
                
                s1.stack[regX].setShape(1, rows: n, cols: n)
                
                for i in 1 ... n {
                    s1.set1( 1.0, r: i, c: i)
                }
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .minX, [
            
            OpPattern( [.X([.real], .matrix)], where: { $0.Xtv.cols > 1 } ) { s0 in
                
                var s1 = s0
                s1.stackDrop()
                
                let (_, _, cols) = s0.Xtv.getShape()
                
                var minX: Double = s0.Xtv.getReal( r: 1, c: 1 )
                
                for col in 2...cols {
                    minX = min( minX, s0.Xtv.getReal( r: 1, c: col ) )
                }
                
                s1.pushRealValue(minX)
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .maxX, [
            
            OpPattern( [.X([.real], .matrix)], where: { $0.Xtv.cols > 1 } ) { s0 in
                
                var s1 = s0
                s1.stackDrop()
                
                let (_, _, cols) = s0.Xtv.getShape()
                
                var maxX: Double = s0.Xtv.getReal( r: 1, c: 1 )
                
                for col in 2...cols {
                    maxX = max( maxX, s0.Xtv.getReal( r: 1, c: col ) )
                }
                
                s1.pushRealValue(maxX)
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .stdDev, [
            
            /// Standard Deviation
            
            OpPattern( [.X([.real], .matrix)] ) { s0 in
                
                var s1 = s0
                s1.stackDrop()
                
                let (_, _, cols) = s0.Xtv.getShape()
                
                let n = Double(cols)
                
                // Find the mean
                var sum: Double = 0.0
                
                for col in 1...cols {
                    sum += s0.Xtv.getReal( r: 1, c: col )
                }
                let mean = sum/n
                
                var dev = 0.0
                
                for col in 1...cols {
                    dev += pow(s0.Xtv.getReal( r: 1, c: col) - mean, 2.0)
                }
                
                s1.pushRealValue( sqrt(dev / Double(cols-1)) )
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .mean, [
            
            OpPattern( [.X([.real], .matrix)] ) { s0 in
                
                var s1 = s0
                s1.stackDrop()
                
                let (_, _, cols) = s0.Xtv.getShape()
                
                var sum: Double = 0.0
                
                for col in 1...cols {
                    sum += s0.Xtv.getReal( r: 1, c: col )
                }
                
                s1.pushRealValue(sum / Double(cols))
                return (KeyPressResult.stateChange, s1)
            },
        ])

        
        defineOpPatterns( .reverseCols, [
            
            OpPattern( [.X(allTypes, .matrix)] ) { s0 in
                
                var s1 = s0
                s1.Xtv.reverseCols()
                return (KeyPressResult.stateChange, s1)
            },
        ])

        
        defineOpPatterns( .reverseRows, [
            
            OpPattern( [.X(allTypes, .matrix)] ) { s0 in
                
                var s1 = s0
                s1.Xtv.reverseRows()
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        // *** UNIT Conversions ***
        
        defineUnitConversions([
            
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
        defineOpPatterns( .matrix, [
            
            // X must be integer, Y must be matrix, any type
            OpPattern( [ .X([.real]), .Y([.real, .rational, .complex, .vector, .polar, .vector3D, .spherical], .matrix) ],
                       where: { s0 in isInt(s0.X) } ) { s0 in
                           
                           let ( _, rows, cols ) = s0.Ytv.getShape()
                           
                           let n = Int(s0.X)
                           
                           if rows > 1 {
                               
                               guard n >= 1 && n <= rows else {
                                   return (KeyPressResult.stateError, nil)
                               }
                               
                               var tv = TaggedValue( s0.Yvtp, tag: s0.Yt, format: s0.Yfmt, rows: 1, cols: cols )
                               
                               tv.copyRow( toRow: 1, from: s0.Ytv, atRow: n)
                               
                               var s1 = s0
                               s1.stackDrop()
                               s1.Xtv = tv
                               return (KeyPressResult.stateChange, s1)
                           }
                           else {
                               
                               guard n >= 1 && n <= cols else {
                                   return (KeyPressResult.stateError, nil)
                               }
                               
                               guard let tv = s0.Ytv.getValue( c: n ) else {
                                   return (KeyPressResult.stateError, nil)
                               }
                               
                               var s1 = s0
                               s1.stackDrop()
                               s1.Xtv = tv
                               return (KeyPressResult.stateChange, s1)
                           }
                           
                       },
        ])
        
        
        // Install Map functions from Map.swift
        self.installMap()
    }
}


class ReduceFunction : ModalContext {
    
    let valueList:     TaggedValue
    
    init(valueList: TaggedValue ) {
        self.valueList = valueList
    }
    
    override var statusString: String? { "ƒ{0.9}Reduce ƒ(,)" }
    
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
