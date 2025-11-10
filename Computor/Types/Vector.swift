//
//  Vector.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-13.
//
import Foundation


func installVector( _ model: CalculatorModel ) {
    
    CalculatorModel.defineOpPatterns( .chs, [
        
        /// Sign change +/-  Invert direction of vector
        
        OpPattern( [ .X([.vector]) ] ) { s0 in
            var s1 = s0
            let (x, y) = s0.Xtv.getVector()
            s1.setVectorValue( -x,-y, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
        
        OpPattern( [ .X([.vector3D]) ] ) { s0 in
            var s1 = s0
            let (x, y, z) = s0.Xtv.getVector3D()
            s1.setVector3DValue( -x,-y,-z, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.polar]) ] ) { s0 in
            var s1 = s0
            let (r, w) = s0.Xtv.getPolar()
            s1.setPolarValue( r, w >= Double.pi ? (w - Double.pi) : (w + Double.pi), tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
        
        OpPattern( [ .X([.spherical]) ] ) { s0 in
            var s1 = s0
            let (x, y, z) = s0.Xtv.getVector3D()
            let (r, w, p) = rect2spherical(x,y,z)
            s1.setSphericalValue( r,w,p, tag: s0.Xt, fmt: s0.Xfmt  )
            return (KeyPressResult.stateChange, s1)
        },
    ])

    CalculatorModel.defineOpPatterns( .abs, [
        
        /// Absolute value of vector - length
        
        OpPattern( [ .X([.vector, .polar]) ] ) { s0 in
            var s1 = s0
            let (r, _) = s0.Xtv.getPolar()
            s1.setRealValue( abs(r), tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
        
        OpPattern( [ .X([.vector3D, .spherical]) ] ) { s0 in
            var s1 = s0
            let (r, _, _) = s0.Xtv.getSpherical()
            s1.setRealValue( abs(r), tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])
    
    CalculatorModel.defineOpPatterns( .zArg, [
        
        OpPattern( [ .X([.vector, .polar]) ] ) { s0 in
            var s1 = s0
            let (_, w) = s0.Xtv.getPolar()
            
            if s0.Xvtp == .polar && s0.Xfmt.polarAngle == .degrees {
                s1.setRealValue( rad2deg(w), tag: tagDeg, fmt: s0.Xfmt )
            }
            else {
                s1.setRealValue( w, tag: s0.Xt, fmt: s0.Xfmt )
            }
            return (KeyPressResult.stateChange, s1)
        },
    ])

    CalculatorModel.defineOpPatterns( .vector, [
        
        /// Make 2D vector from 2 reals, one polar vector or a complex number
        
        OpPattern( [ .X([.real]), .Y([.real])], where: { $0.Xt == $0.Yt } ) { s0 in
            
            // Create 2D vector value
            var s1 = s0
            s1.stackDrop()
            let x: Double = s0.X
            let y: Double = s0.Y
            s1.setVectorValue( x,y, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.polar]) ] ) { s0 in
            
            // Convert polar to rect co-ords
            var s1 = s0
            let (r, w) = s0.Xtv.get2()
            let (x, y) = polar2rect(r,w)
            s1.setVectorValue( x,y, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.complex]) ] ) { s0 in
            
            // Convert complex to vector
            var s1 = s0
            let z = s0.Xtv.getComplex()
            s1.setVectorValue( z.real, z.imaginary, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])

    
    // Angle parm of polar value must be Rad, Deg or untyped ( = Rad)
    let degTestY: StateTest = {$0.Ytv.isReal && ($0.Yt == tagDeg || $0.Yt == tagRad || $0.Yt == tagUntyped) }
    
    
    CalculatorModel.defineOpPatterns( .polar, [
        
        ///  Make a polar vector from 2 reals, a 2D vector or a complex number
        
        OpPattern( [ .X([.real]), .Y([.real])], where: degTestY ) { s0 in
            
            // Create 2D polar value
            var s1 = s0
            s1.stackDrop()
            let r: Double = s0.X
            let a: Double = s0.Y
            
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
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.vector]) ] ) { s0 in
            
            // Convert 2D vector to polar
            var s1 = s0
            let (x, y) = s0.Xtv.getVector()
            let (r, w) = rect2polar(x,y)
            s1.setPolarValue( r,w, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.complex]) ] ) { s0 in
            
            // Convert complex to polar
            var s1 = s0
            let z = s0.Xtv.getComplex()
            s1.setPolarValue( z.length, z.phase, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])

    
    CalculatorModel.defineOpPatterns( .vector3D, [
        
        /// Make a 3D vector from 3 reals (all of the same type) or a spherical vector
        
        OpPattern( [ .X([.real]), .Y([.real]), .Z([.real]) ],
                   where: { $0.Xt == $0.Yt  &&  $0.Yt == $0.Zt } ) { s0 in
            
            // Create 2D vector value
            var s1 = s0
            s1.stackDrop()
            s1.stackDrop()
            let x: Double = s0.X
            let y: Double = s0.Y
            let z: Double = s0.Z
            s1.setVector3DValue( x,y,z, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.spherical]) ] ) { s0 in
            
            // Convert polar to rect co-ords
            var s1 = s0
            let (r, w, p) = s0.Xtv.get3()
            let (x, y, z) = spherical2rect(r,w,p)
            s1.setVector3DValue( x,y,z, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])

    
    let degTestZ: StateTest = {$0.Ztv.isReal && ($0.Zt == tagDeg || $0.Zt == tagRad || $0.Zt == tagUntyped) }

    CalculatorModel.defineOpPatterns( .spherical, [
        
        /// Make a spherical vector from 3 reals or a 3D vector
        
        OpPattern( [ .X([.real]), .Y([.real]), .Z([.real]) ],
                   where: { degTestY($0) && degTestZ($0) } ) { s0 in
                       
           // Create 2D vector value
           var s1 = s0
           s1.stackDrop()
           s1.stackDrop()

           let r: Double = s0.X
           var w: Double = s0.Y
           var p: Double = s0.Z
                       
           // Convert supplied parms to radians if needed
           w = (s0.Yt == tagDeg) ? w / 180.0 * Double.pi : w
           p = (s0.Zt == tagDeg) ? p / 180.0 * Double.pi : p
                       
           // Copy format from X
           var fmtRec = s0.Xfmt
           if s0.Yt == tagDeg {
               // Add polar degree flag if Y is deg
               fmtRec.polarAngle = .degrees
           }

           s1.setSphericalValue( r,w,p, tag: s0.Xt, fmt: fmtRec )
           return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.vector3D]) ] ) { s0 in
            
            // Convert rect to spherical
            var s1 = s0
            let (x, y, z) = s0.Xtv.get3()
            let (r, w, p) = rect2spherical(x,y,z)
            s1.setSphericalValue( r,w,p, tag: s0.Xt, fmt: s0.Xfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])
    
    
    CalculatorModel.defineOpPatterns( .plus, [
        
        /// Addition of vectors
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector])] ) { s0 in
            
            // 2D vector ADDITION
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector()
                let (x2, y2) = s0.Ytv.getVector()
                
                s1.setVectorValue( x1*ratio + x2, y1*ratio + y2, tag: s0.Yt, fmt: s0.Yfmt )
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
        
        OpPattern( [ .X([.polar, .vector]), .Y([.polar])] ) { s0 in
            
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector()
                let (x2, y2) = s0.Ytv.getVector()
                
                let (x, y)   = (x1*ratio + x2, y1*ratio + y2)
                let (r, w) = rect2polar(x,y)
                
                s1.setPolarValue( r,w, tag: s0.Yt, fmt: s0.Yfmt)
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },

        OpPattern( [ .X([.vector3D, .spherical]), .Y([.vector3D])] ) { s0 in
            
            // 3D vector ADDITION
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1, z1) = s0.Xtv.getVector3D()
                let (x2, y2, z2) = s0.Ytv.getVector3D()
                
                s1.setVector3DValue( x1*ratio + x2, y1*ratio + y2, z1*ratio + z2, tag: s0.Yt, fmt: s0.Yfmt )
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
        
        OpPattern( [ .X([.spherical, .vector3D]), .Y([.spherical])] ) { s0 in
            
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1, z1) = s0.Xtv.getVector3D()
                let (x2, y2, z2) = s0.Ytv.getVector3D()
                
                let (x, y, z)   = (x1*ratio + x2, y1*ratio + y2, z1*ratio + z2)
                let (r, w, p) = rect2spherical(x,y,z)
                
                s1.setSphericalValue( r,w,p, tag: s0.Yt, fmt: s0.Yfmt)
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
    ])

    CalculatorModel.defineOpPatterns( .minus, [
        
        /// Vector Subtraction operations
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector])] ) { s0 in
            
            // 2D vector subtraction
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector()
                let (x2, y2) = s0.Ytv.getVector()
                
                s1.setVectorValue( x2 - x1*ratio, y2 - y1*ratio, tag: s0.Yt, fmt: s0.Yfmt )
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
        
        OpPattern( [ .X([.polar, .vector]), .Y([.polar])] ) { s0 in
            
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector()
                let (x2, y2) = s0.Ytv.getVector()
                
                let (x, y)   = (x2 - x1*ratio, y2 - y1*ratio)
                let (r, w) = rect2polar(x,y)
                
                s1.setPolarValue( r,w, tag: s0.Yt, fmt: s0.Yfmt)
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },

        OpPattern( [ .X([.vector3D, .spherical]), .Y([.vector3D])] ) { s0 in
            
            // 3D vector ADDITION
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1, z1) = s0.Xtv.getVector3D()
                let (x2, y2, z2) = s0.Ytv.getVector3D()
                
                s1.setVector3DValue( x2 - x1*ratio, y2 - y1*ratio, z2 - z1*ratio, tag: s0.Yt, fmt: s0.Yfmt )
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
        
        OpPattern( [ .X([.spherical, .vector3D]), .Y([.spherical])] ) { s0 in
            
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1, z1) = s0.Xtv.getVector3D()
                let (x2, y2, z2) = s0.Ytv.getVector3D()
                
                let (x, y, z)   = (x2 - x1*ratio, y2 - y1*ratio, z2 - z1*ratio)
                let (r, w, p) = rect2spherical(x,y,z)
                
                s1.setSphericalValue( r,w,p, tag: s0.Yt, fmt: s0.Yfmt)
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
    ])

    CalculatorModel.defineOpPatterns( .times, [
        
        /// Multiplication of vector by a scalar real
        
        OpPattern( [ .X([.real]), .Y([.vector])], where: { $0.Xt == tagUntyped } ) { s0 in
            
            // Scale 2D vector
            var s1 = s0
            s1.stackDrop()
            
            let s: Double = s0.X
            let (x, y) = s0.Ytv.getVector()
            
            s1.setVectorValue( s*x, s*y, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.real]), .Y([.polar])], where: { $0.Xt == tagUntyped } ) { s0 in
            
            // Scale 2D vector
            var s1 = s0
            s1.stackDrop()
            
            let s: Double = s0.X
            let (r, w) = s0.Ytv.getPolar()
            
            s1.setPolarValue( s*r, w, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.polar]), .Y([.polar])], where: { $0.Xt == $0.Yt } ) { s0 in
            
            // Multiply Polars which could by considered complex values
            var s1 = s0
            s1.stackDrop()
            
            let (rx, wx) = s0.Xtv.getPolar()
            let (ry, wy) = s0.Ytv.getPolar()

            s1.setPolarValue( rx*ry, wx+wy, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.real]), .Y([.vector3D])], where: { $0.Xt == tagUntyped } ) { s0 in
            
            // Scale 3D vector
            var s1 = s0
            s1.stackDrop()
            
            let s: Double = s0.X
            let (x, y, z) = s0.Ytv.getVector3D()
            
            s1.setVector3DValue( s*x, s*y, s*z, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },

        OpPattern( [ .X([.real]), .Y([.spherical])], where: { $0.Xt == tagUntyped } ) { s0 in
            
            // Scale spherical vector
            var s1 = s0
            s1.stackDrop()
            
            let s: Double = s0.Xtv.reg
            let (r, w, p) = s0.Ytv.getSpherical()
            
            s1.setSphericalValue( s*r, w, p, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])
    
    
    CalculatorModel.defineOpPatterns( .divide, [
        
        OpPattern( [ .X([.polar]), .Y([.polar])], where: { $0.Xt == $0.Yt } ) { s0 in
            
            // Divide Polars which could by considered complex values
            var s1 = s0
            s1.stackDrop()
            
            let (rx, wx) = s0.Xtv.getPolar()
            let (ry, wy) = s0.Ytv.getPolar()
            
            s1.setPolarValue( ry/rx, wy-wx, tag: s0.Yt, fmt: s0.Yfmt )
            return (KeyPressResult.stateChange, s1)
        },
    ])


    CalculatorModel.defineOpPatterns( .dotProduct, [
        
        /// Vector  dot product
        
        OpPattern( [ .X([.vector, .polar]), .Y([.vector, .polar])] ) { s0 in
            
            // 2D vector dot product
            if let (tag, ratio) = typeProduct( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1) = s0.Xtv.getVector()
                let (x2, y2) = s0.Ytv.getVector()
                
                s1.setRealValue( x2 * x1*ratio + y2 * y1*ratio, tag: tag, fmt: s0.Yfmt )
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
        
        OpPattern( [ .X([.vector3D, .spherical]), .Y([.vector3D, .spherical])] ) { s0 in
            
            // 2D vector dot product
            if let (tag, ratio) = typeProduct( s0.Yt, s0.Xt) {
                var s1 = s0
                s1.stackDrop()
                
                let (x1, y1, z1) = s0.Xtv.getVector3D()
                let (x2, y2, z2) = s0.Ytv.getVector3D()
                
                s1.setRealValue( x2 * x1*ratio + y2 * y1*ratio + z2 * z1*ratio,
                                 tag: tag, fmt: s0.Yfmt )
                return (KeyPressResult.stateChange, s1)
            }
            
            // Incompatible units
            return (KeyPressResult.stateError, nil)
        },
        
    ])

    
    // Indexing operator [] uses .matrix keycode for now
    CalculatorModel.defineOpPatterns( .matrix, [
        
        OpPattern( [ .X([.real]), .Y([.vector, .complex]) ],
                   where: { s0 in isInt(s0.X) } ) { s0 in
                       
                       let n = Int(s0.X)
                       
                       guard n >= 1 && n <= 2 else {
                           return (KeyPressResult.stateError, nil)
                       }
                       
                       let (x, y) = s0.Ytv.getVector()
                       
                       var s1 = s0
                       s1.stackDrop()
                       
                       s1.setRealValue( n == 1 ? x : y, tag: s0.Yt, fmt: s0.Yfmt )
                       return (KeyPressResult.stateChange, s1)
                   },

        OpPattern( [ .X([.real]), .Y([.polar]) ],
                   where: { s0 in isInt(s0.X) } ) { s0 in
                       
                       let n = Int(s0.X)
                       
                       guard n >= 1 && n <= 2 else {
                           return (KeyPressResult.stateError, nil)
                       }
                       
                       let (r, w) = s0.Ytv.getPolar()
                       
                       var s1 = s0
                       s1.stackDrop()
                       
                       if n == 1 {
                           s1.setRealValue( r, tag: s0.Yt, fmt: s0.Yfmt )
                       }
                       else if s0.Yfmt.polarAngle == .degrees {
                           s1.setRealValue( w * 180/Double.pi, tag: tagDeg, fmt: s0.Yfmt )
                       }
                       else {
                           s1.setRealValue( w, tag: tagRad, fmt: s0.Yfmt )
                       }
                       return (KeyPressResult.stateChange, s1)
                   },
        
        // TODO: Add index op for spherical

        OpPattern( [ .X([.real]), .Y([.vector3D]) ],
                   where: { s0 in isInt(s0.X) } ) { s0 in
                       
                       let n = Int(s0.X)
                       
                       guard n >= 1 && n <= 3 else {
                           return (KeyPressResult.stateError, nil)
                       }
                       
                       let (x, y, z) = s0.Ytv.getVector3D()
                       
                       var s1 = s0
                       s1.stackDrop()
                       
                       s1.setRealValue( n == 1 ? x : (n == 2 ? y : z), tag: s0.Yt, fmt: s0.Yfmt )
                       return (KeyPressResult.stateChange, s1)
                   },
    ])

    // *** UNIT Conversions ***
    
    CalculatorModel.defineUnitConversions([
        
        ConversionPattern( [ .X([.vector]) ] ) { s0, tagTo in
            
            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                var s1 = s0
                let (x, y) = s0.Xtv.getVector()
                s1.setVectorValue( seq.op(x), seq.op(y), tag: tagTo, fmt: s0.Xfmt )
                return s1
            }
            
            // Conversion not possible
            return nil
        },

        ConversionPattern( [ .X([.vector3D]) ] ) { s0, tagTo in
            
            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                var s1 = s0
                let (x, y, z) = s0.Xtv.getVector3D()
                s1.setVector3DValue( seq.op(x), seq.op(y), seq.op(z), tag: tagTo, fmt: s0.Xfmt )
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
                let (r, w) = s0.Xtv.getPolar()
                s1.setPolarValue( seq.op(r), w, tag: tagTo, fmt: s0.Xfmt )
                return s1
            }
            
            return nil
        },

        ConversionPattern( [ .X([.spherical]) ] ) { s0, tagTo in
            
            var s1 = s0
            
            if tagTo == tagDeg {
                if s0.Xfmt.polarAngle != .degrees {
                    s1.Xfmt.polarAngle = .degrees
                    return s1
                }
                return nil
            }

            if tagTo == tagRad {
                if s0.Xfmt.polarAngle != .radians {
                    s1.Xfmt.polarAngle = .radians
                    return s1
                }
                return nil
            }
            
            // TODO: How do we convert to DMS ?

            if let seq = unitConvert( from: s0.Xt, to: tagTo ) {
                let (r, w, p) = s0.Xtv.getSpherical()
                s1.setSphericalValue( seq.op(r), w, p, tag: tagTo, fmt: s0.Xfmt )
                return s1
            }
            
            return nil
        },
    ])
}
