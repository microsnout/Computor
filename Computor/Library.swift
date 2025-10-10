//
//  Functions.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-12.
//
import Foundation


func installFunctions( _ model: CalculatorModel ) {
    
    /// ** Install Fuctions **
    
    SystemLibrary.addGroup( stdGroup )
}


// ***********************
// Library Data Structures
// ***********************

typealias LibFuncClosure = ( _ model: CalculatorModel ) -> KeyPressResult


struct SystemLibrary {
    
    static var groups: [LibraryGroup] = []
    
    static func addGroup( _ group: LibraryGroup ) {
        
        // Allocate system module code
        group.modCode = Self.groups.count + SymbolTag.firstSysMod
        
        Self.groups.append(group)
    }
    
    
    static func getLibFunction( for tag: SymbolTag ) -> LibraryFunction? {
        
        assert( tag.isSysMod )
        
        let index = tag.mod - SymbolTag.firstSysMod
        let localTag = tag.localTag
        return Self.groups[index].functions.first( where: { $0.sym == localTag } )
    }
}


class LibraryGroup {
    
    var name: String
    var functions: [LibraryFunction]
    
    var modCode: Int = 0
    
    init( name: String, functions: [LibraryFunction] ) {
        self.name = name
        self.functions = functions
    }
}


class LibraryFunction {
    
    var sym: SymbolTag
    var regPattern: RegisterPattern = RegisterPattern()
    var libFunc: LibFuncClosure
    
    init( sym: SymbolTag, require pattern: [RegisterSpec], where test: StateTest? = nil, _ libFunc: @escaping LibFuncClosure ) {
        
        self.sym = sym
        self.regPattern = RegisterPattern(pattern, test)
        self.libFunc = libFunc
    }
}


typealias FunctionX = ( _ x: Double ) -> Double


class LibraryFunctionContext : ModalContext {
    
    var prompt: String
    
    var block: ( _ model: CalculatorModel, _ f: FunctionX ) -> KeyPressResult
    
    init( prompt: String, block: @escaping ( _ model: CalculatorModel, _ f: FunctionX ) -> KeyPressResult ) {
        self.prompt = prompt
        self.block = block
    }
    
    override var statusString: String? { self.prompt }
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        let f: FunctionX = { x in
            
            let tvX = TaggedValue( reg: x )
            model.enterValue(tvX)
            let _ = self.executeFn(event)
            let value = model.state.X
            model.state.stackDrop()
            return value
        }
        
        return self.block(model, f)
    }
}


extension CalculatorModel {
    
    func withModalFunc( prompt: String, block: @escaping ( _ model: CalculatorModel, _ f: FunctionX ) -> KeyPressResult ) -> KeyPressResult {
        
        let ctx = LibraryFunctionContext( prompt: prompt, block: block )
        
        self.pushContext(ctx)
        
        return KeyPressResult.modalFunction
    }
}


// **************************
// Standard Library Functions
// **************************

var stdGroup = LibraryGroup(
    name: "Std",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.Q, .f] ),
            require: [ .X([.real]), .Y([.real]), .Z([.real])], where: { s0 in s0.Xt == s0.Yt && s0.Yt == s0.Zt && s0.Xt == tagUntyped },
            libQuadraticFormula(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.T, .r] ),
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libTrapezoidalRule(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.T, .q] ),
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libTrapezoidalRule2(_:)
        ),
    ])


func libQuadraticFormula( _ model: CalculatorModel ) -> KeyPressResult {
    
    /// Solve quadratic function
    /// 0 = ax^2 + bx + c
    /// where X=a, Y=b, Z=c
    
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
    
    model.state = s1
    return KeyPressResult.stateChange
}


func trapzd( _ f: (Double) -> Double, _ a: Double, _ b: Double, n: Int = 1, s0: Double = 0.0 ) -> Double {
    
    /// ** trapzd **
    ///  from Numerical Recipes in C page 137
    
    if n == 1 {
        return (f(a) + f(b))*(b-a)/2
    }
    else {
        let it = 1 << (n-2)
        let tnm = Double(it)
        let delta = (b-a)/tnm
        
        var x = a + delta/2
        var sum = 0.0
        
        for _ in 1...it {
            sum += f(x)
            x += delta
        }
        return (s0 + (b-a) * sum/tnm) / 2
    }
}


func qtrap( _ f: (Double) -> Double, a: Double, b: Double, eps: Double = 1.0e-7, nmax: Int = 14 ) -> Double {
    
    /// ** qtrap **
    ///  from Numerical Recipes in C page 137

    var lasts = trapzd( f, a, b )
    
    for j in 2...nmax {
        
        let s = trapzd( f, a, b, n: j, s0: lasts)
        
        print( "qtrap: n=\(j)  lasts=\(lasts)  s=\(s)  s-lasts=\(abs(s-lasts))  eps: \(eps * abs(lasts))" )
        
        if ( abs(s-lasts) < eps * abs(lasts) ) {
            return s
        }
        
        lasts = s
    }
    
    return 0.0
}


func libTrapezoidalRule( _ model: CalculatorModel ) -> KeyPressResult {
    
    let s0 = model.state
    
    // Create a Reduce function obj capturing the value list and mode reference
    let trapFn = TrapezoidalRuleContext( fromA: s0.Xtv, toB: s0.Ytv )
    
    model.pushContext( trapFn, lastEvent: KeyEvent(.lib) )
    
    return KeyPressResult.modalFunction
}


func libTrapezoidalRule2( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Trapezoid Rule ƒ()" ) { model, f in
        
        let (a, b) = (model.state.X, model.state.Y)
        
        model.state.stackDrop()
        model.state.stackDrop()

        let result = qtrap( f, a: a, b: b)
        
        let resTv = TaggedValue( reg: result )
        
        model.enterValue(resTv)

        return KeyPressResult.stateChange
    }
}


class TrapezoidalRuleContext : ModalContext {
    
    let fromA:  TaggedValue
    let toB:  TaggedValue

    init( fromA: TaggedValue, toB: TaggedValue ) {
        self.fromA = fromA
        self.toB = toB
    }
    
    override var statusString: String? { "ç{UnitText}Trapezoid Rule ƒ()" }
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        let f: (Double) -> Double = { x in
            
            let xValue = TaggedValue( reg: x)
            model.enterValue(xValue)
            
            if self.executeFn( event ) == .stateChange {
                let fResult = model.state.X
                model.state.stackDrop()
                
                // print( "f(\(x)) = \(fResult)")
                return fResult
            }
            else {
                model.state.stackDrop()
                return 0.0
            }
        }
        
        // Remove parameter values from stack
        model.state.stackDrop()
        model.state.stackDrop()
        
        let result = qtrap( f, a: fromA.reg, b: toB.reg)
        
        let resTv = TaggedValue( reg: result )
        
        model.enterValue(resTv)
        return KeyPressResult.stateChange
    }
}
