//
//  Vector.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-13.
//
import Foundation


func installVector( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpPatterns( .abs, [
        
        OpPattern( [ .X([.vector]) ] ) { s0 in
            var s1 = s0
            let (x, y) = s0.Xtv.get2()
            s1.setRealValue( sqrt(x*x + y*y) )
            return s1
        },

        OpPattern( [ .X([.polar, .polarDeg]) ] ) { s0 in
            var s1 = s0
            let (r, _) = s0.Xtv.get2()
            s1.setRealValue( abs(r) )
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
            s1.setVectorValue( x,y )
            return s1
        },

        OpPattern( [ .X([.polar, .polarDeg]) ] ) { s0 in
            
            // Convert polar to rect co-ords
            var s1 = s0
            let (r, w) = s0.Xtv.get2()
            let theta = s0.Xtv.vtp == .polarDeg ? w * Double.pi / 180.0 : w
            let x: Double = r * cos(theta)
            let y: Double = r * sin(theta)
            s1.setVectorValue( x,y )
            return s1
        },
    ])

    
    // Angle parm of polar value must be Rad, Deg or untyped ( = Rad)
    let degTest: StateTest = {$0.Ytv.isReal && ($0.Yt == tagDeg || $0.Yt == tagRad || $0.Yt == tagUntyped) }
    
    
    CalculatorModel.defineOpPatterns( .polarV, [
        
        OpPattern( [ .X([.real]), .Y([.real])], where: degTest ) { s0 in
            
            // Create 2D polar value
            var s1 = s0
            s1.stackDrop()
            let r: Double = s0.Xtv.reg
            let w: Double = s0.Ytv.reg
            
            // Set unit tag same as X parm
            s1.setPolarValue( r,w, tag: s0.Xt )
            
            if s0.Yt == tagDeg {
                // Input parm Y was in deg
                s1.Xvtp = .polarDeg
            }
            return s1
        },

        OpPattern( [ .X([.vector]) ] ) { s0 in
            
            // Convert 2D vector to polar
            var s1 = s0
            let (x, y) = s0.Xtv.get2()
            let r: Double = sqrt( x*x + y*y)
            let w: Double = atan( x/y )
            s1.setPolarValue( r,w )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector])] ) { s0 in
            
            // 2D vector addition
            var s1 = s0
            s1.stackDrop()
            let (x1, y1) = s0.Xtv.getVector2D()
            let (x2, y2) = s0.Ytv.getVector2D()
            s1.setVectorValue( x1+x2, y1+y2 )
            return s1
        },
        
        OpPattern( [ .X([.polar, .polarDeg, .vector]), .Y([.polar, .polarDeg])] ) { s0 in
            
            var s1 = s0
            s1.stackDrop()
            let (x1, y1) = s0.Xtv.getVector2D()
            let (x2, y2) = s0.Ytv.getVector2D()
            let (x, y)   = (x1+x2, y1+y2)
            s1.setPolarValue( sqrt(x*x + y*y), atan(y/x), as: s0.Yvtp )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .minus, [
        
        OpPattern( [ .X([.vector]), .Y([.vector])] ) { s0 in
            
            // 2D vector subtraction
            var s1 = s0
            s1.stackDrop()
            let (x1, y1) = s0.Xtv.get2()
            let (x2, y2) = s0.Ytv.get2()
            s1.setVectorValue( x2-x1, y2-y1 )
            return s1
        }
    ])

    CalculatorModel.defineOpPatterns( .times, [
        
        OpPattern( [ .X([.real]), .Y([.vector])] ) { s0 in
            
            // Scale 2D vector
            var s1 = s0
            s1.stackDrop()
            let s: Double = s0.Xtv.reg
            let (x, y) = s0.Ytv.get2()
            s1.setVectorValue( s*x, s*y )
            return s1
        }
    ])
    
}
