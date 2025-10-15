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
    SystemLibrary.addGroup( integralGroup )
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
    
    
    static func getSystemGroup( for tag: SymbolTag ) -> LibraryGroup {
        
        assert( tag.isSysMod )

        let index = tag.mod - SymbolTag.firstSysMod
        return Self.groups[index]
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
    
    func withModalFunc( prompt: String, block: @escaping (_ model: CalculatorModel, _ f: FunctionX) -> KeyPressResult )-> KeyPressResult {
        
        /// ** With Modal Func **
        /// Delays execution of 'block' until the user enters a function, either single key or a {..} block
        /// Passes the entred function to the block
        
        let ctx = LibraryFunctionContext( prompt: prompt, block: block )
        
        self.pushContext(ctx)
        
        return KeyPressResult.modalFunction
    }
    
    
    func withModalConfirmation( prompt: String, regLabels labels: [String]? = nil, block: @escaping (_ model: CalculatorModel ) -> KeyPressResult ) -> KeyPressResult {
        
        /// ** With Modal Confirmation **
        /// Delays execution of the function block until confirmed by pressing Enter
        /// Does Nothing (no delay) if currently in recording or playback context
        
        let withinNormalContext: Bool = self.eventContext is NormalContext
        
        if withinNormalContext {
            
            // Return confirmation context to handle Enter to confirm execution
            let ctx = ModalConfirmationContext( prompt: prompt, regLabels: labels, block: block )
            self.pushContext(ctx)
            return KeyPressResult.modalFunction
        }
        else {
            // Execute block immediately if recording or playback
            return block( self )
        }

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
            sym: SymbolTag( [.P, .t] ),
            require: [ .X([.real]), .Y([.vector], .matrix) ],
            libPolyTerp(_:)
        ),
    ])

var integralGroup = LibraryGroup(
    name: "Integration",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.integralSym, .T], subPt: 2 ),
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libTrapezoidalRule(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.integralSym, .S], subPt: 2 ),
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libSimpsonsRule(_:)
        ),
    ])


func libQuadraticFormula( _ model: CalculatorModel ) -> KeyPressResult {
    
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
        
        model.state = s1
        return KeyPressResult.stateChange
    }
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


func qsimp( _ f: (Double) -> Double, a: Double, b: Double, eps: Double = 1.0e-7, nmax: Int = 14 ) -> Double {
    
    /// ** qsimp **
    ///  from Numerical Recipes in C page 139

    var ost = trapzd( f, a, b )
    var os  = ost
    
    for j in 2...nmax {
        
        let st = trapzd( f, a, b, n: j, s0: ost )
        let s  = (4.0*st - ost)/3.0
        
        print( "qsimp: n=\(j)  os=\(os)  s=\(s)  s-os=\(abs(s-os))  eps: \(eps * abs(os))" )
        
        if ( abs(s-os) < eps * abs(os) ) {
            return s
        }
        
        ost = st
        os  = s
    }
    
    return 0.0
    
}


func polyTerp( _ points: [( x:Double, y:Double)], x: Double ) -> Double {
    
    func P( _ a: Int, _ b: Int ) -> Double {
        
        if a == b {
            return points[a].y
        }
        let pL = P( a, b-1 )
        let pU = P( a+1, b )
        let (xa, xb) = (points[a].x, points[b].x)
        return ( (x - xa)*pU - (x - xb)*pL ) / (xb - xa)
    }
    
    let n = points.count
    return P(0, n-1)
}


func libPolyTerp( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalConfirmation(prompt: "Interpolate Polynomial: ƒ{0.8}Enter|Undo", regLabels: ["x-value", "points"] ) { model in
        
        let xValue = model.state.popRealX()
        let tvPoints = model.state.popValueX()
        
        let n = tvPoints.cols
        var pts: [(x: Double, y: Double)] = []
        
        for i in 1...n {
            let (xValue, yVaue) = tvPoints.getVector( c: i )
            pts.append( (x: xValue, y: yVaue) )
        }
        
        let result = polyTerp(pts, x: xValue )
        
        model.enterRealValue(result)
        return KeyPressResult.stateChange
    }
}


func libTrapezoidalRule( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Trapezoid Rule ƒ()" ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = qtrap( f, a: a, b: b)
        
        model.enterRealValue(result)
        
        return KeyPressResult.stateChange
    }
}


func libSimpsonsRule( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Simpsons Rule ƒ()" ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = qsimp( f, a: a, b: b)
        
        model.enterRealValue(result)
        
        return KeyPressResult.stateChange
    }
}
