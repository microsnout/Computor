//
//  Complex.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-10.
//
import Foundation


func installComplex( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X(.complex), .Y(.complex)] ) { (s0: CalcState) -> CalcState? in
            
            // Complex addition
            var s1 = s0
            s1.stackDrop()
            let x = s0.Xtv.getComplex()
            let y = s0.Ytv.getComplex()
            s1.stack[regX].value.setComplex(x + y)
            return s1
        }
    ])
    
    CalculatorModel.defineOpPatterns( .minus, [
        
        OpPattern( [ .X(.complex), .Y(.complex)] ) { (s0: CalcState) -> CalcState? in
            
            // Complex addition
            var s1 = s0
            s1.stackDrop()
            let x = s0.Xtv.getComplex()
            let y = s0.Ytv.getComplex()
            s1.stack[regX].value.setComplex(y - x)
            return s1
        }
    ])
    
    CalculatorModel.defineOpPatterns( .times, [
        
        OpPattern( [ .X(.complex), .Y(.complex)] ) { (s0: CalcState) -> CalcState? in
            
            // Complex addition
            var s1 = s0
            s1.stackDrop()
            let x = s0.Xtv.getComplex()
            let y = s0.Ytv.getComplex()
            s1.stack[regX].value.setComplex(x * y)
            return s1
        }
    ])
}
