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
            
            // Complex subtraction
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
            
            // Complex multiplication
            var s1 = s0
            s1.stackDrop()
            let x = s0.Xtv.getComplex()
            let y = s0.Ytv.getComplex()
            s1.stack[regX].value.setComplex(x * y)
            return s1
        }
    ])
    
    CalculatorModel.defineOpPatterns( .x2, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex square
            var s1 = s0
            s1.stackDrop()
            let x = s0.Xtv.getComplex()
            s1.stack[regX].value.setComplex( x*x )
            return s1
        }
    ])

    CalculatorModel.defineOpPatterns( .abs, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex square
            var s1 = s0
            s1.stackDrop()
            let x = s0.Xtv.getComplex()
            s1.setRealValue( sqrt(x.lengthSquared) )
            return s1
        }
    ])
    
    CalculatorModel.defineOpPatterns( .complexV, [
        
        OpPattern( [ .X([.vector])] ) { s0 in
            
            // Vector to Complex
            var s1 = s0
            s1.stackDrop()
            
            let (x, y) = s0.Xtv.getVector2D()
            let z = Comp(x, y)
            
            s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },

        OpPattern( [ .X([.polar]) ] ) { s0 in
            
            // Polar to Complex
            var s1 = s0
            
            let (re, im) = s0.Xtv.getVector2D()
            let z = Comp(re, im)
            
            s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },
    ])
}
