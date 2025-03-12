//
//  Functions.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-12.
//
import Foundation


func installFunctions( _ model: CalculatorModel ) {
    
    // Solve quadratic function
    // 0 = ax^2 + bx + c
    // where X=a, Y=b, Z=c
    //
    CalculatorModel.defineOpPatterns( .quad, [
        
        OpPattern( [ .X([.real]), .Y([.real]), .Z([.real])], where: { s0 in
            s0.Xt == s0.Yt && s0.Yt == s0.Zt && s0.Xt == tagUntyped
        } ) { s0 in
            
            let (a, b, c) = (s0.X, s0.Y, s0.Z)
            
            var s1 = s0
            s1.stackDrop()
            s1.stackDrop()

            let rad = b*b - 4*a*c
            
            if rad == 0.0 {
                // One solution
                s1.setRealValue( -b / 2*a, fmt: s0.Xfmt )
            }
            else if rad > 0.0 {
                // Two real solutions
                s1.setShape( rows: 2 )
                s1.stack[regX].value.set1( (-b + sqrt(rad))/2*a, r: 1 )
                s1.stack[regX].value.set1( (-b - sqrt(rad))/2*a, r: 2 )
            }
            else {
                // Return 2 complex values
                s1.stack[regX].value.setMatrix( .complex, rows: 2 )
                let re = -b/2*a
                let im = sqrt(-rad)/2*a
                s1.stack[regX].value.set2( re, im, r: 1 )
                s1.stack[regX].value.set2( re, -im, r: 2 )
            }
            return s1
        }
    ])
    
}

