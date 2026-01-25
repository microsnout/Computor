//
//  Complex.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-10.
//
import Foundation
import Numerics


extension CalculatorModel {
    
    func installComplex() {
        
        // Set of allowed types
        let zSet: ValueTypeSet = [.complex, .real, .rational]
        
        // One operand must be complex
        let zTest: StateTest = {$0.Xvtp == .complex || $0.Yvtp == .complex}
        
        defineOpPatterns( .plus, [
            
            OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
                
                // Complex ADDITION
                if let ratio = typeAddable( s0.Yt, s0.Xt) {
                    
                    var s1 = s0
                    s1.stackDrop()
                    
                    let x = s0.Xtv.getComplex()
                    let y = s0.Ytv.getComplex()
                    
                    let zx = Comp( ratio*x.real, ratio*x.imaginary )
                    
                    s1.setComplexValue(zx + y, tag: s0.Yt, fmt: s0.Yfmt)
                    return (KeyPressResult.stateChange, s1)
                }
                
                // Incompatible units
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        defineOpPatterns( .chs, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                var s1 = s0
                let z = s0.Xtv.getComplex()
                s1.setComplexValue( Comp(-z.real, -z.imaginary), tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        defineOpPatterns( .minus, [
            
            OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
                
                // Complex SUBTRACTION
                if let ratio = typeAddable( s0.Yt, s0.Xt) {
                    
                    var s1 = s0
                    s1.stackDrop()
                    
                    let x = s0.Xtv.getComplex()
                    let y = s0.Ytv.getComplex()
                    
                    let zx = Comp( ratio*x.real, ratio*x.imaginary )
                    
                    s1.setComplexValue(y - zx, tag: s0.Yt, fmt: s0.Yfmt)
                    return (KeyPressResult.stateChange, s1)
                }
                
                // Incompatible units
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        
        defineOpPatterns( .times, [
            
            OpPattern( [ .X(zSet), .Y(zSet)], where: zTest ) { s0 in
                
                // Complex MULTIPLICATION
                if let (tagProduct, ratio) = typeProduct(s0.Yt, s0.Xt ) {
                    var s1 = s0
                    s1.stackDrop()
                    
                    let x = s0.Xtv.getComplex()
                    let y = s0.Ytv.getComplex()
                    
                    let zx = Comp( ratio*x.real, ratio*x.imaginary )
                    
                    s1.setComplexValue(zx * y, tag: tagProduct, fmt: s0.Yfmt )
                    return (KeyPressResult.stateChange, s1)
                }
                
                // Incompatible units
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        
        defineOpPatterns( .divide, [
            
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
                    return (KeyPressResult.stateChange, s1)
                }
                
                // Incompatible units
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        
        defineOpPatterns( .sqrt, [
            
            OpPattern( [ .X([.real]) ], where: { $0.X < 0.0 } ) { s0 in
                
                // Square root of negative real value, return a complex
                var s1 = s0
                let z = Comp(0.0, sqrt( -s0.X ) )
                s1.setComplexValue(z)
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .x2, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex SQUARE
                if let (tagProduct, _) = typeProduct(s0.Xt, s0.Xt ) {
                    var s1 = s0
                    
                    let x = s0.Xtv.getComplex()
                    
                    s1.setComplexValue( x*x, tag: tagProduct, fmt: s0.Yfmt )
                    return (KeyPressResult.stateChange, s1)
                }
                
                // Incompatible units - NOT possible because types are the same
                assert(false)
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        
        defineOpPatterns( .x3, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex SQUARE
                if let (tagProduct, _) = typeProduct(s0.Xt, s0.Xt ) {
                    var s1 = s0
                    
                    let x = s0.Xtv.getComplex()
                    
                    s1.setComplexValue( x*x*x, tag: tagProduct, fmt: s0.Yfmt )
                    return (KeyPressResult.stateChange, s1)
                }
                
                // Incompatible units - NOT possible because types are the same
                assert(false)
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        
        defineOpPatterns( .abs, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex ABSOLUTE
                var s1 = s0
                
                let x = s0.Xtv.getComplex()
                
                s1.setRealValue( x.length, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .zRe, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex REAL value
                var s1 = s0
                let x = s0.Xtv.getComplex()
                s1.setRealValue( x.real , tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .zIm, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex REAL value
                var s1 = s0
                let x = s0.Xtv.getComplex()
                s1.setRealValue( x.imaginary , tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .zArg, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex IMAGINARY value
                var s1 = s0
                let x = s0.Xtv.getComplex()
                s1.setRealValue( x.phase , tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .zConj, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex CONJUGATE
                var s1 = s0
                let x = s0.Xtv.getComplex()
                s1.setComplexValue( x.conjugate , tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        
        defineOpPatterns( .zNorm, [
            
            OpPattern( [ .X([.complex])] ) { s0 in
                
                // Complex CONJUGATE
                var s1 = s0
                let x = s0.Xtv.getComplex()
                
                if let z = x.normalized {
                    s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                    return (KeyPressResult.stateChange, s1)
                }
                
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        
        defineOpPatterns( .inv, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex RECIPROCOL
                if let (tagProduct, _) = typeProduct(tagUntyped, s0.Xt, quotient: true ) {
                    var s1 = s0
                    
                    let x = s0.Xtv.getComplex()
                    
                    if let z = x.reciprocal {
                        s1.setComplexValue( z, tag: tagProduct, fmt: s0.Xfmt )
                        return (KeyPressResult.stateChange, s1)
                    }
                }
                
                // Incompatible units
                return (KeyPressResult.stateError, nil)
            }
        ])
        
        // MARK: - exp-like functions
        
        defineOpPatterns( .eExp, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex exponential
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.exp(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .cosh, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex cosh
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.cosh(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .sinh, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex sinh
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.sinh(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .tanh, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex tanh
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.tanh(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .cos, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex cos
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.cos(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .sin, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex sin
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.sin(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .tan, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex tan
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.tan(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        // MARK: - log-like functions
        
        defineOpPatterns( .log, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex log
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.log(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .acosh, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex acosh
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.acosh(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .asinh, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex asinh
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.asinh(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .atanh, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex atanh
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.atanh(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .acos, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex acos
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.acos(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .asin, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex asin
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.asin(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .atan, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex atan
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.atan(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        // MARK: - pow-like functions
        
        defineOpPatterns( .y2x, [
            
            OpPattern( [ .X([.complex]), .Y([.complex]) ] ) { s0 in
                
                // Complex pow y2x
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let y = s0.Ytv.getComplex()
                let z = Complex.pow(y, x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            },
            
            OpPattern( [ .X([.real]), .Y([.complex]) ] ) { s0 in
                
                // Complex pow y2x
                var s1 = s0
                let x = s0.Xtv.getReal()
                let y = s0.Ytv.getComplex()
                var z: Comp
                
                if let n = getInt(x) {
                    z = Complex.pow(y, n)
                }
                else {
                    let w = Comp(x, 0.0)
                    z = Complex.pow(y, w)
                }
                
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        defineOpPatterns( .sqrt, [
            
            OpPattern( [ .X([.complex]) ] ) { s0 in
                
                // Complex square root
                var s1 = s0
                let x = s0.Xtv.getComplex()
                let z = Complex.sqrt(x)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            }
        ])
        
        // MARK: - Type Conversions
        
        defineOpPatterns( .complex, [
            
            OpPattern( [ .X([.vector])] ) { s0 in
                
                // Vector to Complex
                var s1 = s0
                
                let (x, y) = s0.Xtv.getVector()
                let z = Comp(x, y)
                
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            },
            
            OpPattern( [ .X([.polar]) ] ) { s0 in
                
                // Polar to Complex
                var s1 = s0
                
                let (re, im) = s0.Xtv.getVector()
                let z = Comp(re, im)
                
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            },
            
            OpPattern( [ .X([.real], .matrix) ], where: { $0.Xtv.capacity == 2  } ) { s0 in
                
                // Create complex value value from a row or col matrix of length 2
                var s1 = s0
                let (re, im) = s0.Xtv.get2()
                let z = Comp(re, im)
                s1.setComplexValue( z, tag: s0.Xt, fmt: s0.Xfmt )
                return (KeyPressResult.stateChange, s1)
            },
        ])
        
        
        // MARK: UNIT Conversions
        
        defineUnitConversions([
            
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
}
