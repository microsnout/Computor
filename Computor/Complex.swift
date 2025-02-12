//
//  Complex.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-10.
//
import Foundation


func installComplex( _ model: CalculatorModel ) {
    
    // Set of allowed types
    let zSet: ValueTypeSet = [.complex, .real, .rational]
    
    // One operand must be complex
    let zTest: StateTest = {$0.Xvtp == .complex || $0.Yvtp == .complex}
    
    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
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
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
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
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
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
