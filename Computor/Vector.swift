//
//  Vector.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-13.
//
import Foundation


func installVector( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpPatterns( .abs, [
        
        OpPattern( [ .X([.vector2D]) ] ) { s0 in
            var s1 = s0
            let (x, y) = s0.Xtv.get2()
            s1.stack[regX].value.setReal( sqrt( x*x + y*y ) )
            return s1
        },

        OpPattern( [ .X([.polar]) ] ) { s0 in
            var s1 = s0
            let (r, _) = s0.Xtv.get2()
            s1.stack[regX].value.setReal( abs(r) )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .vector2D, [
        
        OpPattern( [ .X([.real]), .Y([.real])] ) { s0 in
            
            // Create 2D vector value
            var s1 = s0
            s1.stackDrop()
            let x: Double = s0.Xtv.reg
            let y: Double = s0.Ytv.reg
            s1.stack[regX].value.setVector2D( x,y )
            return s1
        },

        OpPattern( [ .X([.polar]) ] ) { s0 in
            
            // Convert polar to rect co-ords
            var s1 = s0
            let (r, w) = s0.Xtv.get2()
            let x: Double = r * cos(w)
            let y: Double = r * sin(w)
            s1.stack[regX].value.setVector2D( x,y )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .polarV, [
        
        OpPattern( [ .X([.real]), .Y([.real])] ) { s0 in
            
            // Create 2D polar value
            var s1 = s0
            s1.stackDrop()
            let r: Double = s0.Xtv.reg
            let w: Double = s0.Ytv.reg
            s1.stack[regX].value.setPolar2D( r,w )
            return s1
        },

        OpPattern( [ .X([.vector2D]) ] ) { s0 in
            
            // Convert 2D vector to polar
            var s1 = s0
            let (x, y) = s0.Xtv.get2()
            let r: Double = sqrt( x*x + y*y)
            let w: Double = atan( x/y )
            s1.stack[regX].value.setPolar2D( r,w )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X([.vector2D]), .Y([.vector2D])] ) { s0 in
            
            // 2D vector addition
            var s1 = s0
            s1.stackDrop()
            let (x1, y1) = s0.Xtv.get2()
            let (x2, y2) = s0.Ytv.get2()
            s1.stack[regX].value.set2( x1+x2, y1+y2 )
            return s1
        }
    ])

    CalculatorModel.defineOpPatterns( .minus, [
        
        OpPattern( [ .X([.vector2D]), .Y([.vector2D])] ) { s0 in
            
            // 2D vector subtraction
            var s1 = s0
            s1.stackDrop()
            let (x1, y1) = s0.Xtv.get2()
            let (x2, y2) = s0.Ytv.get2()
            s1.stack[regX].value.set2( x2-x1, y2-y1 )
            return s1
        }
    ])

    CalculatorModel.defineOpPatterns( .times, [
        
        OpPattern( [ .X([.real]), .Y([.vector2D])] ) { s0 in
            
            // Scale 2D vector
            var s1 = s0
            s1.stackDrop()
            let s: Double = s0.Xtv.reg
            let (x, y) = s0.Ytv.get2()
            s1.stack[regX].value.set2( s*x, s*y )
            return s1
        }
    ])
    
}
