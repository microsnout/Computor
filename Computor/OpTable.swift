//
//  OpTable.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-18.
//
import SwiftUI
import Numerics
import OSLog


extension CalculatorModel {
    
    static var opTable: [KeyCode : StateOperator] = [
        .plus:  BinaryOpAdditive( + ),
        .minus: BinaryOpAdditive( - ),
        .times: BinaryOpMultiplicative( .times ),
        .divide: BinaryOpMultiplicative( .divide ),

        // Math function row 0
        .sin:   UnaryOp( parm: tagRad, result: tagUntyped, sin ),
        .cos:   UnaryOp( parm: tagRad, result: tagUntyped, cos ),
        .tan:   UnaryOp( parm: tagRad, result: tagUntyped, tan ),
        
        .asin:   UnaryOp( parm: tagUntyped, result: tagRad, asin ),
        .acos:   UnaryOp( parm: tagUntyped, result: tagRad, acos ),
        .atan:   UnaryOp( parm: tagUntyped, result: tagRad, atan ),
            
        .csc:   UnaryOp( parm: tagRad, result: tagUntyped, { 1.0/sin($0) } ),
        .sec:   UnaryOp( parm: tagRad, result: tagUntyped, { 1.0/cos($0) } ),
        .cot:   UnaryOp( parm: tagRad, result: tagUntyped, { 1.0/tan($0) } ),
        
        .acsc:   UnaryOp( parm: tagUntyped, result: tagRad, { asin(1.0/$0) } ),
        .asec:   UnaryOp( parm: tagUntyped, result: tagRad, { acos(1.0/$0) } ),
        .acot:   UnaryOp( parm: tagUntyped, result: tagRad, { atan(1.0/$0) } ),
                
        .sinh:   UnaryOp( parm: tagUntyped, result: tagUntyped, sinh ),
        .cosh:   UnaryOp( parm: tagUntyped, result: tagUntyped, cosh ),
        .tanh:   UnaryOp( parm: tagUntyped, result: tagUntyped, tanh ),
        
        .asinh:   UnaryOp( parm: tagUntyped, result: tagUntyped, asinh ),
        .acosh:   UnaryOp( parm: tagUntyped, result: tagUntyped, acosh ),
        .atanh:   UnaryOp( parm: tagUntyped, result: tagUntyped, atanh ),
                
        .log:   UnaryOp( result: tagUntyped, log10 ),
        .ln:    UnaryOp( result: tagUntyped, log ),
        .log2:  UnaryOp( result: tagUntyped, { x in log10(x)/log10(2) } ),
        
        .logY:  BinaryOpReal( { y, x in log10(x)/log10(y) } ),
        
        .tenExp: UnaryOp( parm: tagUntyped, result: tagUntyped, { x in pow(10.0, x) } ),
        .eExp: UnaryOp( parm: tagUntyped, result: tagUntyped, { x in exp(x) } ),

        .pi:    Constant( Double.pi ),
        .e:     Constant( exp(1.0) ),
        .abs:   UnaryOp( { x in abs(x) } ),
        .sign:  UnaryOp( { x in -x }),
        
        .sqrt:
            CustomOp { s0 in
                guard s0.Xtv.isReal else {
                    // Real values only
                    return nil
                }
                
                if s0.Xt == tagUntyped {
                    // Simple case, X is untyped value
                    var s1 = s0
                    s1.X = sqrt(s0.X)
                    return s1
                }
                
                if let tag = typeNthRoot(s0.Xt, n: 2) {
                    // Successful nth root of type tag
                    var s1 = s0
                    s1.Xtv = TaggedValue( tag: tag, reg: sqrt(s0.X), format: s0.Xfmt)
                    return s1
                }
                
                // Failed operation
                return nil
            },
        
        .y2x:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isReal && s0.Ytv.isReal else {
                    // Real values only
                    return nil
                }
                
                if s0.Xt != tagUntyped {
                    // Exponent must be untyped value
                    return nil
                }
                
                if s0.Yt == tagUntyped {
                    // Simple case, both operands untyped
                    var s1 = s0
                    s1.stackDrop()
                    s1.X = pow(s0.Y, s0.X)
                    return s1
                }
                
                if let exp = getInt(s0.X),
                   let tag = typeExponent( s0.Yt, x: exp )
                {
                    // Successful type exponentiation
                    var s1 = s0
                    s1.stackDrop()
                    s1.Xtv = TaggedValue( tag: tag, reg: pow(s0.Y, s0.X), format: s0.Yfmt)
                    return s1
                }
                
                // Failed operation
                return nil
            },
        
