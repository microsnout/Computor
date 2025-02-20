//
//  Vector.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-13.
//
import Foundation


func installVector( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpPatterns( .abs, [
        
        OpPattern( [ .X([.vector, .polar]) ] ) { s0 in
            var s1 = s0
            let (r, _) = s0.Xtv.getPolar2D()
            s1.setRealValue( abs(r) )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .vector2D, [
        
        OpPattern( [ .X([.real]), .Y([.real])], where: { $0.Xt == $0.Yt } ) { s0 in
            
            // Create 2D vector value
            var s1 = s0
            s1.stackDrop()
            let x: Double = s0.Xtv.reg
            let y: Double = s0.Ytv.reg
            s1.setVectorValue( x,y, tag: s0.Yt, fmt: s0.Yfmt )
            return s1
        },

        OpPattern( [ .X([.polar]) ] ) { s0 in
            
            // Convert polar to rect co-ords
            var s1 = s0
            let (r, w) = s0.Xtv.get2()
            let x: Double = r * cos(w)
            let y: Double = r * sin(w)
            s1.setVectorValue( x,y, tag: s0.Xt, fmt: s0.Xfmt )
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
            let a: Double = s0.Ytv.reg
            
            // Convert supplied parm to radians if needed
            let w = s0.Yt == tagDeg ? a / 180.0 * Double.pi : a
            
            // Copy format from X
            var fmtRec = s0.Xfmt
            if s0.Yt == tagDeg {
                // Add polar degree flag if Y is deg
                fmtRec.polarDeg = true
            }
            
            // Set unit tag same as X parm
            s1.setPolarValue( r,w, tag: s0.Xt, fmt: fmtRec )
            return s1
        },

        OpPattern( [ .X([.vector]) ] ) { s0 in
            
            // Convert 2D vector to polar
            var s1 = s0
            let (x, y) = s0.Xtv.getVector2D()
            let r: Double = sqrt( x*x + y*y)
            let w: Double = atan( x/y )
            s1.setPolarValue( r,w, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector])] ) { s0 in
            
            // 2D vector addition
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector2D()
                let (x2, y2) = s0.Ytv.getVector2D()
                
                s1.setVectorValue( x1*ratio + x2, y1*ratio + y2, tag: s0.Yt, fmt: s0.Yfmt )
                return s1
            }
            
            // Incompatible units
            return nil
        },
        
        OpPattern( [ .X([.polar, .vector]), .Y([.polar])] ) { s0 in
            
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector2D()
                let (x2, y2) = s0.Ytv.getVector2D()
                
                let (x, y)   = (x1*ratio + x2, y1*ratio + y2)
                
                s1.setPolarValue( sqrt(x*x + y*y), atan(y/x), tag: s0.Yt, fmt: s0.Yfmt)
                return s1
            }
            
            // Incompatible units
            return nil
        },
    ])

    CalculatorModel.defineOpPatterns( .minus, [
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector])] ) { s0 in
            
            // 2D vector subtraction
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector2D()
                let (x2, y2) = s0.Ytv.getVector2D()
                
                s1.setVectorValue( x2 - x1*ratio, y2 - y1*ratio, tag: s0.Yt, fmt: s0.Yfmt )
                return s1
            }
            
            // Incompatible units
            return nil
        }
    ])

    CalculatorModel.defineOpPatterns( .times, [
        
        OpPattern( [ .X([.real]), .Y([.vector])], where: { $0.Xt == tagUntyped } ) { s0 in
            
            // Scale 2D vector
            var s1 = s0
            s1.stackDrop()
            
            let s: Double = s0.Xtv.reg
            let (x, y) = s0.Ytv.getVector2D()
            
            s1.setVectorValue( s*x, s*y, tag: s0.Yt, fmt: s0.Yfmt )
            return s1
        }
    ])
    
}
