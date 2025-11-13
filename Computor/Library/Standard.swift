//
//  Standard.swift
//  Computor
//
//  Created by Barry Hall on 2025-11-04.
//
import Foundation


// **************************
// Standard Library Functions
// **************************


var flowGroup = LibraryGroup(
    name: "Control Flow",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.L, .o, .o, .p, .G, .T] ),
            caption: "Loop while Greater Than",
            require: [ .X([.real]) ], where: { isInt($0.X) && $0.X > 0 },
            modals: 1,
            libLoopGT(_:)
        ),
    ])

var stdGroup = LibraryGroup(
    name: "Interpolation",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.scriptP, .N], subPt: 2 ),
            caption: "Interpolation (Neville's Algorithm)",
            require: [ .X([.real]), .Y([.vector], .matrix) ],
            libPolyTerp(_:)
        ),
    ])

var rootGroup = LibraryGroup(
    name: "Root Finding",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.scriptQ, .f], subPt: 2 ),
            caption: "Quadratic Formula",
            require: [ .X([.real]), .Y([.real]), .Z([.real])], where: { s0 in s0.Xt == s0.Yt && s0.Yt == s0.Zt && s0.Xt == tagUntyped },
            libQuadraticFormula(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.scriptR, .B], subPt: 2 ),
            caption: "Bisection Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            modals: 1,
            libBisection(_:)
        ),
        
        LibraryFunction(
            sym: SymbolTag( [.scriptR, .S], subPt: 2 ),
            caption: "Secant Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            modals: 1,
            libSecant(_:)
        ),
        
        LibraryFunction(
            sym: SymbolTag( [.scriptR, .B, .r], subPt: 2 ),
            caption: "Brent Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            modals: 1,
            libBrent(_:)
        ),
    ])

var integralGroup = LibraryGroup(
    name: "Integration",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.integralSym, .T], subPt: 2 ),
            caption: "Trapezoid Rule",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            modals: 1,
            libTrapezoidalRule(_:)
        ),
        
        LibraryFunction(
            sym: SymbolTag( [.integralSym, .S], subPt: 2 ),
            caption: "Simpson's Rule",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            modals: 1,
            libSimpsonsRule(_:)
        ),
        
        LibraryFunction(
            sym: SymbolTag( [.integralSym, .R], subPt: 2 ),
            caption: "Romberg Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            modals: 1,
            libRombergRule(_:)
        ),
    ])


func libLoopGT( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalProc( prompt: "ç{UnitText}Loop while x>0 :  ƒ()", regLabels: ["N max"] ) { model, proc in
        
        var nMax = Int(model.state.X)
        
        assert( nMax > 0 )
        
        model.state.stackDrop()
        
        var test = 0.0
        
        repeat {
            test = proc()
            nMax -= 1
        }
        while test > 0.0 && nMax > 0
                
        let s1 = model.state
        
        return (KeyPressResult.stateChange, s1)
    }
}


func libQuadraticFormula( _ model: CalculatorModel ) -> OpResult {
    
    /// ** Quadratic Function **
    /// ax^2 + bx + c
    /// where X=a, Y=b, Z=c
    
    return model.withModalConfirmation(prompt: "Solve Ax^{2}+Bx+C: ƒ{0.8}Enter|Undo", regLabels: ["A", "B", "C"] ) { model in
        
        var s1 = model.state
        
        let (a, b, c) = (s1.X, s1.Y, s1.Z)
        
        s1.stackDrop()
        s1.stackDrop()
        
        let rad = b*b - 4*a*c
        
        if rad == 0.0 {
            // One solution
            s1.setRealValue( -b / 2*a, fmt: model.state.Xfmt )
        }
        else if rad > 0.0 {
            // Two real solutions
            s1.setShape( cols: 2 )
            s1.stack[regX].set1( (-b + sqrt(rad))/2*a, c: 1 )
            s1.stack[regX].set1( (-b - sqrt(rad))/2*a, c: 2 )
        }
        else {
            // Return 2 complex values
            s1.stack[regX].setMatrix( .complex, cols: 2 )
            let re = -b/2*a
            let im = sqrt(-rad)/2*a
            s1.stack[regX].set2( re, im, c: 1 )
            s1.stack[regX].set2( re, -im, c: 2 )
        }
        
        return (KeyPressResult.stateChange, s1)
    }
}


func libBisection( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Root (Bisection):  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        if let root = bisection(f, x1: a, x2: b, acc: 10e-8 ) {
            
            var s1 = model.state
            s1.pushRealValue(root)
            return (KeyPressResult.stateChange, s1)
        }
        return (KeyPressResult.stateError, nil)
    }
}


func libSecant( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Root (Secant):  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        if let root = secant(f, x1: a, x2: b, acc: 10e-8 ) {
            
            var s1 = model.state
            s1.pushRealValue(root)
            return (KeyPressResult.stateChange, s1)
        }
        return (KeyPressResult.stateError, nil)
    }
}


func libBrent( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Root (Brent):  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        if let root = brent(f, x1: a, x2: b, tol: 1e-10 ) {
            
            var s1 = model.state
            s1.pushRealValue(root)
            return (KeyPressResult.stateChange, s1)
        }
        return (KeyPressResult.stateError, nil)
    }
}


func libPolyTerp( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalConfirmation(prompt: "Interpolate Polynomial: ƒ{0.8}Enter|Undo", regLabels: ["x-value", "points"] ) { model in
        
        let xValue = model.state.popRealX()
        let tvPoints = model.state.popValueX()
        
        let n = tvPoints.cols
        var pts: [(x: Double, y: Double)] = []
        
        for i in 1...n {
            let (xValue, yVaue) = tvPoints.getVector( c: i )
            pts.append( (x: xValue, y: yVaue) )
        }
        
        let (result, _) = neville(pts, x: xValue )
        
        var s1 = model.state
        s1.pushRealValue(result)
        return (KeyPressResult.stateChange, s1)
    }
}


func libTrapezoidalRule( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Trapezoid Rule:  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = trapezoid( f, a: a, b: b)
        
        var s1 = model.state
        s1.pushRealValue(result)
        return (KeyPressResult.stateChange, s1)
    }
}


func libSimpsonsRule( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Simpsons Rule:  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = simpson( f, a: a, b: b)
        
        var s1 = model.state
        s1.pushRealValue(result)
        return (KeyPressResult.stateChange, s1)
    }
}


func libRombergRule( _ model: CalculatorModel ) -> OpResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Romberg Rule:  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = romberg( f, a: a, b: b)
        
        var s1 = model.state
        s1.pushRealValue(result)
        return (KeyPressResult.stateChange, s1)
    }
}