        .x2:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isReal else {
                    // Real values only
                    return nil
                }
                
                if let (tag, ratio) = typeProduct(s0.Xt, s0.Xt) {
                    var s1 = s0
                    s1.Xtv = TaggedValue(tag: tag, reg: s0.X * s0.X, format: s0.Xfmt)
                    return s1
                }
                return nil
            },
        
        .percent:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isReal && s0.Ytv.isReal else {
                    // Real values only
                    return nil
                }
                
                if s0.Xt == tagUntyped {
                    var s1 = s0
                    s1.Xtv = TaggedValue( tag: s0.Yt, reg: s0.X / 100.0 * s0.Y, format: s0.Yfmt)
                    return s1
                }
                return nil
            },
        
        .inv:
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isReal else {
                    // Real values only
                    return nil
                }
                
                if let (tag, ratio) = typeProduct(tagUntyped, s0.Xt, quotient: true) {
                    var s1 = s0
                    s1.Xtv = TaggedValue( tag: tag, reg: 1.0 / s0.X, format: s0.Xfmt)
                    return s1
                }
                return nil
            },
        
        .clX:
            // Clear X register
            CustomOp { (s0: CalcState) -> CalcState? in
                var s1 = s0
                s1.Xtv = untypedZero
                s1.noLift = true
                return s1
            },

        .clY:
            // Clear Y register
            CustomOp { s0 in
                var s1 = s0
                s1.Ytv = untypedZero
                return s1
            },

        .clZ:
            // Clear Z register
            CustomOp { s0 in
                var s1 = s0
                s1.Ztv = untypedZero
                return s1
            },

        .clReg:
            // Clear registers
            CustomOp { s0 in
                var s1 = s0
                
                for i in 0 ..< stackSize {
                    s1.stack[i].value = untypedZero
                }
                s1.noLift = true
                return s1
            },
        
        .roll:
            // Roll down register stack
            CustomOp { s0 in
                var s1 = s0
                s1.stackRoll()
                return s1
            },
        
        .xy:
            // XY exchange
            CustomOp { s0 in
                var s1 = s0
                s1.Ytv = s0.Xtv
                s1.Xtv = s0.Ytv
                return s1
            },
        
        .yz:
            // Y Z exchange
            CustomOp { s0 in
                var s1 = s0
                s1.Ytv = s0.Ztv
                s1.Ztv = s0.Ytv
                return s1
            },

        .xz:
            // X Z exchange
            CustomOp { s0 in
                var s1 = s0
                s1.Ztv = s0.Xtv
                s1.Xtv = s0.Ztv
                return s1
            },
        
        .rational:
            // Form rational value from x, y
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isInteger && s0.Ytv.isInteger else {
                    return nil
                }
                guard s0.Xt.isType(.untyped) && s0.Yt.isType(.untyped) && s0.Y != 0 else {
                    return nil
                }
                
                var s1 = s0
                var (num, den) = (s0.X, s0.Y)
                if den < 0 {
                    num = -num
                    den = -den
                }
                s1.stackDrop()
                s1.setShape(2)
                s1.set2( num, den )
                s1.Xvtp = .rational
                return s1
            },

        .complex:
            // Form complex value from x, y
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xtv.isReal && s0.Ytv.isReal else {
                    return nil
                }
                guard s0.Xt.isType(.untyped) && s0.Yt.isType(.untyped) else {
                    return nil
                }
                var s1 = s0
                s1.stackDrop()
                s1.setShape(2)
                s1.set2( s0.X, s0.Y )
                s1.Xvtp = .complex
                return s1
            },
        
        .deg: Convert( sym: "deg", fmt: FormatRec( style: .decimal) ),
        .rad: Convert( sym: "rad", fmt: FormatRec( style: .decimal) ),
        .dms: Convert( sym: "deg", fmt: FormatRec( style: .dms)),
        .dm:  Convert( sym: "deg", fmt: FormatRec( style: .dm)),
    ]

}
