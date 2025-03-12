//
//  Vector.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-13.
//
import Foundation


func installVector( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpPatterns( .sign, [
        
        OpPattern( [ .X([.vector]) ] ) { s0 in
            var s1 = s0
            let (x, y) = s0.Xtv.getVector2D()
            s1.setVectorValue( -x,-y, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },
        
        OpPattern( [ .X([.polar]) ] ) { s0 in
            var s1 = s0
            let (r, w) = s0.Xtv.getPolar2D()
            s1.setPolarValue( r, w >= Double.pi ? (w - Double.pi) : (w + Double.pi), tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .abs, [
        
        OpPattern( [ .X([.vector, .polar]) ] ) { s0 in
            var s1 = s0
            let (r, _) = s0.Xtv.getPolar2D()
            s1.setRealValue( abs(r), tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },
    ])
    
    CalculatorModel.defineOpPatterns( .zArg, [
        
        OpPattern( [ .X([.vector, .polar]) ] ) { s0 in
            var s1 = s0
            let (_, w) = s0.Xtv.getPolar2D()
            
            if s0.Xvtp == .polar && s0.Xfmt.polarAngle == .degrees {
                s1.setRealValue( rad2deg(w), tag: tagDeg, fmt: s0.Xfmt )
            }
            else {
                s1.setRealValue( w, tag: s0.Xt, fmt: s0.Xfmt )
            }
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
            let (x, y) = polar2rect(r,w)
            s1.setVectorValue( x,y, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },

        OpPattern( [ .X([.complex]) ] ) { s0 in
            
            // Convert complex to vector
            var s1 = s0
            let z = s0.Xtv.getComplex()
            s1.setVectorValue( z.real, z.imaginary, tag: s0.Xt, fmt: s0.Xfmt )
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
                fmtRec.polarAngle = .degrees
            }
            
            // Set unit tag same as X parm
            s1.setPolarValue( r,w, tag: s0.Xt, fmt: fmtRec )
            return s1
        },

        OpPattern( [ .X([.vector]) ] ) { s0 in
            
            // Convert 2D vector to polar
            var s1 = s0
            let (x, y) = s0.Xtv.getVector2D()
            let (r, w) = rect2polar(x,y)
            s1.setPolarValue( r,w, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },

        OpPattern( [ .X([.complex]) ] ) { s0 in
            
            // Convert complex to polar
            var s1 = s0
            let z = s0.Xtv.getComplex()
            s1.setPolarValue( z.length, z.phase, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        },
    ])

    CalculatorModel.defineOpPatterns( .plus, [
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector])] ) { s0 in
            
            // 2D vector ADDITION
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
                let (r, w) = rect2polar(x,y)
                
                s1.setPolarValue( r,w, tag: s0.Yt, fmt: s0.Yfmt)
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
        },

        OpPattern( [ .X([.real]), .Y([.polar])], where: { $0.Xt == tagUntyped } ) { s0 in
            
            // Scale 2D vector
            var s1 = s0
            s1.stackDrop()
            
            let s: Double = s0.Xtv.reg
            let (r, w) = s0.Ytv.getPolar2D()
            
            s1.setPolarValue( s*r, w, tag: s0.Yt, fmt: s0.Yfmt )
            return s1
        },
    ])
    
    
    // *** UNIT Conversions ***
    
    CalculatorModel.defineUnitConversions([
        
        ConversionPattern( [ .X([.vector]) ] ) { s0, tagTo in
            
            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                var s1 = s0
                let (x, y) = s0.Xtv.getVector2D()
                s1.setVectorValue( seq.op(x), seq.op(y), tag: tagTo, fmt: s0.Xfmt )
                return s1
            }
            
            // Conversion not possible
            return nil
        },
        
        ConversionPattern( [ .X([.polar]) ] ) { s0, tagTo in
            
            var s1 = s0
            
            if tagTo == tagDeg {
                if s0.Xfmt.polarAngle == .radians {
                    s1.Xfmt.polarAngle = .degrees
                   return s1
                }
                return nil
            }

            if tagTo == tagRad {
                if s0.Xfmt.polarAngle == .degrees {
                    s1.Xfmt.polarAngle = .radians
                    return s1
                }
                return nil
            }
            
            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                let (r, w) = s0.Xtv.getPolar2D()
                s1.setPolarValue( seq.op(r), w, tag: tagTo, fmt: s0.Xfmt )
                return s1
            }
            
            return nil
        },
    ])
}
