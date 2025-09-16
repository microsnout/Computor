//
//  Rational.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-13.
//
import Foundation


func installRational( _ model: CalculatorModel ) {
    
    // Set of allowed types
    let zSet: ValueTypeSet = [.real, .rational]
    
    // One operand must be rational
    let zTest: StateTest = {$0.Xvtp == .rational || $0.Yvtp == .rational}
    
    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
            // Rational addition
            var s1 = s0
            s1.stackDrop()
            return s1
        }
    ])
    
}

