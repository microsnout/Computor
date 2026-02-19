//
//  Map.swift
//  Computor
//
//  Created by Barry Hall on 2026-02-18.
//
import Foundation
import OSLog


extension CalculatorModel {
    
    func installMap() {
        
        
        defineOpPatterns( .mapX, [
            
            OpPattern( [ .X(allTypes, .matrix) ], where: { s0 in s0.Xtv.rows == 1 } ) { s0 in
                
                // Create a Reduce function obj capturing the value list and mode reference
                let mapFn = MapFunctionX( valueList: s0.Xtv )
                
                self.pushContext( mapFn, lastEvent: KeyEvent(.mapX) )
                
                // No new state
                return (KeyPressResult.modalFunction, nil)
            },
            
            
            OpPattern( [ .X(allTypes, .matrix) ], where: { s0 in s0.Xtv.cols == 1 } ) { s0 in
                
                // Create a Reduce function obj capturing the value list and mode reference
                let mapFn = MapFunctionXcol( valueList: s0.Xtv )
                
                self.pushContext( mapFn, lastEvent: KeyEvent(.mapX) )
                
                // No new state
                return (KeyPressResult.modalFunction, nil)
            }
        ])
        
        
        defineOpPatterns( .mapXY, [
            
            OpPattern( [ .X(allTypes, .matrix), .Y(allTypes, .matrix) ], where: { s0 in s0.Xtv.rows == 1 && s0.Ytv.rows == 1 } ) { s0 in
                
                // Create a Reduce function obj capturing the value list and mode reference
                let mapFn = MapFunctionXY( valueListX: s0.Xtv, valueListY: s0.Ytv )
                
                self.pushContext( mapFn, lastEvent: KeyEvent(.mapX) )
                
                // No new state
                return (KeyPressResult.modalFunction, nil)
            }
        ])
    }
    
}


class MapFunctionX : ModalContext {
    
    let valueList:  TaggedValue
    
    init( valueList: TaggedValue ) {
        self.valueList = valueList
    }
    
    override var statusString: String? { "Map ƒ()" }
    
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        /// ** MapX -  Modal Execute **
        
        guard let model = self.model else { return KeyPressResult.null }
        
        // Start with empty output list
        let seqCols    = valueList.cols
        var resultList = TaggedValue()
        
        // Remove parameter value from stack
        model.state.stackDrop()
        
        for c in 1 ... seqCols {
            
            if let value = valueList.getValue( c: c) {
                
                model.enterValue( value )
                
                if model.state.Xtv.cols > 1 {
                    
                    // All results must have only one column
                    return KeyPressResult.stateError
                }
                
                if executeFn( event ) == .stateChange {
                    
                    if c == 1 {
                        // Grab the first result to define the type tag and format for result
                        let firstValue = model.state.Xtv
                        let ss = firstValue.size
                        let resultRows = firstValue.rows
                        
                        // Establish size of result and add first value
                        resultList.setShape(ss, rows: resultRows, cols: seqCols)
                        
                        // Copy initial result to list which could be a single value or a row
                        resultList.copyColumn( toCol: 1, from: model.state.Xtv, atCol: 1 )
                        
                        resultList.tag = firstValue.tag
                        resultList.fmt = firstValue.fmt
                        resultList.vtp = firstValue.vtp
                    }
                    else {
                        let newResult = model.state.Xtv
                        
                        if newResult.rows != resultList.rows {
                            // All results must match the number of rows in the first
                            return KeyPressResult.stateError
                        }
                        
                        if newResult.rows == 1 {
                            // Add next value at correct row
                            resultList.setValue( model.state.Xtv, c: c )
                        }
                        else {
                            // Add a new column of values
                            resultList.copyColumn( toCol: c, from: model.state.Xtv, atCol: 1 )
                        }
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


class MapFunctionXcol : ModalContext {
    
    let valueList:  TaggedValue
    
    init( valueList: TaggedValue ) {
        self.valueList = valueList
    }
    
    override var statusString: String? { "Map ƒ()" }
    
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        /// ** MapX -  Modal Execute **
        
        guard let model = self.model else { return KeyPressResult.null }
        
        // Start with empty output list
        let seqRows    = valueList.rows
        var resultList = TaggedValue()
        
        // Remove parameter value from stack
        model.state.stackDrop()
        
        for r in 1 ... seqRows {
            
            if let value = valueList.getValue( r: r) {
                
                model.enterValue( value )
                
                if model.state.Xtv.rows > 1 {
                    
                    // All results must have only one column
                    return KeyPressResult.stateError
                }
                
                if executeFn( event ) == .stateChange {
                    
                    if r == 1 {
                        // Grab the first result to define the type tag and format for result
                        let firstValue = model.state.Xtv
                        let ss = firstValue.size
                        let resultCols = firstValue.cols
                        
                        // Establish size of result and add first value
                        resultList.setShape(ss, rows: seqRows, cols: resultCols)
                        
                        // Copy initial result to list which could be a single value or a row
                        resultList.copyRow( toRow: 1, from: model.state.Xtv, atRow: 1 )

                        resultList.tag = firstValue.tag
                        resultList.fmt = firstValue.fmt
                        resultList.vtp = firstValue.vtp
                    }
                    else {
                        let newResult = model.state.Xtv
                        
                        if newResult.cols != resultList.cols {
                            // All results must match the number of cols in the first
                            return KeyPressResult.stateError
                        }
                        
                        if newResult.cols == 1 {
                            // Add next value at correct row
                            resultList.setValue( model.state.Xtv, r: r )
                        }
                        else {
                            // Add a new column of values
                            resultList.copyRow( toRow: r, from: model.state.Xtv, atRow: 1 )
                        }
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
    
    override var statusString: String? { "Map-xy ƒ(,)" }
    
    override func modalExecute( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
#if DEBUG
        print( "MapFunctionXY keypress: \(event.keyCode)")
#endif
        
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
