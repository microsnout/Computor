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
            
            // Complex ADDITION
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                
                var s1 = s0
                s1.stackDrop()
                
                let x = s0.Xtv.getComplex()
                let y = s0.Ytv.getComplex()
                
                let zx = Comp( ratio*x.real, ratio*x.imaginary )
                
                s1.setComplexValue(zx + y, tag: s0.Yt, fmt: s0.Yfmt)
                return s1
            }
            
            // Incompatible units
            return nil
        }
    ])
    
    
    CalculatorModel.defineOpPatterns( .minus, [
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
            // Complex SUBTRACTION
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                
                var s1 = s0
                s1.stackDrop()
                
                let x = s0.Xtv.getComplex()
                let y = s0.Ytv.getComplex()
                
                let zx = Comp( ratio*x.real, ratio*x.imaginary )
                
                s1.setComplexValue(y - zx, tag: s0.Yt, fmt: s0.Yfmt)
                return s1
            }
            
            // Incompatible units
            return nil
        }
    ])
    
    
    CalculatorModel.defineOpPatterns( .times, [
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
            // Complex MULTIPLICATION
            if let (tagProduct, ratio) = typeProduct(s0.Yt, s0.Xt ) {
                var s1 = s0
                s1.stackDrop()

                let x = s0.Xtv.getComplex()
                let y = s0.Ytv.getComplex()
                
                let zx = Comp( ratio*x.real, ratio*x.imaginary )

                s1.setComplexValue(zx * y, tag: tagProduct, fmt: s0.Yfmt )
                return s1
            }
            
            // Incompatible units
            return nil
        }
    ])

    
    CalculatorModel.defineOpPatterns( .divide, [
        
        OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
            
            // Complex DIVISION
            if let (tagProduct, ratio) = typeProduct(s0.Yt, s0.Xt, quotient: true ) {
                var s1 = s0
                s1.stackDrop()

                let x = s0.Xtv.getComplex()
                let y = s0.Ytv.getComplex()
                
                let (u, v) = (y.real, y.imaginary)
                let (zRe, zIm ) = (ratio * x.real, ratio * x.imaginary)
                let mag2 = zRe*zRe + zIm*zIm
                let z = Comp( (u*zRe + v*zIm)/mag2, (v*zRe - u*zIm)/mag2 )

                s1.setComplexValue( z, tag: tagProduct, fmt: s0.Yfmt )
                return s1
            }
            
            // Incompatible units
            return nil
        }
    ])
    
    
    CalculatorModel.defineOpPatterns( .x2, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex SQUARE
            if let (tagProduct, _) = typeProduct(s0.Xt, s0.Xt ) {
                var s1 = s0
                
                let x = s0.Xtv.getComplex()
                
                s1.setComplexValue( x*x, tag: tagProduct, fmt: s0.Yfmt )
                return s1
            }
            
            // Incompatible units - NOT possible because types are the same
            assert(false)
            return nil
        }
    ])

    
    CalculatorModel.defineOpPatterns( .abs, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex ABSOLUTE
            var s1 = s0
            
            let x = s0.Xtv.getComplex()
            
            s1.setRealValue( x.length, tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        }
    ])

    
    CalculatorModel.defineOpPatterns( .zRe, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex REAL value
            var s1 = s0
            let x = s0.Xtv.getComplex()
            s1.setRealValue( x.real , tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        }
    ])

    
    CalculatorModel.defineOpPatterns( .zIm, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex REAL value
            var s1 = s0
            let x = s0.Xtv.getComplex()
            s1.setRealValue( x.imaginary , tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        }
    ])

    
    CalculatorModel.defineOpPatterns( .zArg, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex IMAGINARY value
            var s1 = s0
            let x = s0.Xtv.getComplex()
            s1.setRealValue( x.phase , tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        }
    ])

    
    CalculatorModel.defineOpPatterns( .zConj, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex CONJUGATE
            var s1 = s0
            let x = s0.Xtv.getComplex()
            s1.setComplexValue( x.conjugate , tag: s0.Xt, fmt: s0.Xfmt )
            return s1
        }
    ])

    
    CalculatorModel.defineOpPatterns( .zNorm, [
        
        OpPattern( [ .X([.complex])] ) { s0 in
            
            // Complex CONJUGATE
            var s1 = s0
            let x = s0.Xtv.getComplex()
            
            if let z = x.normalized {
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return s1
            }
            
            return nil
        }
    ])

    
    CalculatorModel.defineOpPatterns( .inv, [
        
        OpPattern( [ .X([.complex]) ] ) { s0 in
            
            // Complex RECIPROCOL
            if let (tagProduct, _) = typeProduct(tagUntyped, s0.Xt, quotient: true ) {
                var s1 = s0

                let x = s0.Xtv.getComplex()
                
                if let z = x.reciprocal {
                    s1.setComplexValue( z, tag: tagProduct, fmt: s0.Xfmt )
                    return s1
                }
            }
            
            // Incompatible units
            return nil
        }
    ])

    
    // *** TYPE Conversions ***
    
    CalculatorModel.defineOpPatterns( .complexV, [
        
        OpPattern( [ .X([.vector])] ) { s0 in
            
            // Vector to Complex
            var s1 = s0
            
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
    
    
    // *** UNIT Conversions ***

    CalculatorModel.defineConversionPatterns([
        
        ConversionPattern( [ .X([.complex]) ] ) { s0, tagTo in
            
            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                var s1 = s0
                let q = s0.Xtv.getComplex()
                let z = Comp( seq.op(q.real), seq.op(q.imaginary))
                s1.setComplexValue(z, tag: tagTo, fmt: s0.Xfmt )
                return s1
            }
            
            // Conversion not possible
            return nil
        },
    ])
}
