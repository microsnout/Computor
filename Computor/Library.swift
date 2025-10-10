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

typealias LibFuncClosure = ( _ model: CalculatorModel, _ s0: CalcState ) -> (CalcState?, KeyPressResult)


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


// **************************
// Standard Library Functions
// **************************

var stdGroup = LibraryGroup(
    name: "Std",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.Q, .f] ),
            require: [ .X([.real]), .Y([.real]), .Z([.real])], where: { s0 in s0.Xt == s0.Yt && s0.Yt == s0.Zt && s0.Xt == tagUntyped },
            libQuadraticFormula(_:_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.T, .r] ),
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libTrapezoidalRule(_:_:)
        ),
    ])


func libQuadraticFormula( _ model: CalculatorModel, _ s0: CalcState) -> (CalcState?, KeyPressResult) {
    
    /// Solve quadratic function
    /// 0 = ax^2 + bx + c
    /// where X=a, Y=b, Z=c
    
    let (a, b, c) = (s0.X, s0.Y, s0.Z)
    
    var s1 = s0
    s1.stackDrop()
    s1.stackDrop()
    
    let rad = b*b - 4*a*c
    
    if rad == 0.0 {
        // One solution
        s1.setRealValue( -b / 2*a, fmt: s0.Xfmt )
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
    return (s1, KeyPressResult.stateChange)
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


func libTrapezoidalRule( _ model: CalculatorModel, _ s0: CalcState) -> (CalcState?, KeyPressResult) {
    
    // Create a Reduce function obj capturing the value list and mode reference
    let trapFn = TrapezoidalRuleContext( fromA: s0.Xtv, toB: s0.Ytv )
    
    model.pushContext( trapFn, lastEvent: KeyEvent(.lib) )

    return (nil, KeyPressResult.stateError)
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
