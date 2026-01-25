//
//  StateOperator.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-18.
//
import SwiftUI
import OSLog


typealias OpPatternClosure = (CalcState) -> (KeyPressResult, CalcState?)


struct OpPattern : StateOperatorEx {
    
    let regPattern: RegisterPattern
    
    let block: OpPatternClosure
    
    init( _ pattern: [RegisterSpec], where test: StateTest? = nil, _ block: @escaping OpPatternClosure ) {
        self.regPattern = RegisterPattern(pattern, test)
        self.block = block
    }

    func transition(_ model: CalculatorModel, _ s0: CalcState ) -> (KeyPressResult, CalcState?) {
        return block(s0)
    }
}


struct ConversionPattern {
    let regPattern: RegisterPattern
    
    let block: (CalcState, TypeTag) -> CalcState?
    
    init( _ pattern: [RegisterSpec], where test: StateTest? = nil, _ block: @escaping (CalcState, TypeTag) -> CalcState? ) {
        self.regPattern = RegisterPattern(pattern, test)
        self.block = block
    }

    func convert(_ s0: CalcState, to toTag: TypeTag ) -> CalcState? {
        return block(s0, toTag)
    }
}


struct CustomOp: StateOperator {
    let block: (CalcState) -> CalcState?
    
    init(_ block: @escaping (CalcState) -> CalcState? ) {
        self.block = block
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        return block(s0)
    }
}


struct ConversionOp: StateOperator {
    let block: (TaggedValue) -> TaggedValue?
    
    init(_ block: @escaping (TaggedValue) -> TaggedValue? ) {
        self.block = block
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        guard s0.Xtv.isReal else {
            // Real values only for now
            return nil
        }
        
        var s1 = s0
        
        guard let newTV = block( s0.Xtv ) else {
            return nil
        }
        s1.Xtv = newTV
        return s1
    }
}


struct Convert: StateOperator {
    let toType: TypeTag
    let toFmt: FormatRec?
    
    init( to: TypeTag, fmt: FormatRec? = nil ) {
        self.toType = to
        self.toFmt = fmt
    }
    
    init( sym: String, fmt: FormatRec? = nil ) {
        self.toType = TypeDef.tagFromSym(sym) ?? tagUntyped
        self.toFmt = fmt
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        guard s0.Xtv.isReal else {
            // Real values only for now
            return nil
        }
        
        var s1 = s0

        if s1.convertX( toTag: toType) {
            if let fmt = toFmt {
                s1.Xfmt = fmt
            }
            else {
                s1.Xfmt = s0.Xfmt
            }
            return s1
        }
        else {
            return nil
        }
    }
}


struct Constant: StateOperator {
    let value: Double
    let tag: TypeTag

    init( _ value: Double, tag: TypeTag = tagUntyped ) {
        self.value = value
        self.tag = tag
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        var s1 = s0
        s1.stackLift()
        s1.setRealValue( reg: regX, self.value, tag: self.tag)
        return s1
    }
}


struct UnaryOp: StateOperator {
    let parmType: TypeTag?
    let resultType: TypeTag?
    let function: (Double) -> Double
    
    init( parm: TypeTag? = nil, result: TypeTag? = nil, _ function: @escaping (Double) -> Double ) {
        self.parmType = parm
        self.resultType = result
        self.function = function
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        guard s0.Xtv.isReal else {
            // Real values only
            return nil
        }
        var s1 = s0
        
        if let xType = self.parmType {
            // Check type of parameter
            if !s1.convertX( toTag: xType) {
                // Cannot convert to required type
                return nil
            }
        }
        s1.X = function( s1.X )
        
        if let rType = self.resultType {
            s1.Xt = rType
        }
        return s1
    }
}


struct BinaryOpReal: StateOperator {
    let function: (Double, Double) -> Double
    
    init(_ function: @escaping (Double, Double) -> Double ) {
        self.function = function
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        guard s0.Xtv.isReal && s0.Ytv.isReal else {
            // Real values only
            return nil
        }
        
        if s0.Yt.uid != uidUntyped || s0.Xt.uid != uidUntyped {
            // Cannot use typed values
            return nil
        }
        
        var s1 = s0
        s1.stackDrop()
        s1.X = function( s0.Y, s0.X )
        return s1
    }
}


struct BinaryOpAdditive: StateOperator {
    let function: (Double, Double) -> Double
    
    init(_ function: @escaping (Double, Double) -> Double ) {
        self.function = function
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        guard s0.Xtv.isReal && s0.Ytv.isReal else {
            // Real values only
            return nil
        }
        
        if let ratio = typeAddable( s0.Yt, s0.Xt) {
            // Operation is possible with scaling of X value
            var s1 = s0
            s1.stackDrop()
            s1.X = function( s0.Y, s0.X * ratio )
            return s1
        }
        else {
            // New state not possible
            return nil
        }
    }
}


struct BinaryOpMultiplicative: StateOperator {
    let kc: KeyCode
    
    init( _ key: KeyCode ) {
        self.kc = key
    }
    
    func _op( _ x: Double, _ y: Double ) -> Double {
        return kc == .times ? x*y : x/y
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        guard s0.Xtv.isReal && s0.Ytv.isReal else {
            // Real values only
            return nil
        }
        
        var s1 = s0
        s1.stackDrop()
        
        if let (tag, ratio) = typeProduct(s0.Yt, s0.Xt, quotient: kc == .divide )
        {
            // Successfully produced new type tag
            s1.X = _op(s0.Y, s0.X) * ratio
            s1.Xt = tag
        }
        else {
            // Cannot multiply these types
            return nil
        }
        
        return s1
    }
}
