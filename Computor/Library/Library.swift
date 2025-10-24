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
    SystemLibrary.addGroup( rootGroup )
    SystemLibrary.addGroup( integralGroup )
}


// ***********************
// Library Data Structures
// ***********************

typealias LibFuncClosure = ( _ model: CalculatorModel ) -> KeyPressResult


protocol TaggedItem {
    var symTag: SymbolTag { get }
    var caption: String? { get }
}


protocol TaggedItemGroup {
    var name: String { get }
    var itemList: [any TaggedItem] { get }
}


struct SystemLibrary {
    
    static var groups: [LibraryGroup] = []
    
    static func addGroup( _ group: LibraryGroup ) {
        
        // Allocate system module code
        Self.groups.append(group)
    }
    
    
    static func getLibFunction( for tag: SymbolTag ) -> LibraryFunction? {
        
        assert( tag.isSysMod )
        
        for grp in Self.groups {
            
            for fn in grp.functions {
                
                if tag == fn.symTag {
                    return fn
                }
            }
        }
        return nil
    }
    
    
    static func getSystemGroup( for tag: SymbolTag ) -> LibraryGroup? {
        
        assert( tag.isSysMod )
        
        for grp in Self.groups {
            
            for fn in grp.functions {
                
                if tag == fn.symTag {
                    return grp
                }
            }
        }
        return nil
    }
}


class LibraryGroup: TaggedItemGroup {
    
    var name: String
    var functions: [LibraryFunction]
    
    var itemList: [any TaggedItem] { self.functions }
    
    init( name: String, functions: [LibraryFunction] ) {
        self.name = name
        self.functions = functions
    }
}


class LibraryFunction: TaggedItem {
    
    var symTag: SymbolTag
    var caption: String? = nil
    var regPattern: RegisterPattern = RegisterPattern()
    var libFunc: LibFuncClosure
    
    init( sym localSym: SymbolTag, caption: String,  require pattern: [RegisterSpec], where test: StateTest? = nil, _ libFunc: @escaping LibFuncClosure ) {
        
        self.symTag = SymbolTag( localSym, mod: Const.LibMod.stdlib )
        self.caption = caption
        self.regPattern = RegisterPattern(pattern, test)
        self.libFunc = libFunc
    }
}


typealias FunctionX = ( _ x: Double ) -> Double


class LibraryFunctionContext : ModalContext {
    
    var prompt: String
    var regLabels: [String]?
    
    var block: ( _ model: CalculatorModel, _ f: FunctionX ) -> KeyPressResult
    
    init( prompt: String, regLabels labels: [String]? = nil, block: @escaping ( _ model: CalculatorModel, _ f: FunctionX ) -> KeyPressResult ) {
        self.prompt = prompt
        self.regLabels = labels
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

    override func onModelSet() {
        
        super.onModelSet()
        
        guard let model = self.model else { assert(false); return }
        
        if let labels = regLabels {
            model.status.setRegisterLabels(labels)
        }
    }
    
    override func onDeactivate( lastEvent: KeyEvent ) {
        
        super.onDeactivate(lastEvent: lastEvent)
        
        guard let model = self.model else { assert(false); return }
        
        model.status.clearRegisterLabels()
    }
}


extension CalculatorModel {
    
    func withModalFunc( prompt: String, regLabels labels: [String]? = nil, block: @escaping (_ model: CalculatorModel, _ f: FunctionX) -> KeyPressResult )-> KeyPressResult {
        
        /// ** With Modal Func **
        /// Delays execution of 'block' until the user enters a function, either single key or a {..} block
        /// Passes the entred function to the block
        
        let ctx = LibraryFunctionContext( prompt: prompt, regLabels: labels, block: block )
        
        self.pushContext(ctx)
        
        return KeyPressResult.modalFunction
    }
    
    
    func withModalConfirmation( prompt: String, regLabels labels: [String]? = nil, block: @escaping (_ model: CalculatorModel ) -> KeyPressResult ) -> KeyPressResult {
        
        /// ** With Modal Confirmation **
        /// Delays execution of the function block until confirmed by pressing Enter
        /// Does Nothing (no delay) if currently in recording or playback context
       
        let withinNormalContext: Bool = self.eventContext is NormalContext
        
        if self.modalConfirmation &&  withinNormalContext {
            
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
            sym: SymbolTag( [.scriptQ, .f], subPt: 2 ),
            caption: "Quadratic Formul",
            require: [ .X([.real]), .Y([.real]), .Z([.real])], where: { s0 in s0.Xt == s0.Yt && s0.Yt == s0.Zt && s0.Xt == tagUntyped },
            libQuadraticFormula(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.scriptP, .N], subPt: 2 ),
            caption: "Interpolation (Neville)",
            require: [ .X([.real]), .Y([.vector], .matrix) ],
            libPolyTerp(_:)
        ),
    ])

var rootGroup = LibraryGroup(
    name: "Root",
    functions: [

        LibraryFunction(
            sym: SymbolTag( [.scriptR, .B], subPt: 2 ),
            caption: "Bisection Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libBisection(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.scriptR, .S], subPt: 2 ),
            caption: "Secant Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libSecant(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.scriptR, .B, .r], subPt: 2 ),
            caption: "Brent Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
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
            libTrapezoidalRule(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.integralSym, .S], subPt: 2 ),
            caption: "Simpson's Rule",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libSimpsonsRule(_:)
        ),

        LibraryFunction(
            sym: SymbolTag( [.integralSym, .R], subPt: 2 ),
            caption: "Romberg Method",
            require: [ .X([.real]), .Y([.real]) ], where: { s0 in s0.Xt == s0.Yt },
            libRombergRule(_:)
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


func neville( _ points: [( x:Double, y:Double)], x: Double ) -> ( y: Double, dy: Double) {
    
    /// ** neville **
    /// Polynomial Interpolation using Neville's algorithm
    
    func P( _ a: Int, _ b: Int ) -> (Double, Double ) {
        
        if a == b {
            return (points[a].y, points[a].y)
        }
        let (pL, _) = P( a, b-1 )
        let (pU, _) = P( a+1, b )
        let (xa, xb) = (points[a].x, points[b].x)
        let y = ( (x - xa)*pU - (x - xb)*pL ) / (xb - xa)
        let dy = min( abs(y-pL), abs(y-pU) )
        return (y, dy)
    }
    
    let n = points.count
    let (y, dy) = P(0, n-1)
    return (y, dy)
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


func trapezoid( _ f: (Double) -> Double, a: Double, b: Double, eps: Double = 1.0e-7, nmax: Int = 14 ) -> Double {
    
    /// ** trapezoid **
    ///  Numerical Integration by Trapezoidal method

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


func simpson( _ f: (Double) -> Double, a: Double, b: Double, eps: Double = 1.0e-7, nmax: Int = 14 ) -> Double {
    
    /// ** simpson **
    ///  Numerical Integration by Simpson's method

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


func romberg( _ f: (Double) -> Double, a: Double, b: Double, eps: Double = 1.0e-7, nmax: Int = 14, k: Int = 5 ) -> Double {
    
    /// ** romberg **
    ///  Numerical Integration by Romberg's method
    
    var lastS = trapzd( f, a, b )
    
    var s: [( x: Double, y: Double)] = [(1.0, lastS)]
    
    for j in 2...nmax {
        
        let sj = trapzd( f, a, b, n: j, s0: lastS )
        
        s.append( ( 0.25 * s[s.count-1].x, sj ) )
        
        if ( j >= k ) {
            
            let (ss, dss) = neville( s, x: 0.0 )
            
            print( "romberg: n=\(j)  lasts=\(lastS)  s=\(sj)  dss=\(abs(dss))  eps*ss: \(eps * abs(ss))" )

            if abs(dss) < eps * abs(ss) {
                return ss
            }
            
            s.removeFirst()
        }
        else {
            print( "romberg: n=\(j)  lasts=\(lastS)  s=\(sj)  sj-lasts=\(abs(sj-lastS))  eps: \(eps * abs(lastS))" )
        }
        
        lastS = sj
    }
    return 0.0
}


func bisection( _ f: (Double) -> Double, x1: Double, x2: Double, acc: Double ) -> Double? {
    
    /// ** bisection **
    /// Bisection root finder
    
    let nmax = 100
    
    var (a, b) = (x1, x2)
    
    var (fa, fb) = (f(a), f(b))
    
    if ( fa * fb > 0.0 ) { return nil }
    
    if ( fa == 0.0 ) { return fa }
    if ( fb == 0.0 ) { return fb }
    
    if fa > 0 {
        (fa, fb) = (fb, fa)
        (a, b) = (b, a)
    }

    for n in 1...nmax {
        
        let mx = (a + b)/2
        
        print( "Bisection n=\(n) a=\(a) b=\(b) abs(b-a)=\(abs(b-a)) acc=\(acc)" )

        if abs(b-a) < acc { return mx }
        
        let fmx = f(mx)
        
        if fmx ==  0.0 { return mx }
        
        if fmx < 0 {
            (a, fa) = (mx, fmx)
        }
        else {
            (b, fb) = (mx, fmx)
        }
    }
    return nil
}


func secant( _ f: (Double) -> Double, x1: Double, x2: Double, acc: Double ) -> Double? {
    
    /// ** secant **
    /// Root finder - secant method, actually false postion
    
    let nmax = 100
    
    var (a, b) = (x1, x2)
    
    var (fa, fb) = (f(a), f(b))
    
    if ( fa * fb > 0.0 ) { return nil }
    
    if ( fa == 0.0 ) { return fa }
    if ( fb == 0.0 ) { return fb }
    
    if fa > 0 {
        (fa, fb) = (fb, fa)
        (a, b) = (b, a)
    }
    
    var lastdx = abs(a-b)
    
    for n in 1...nmax {
        
        print( "Bisection n=\(n) a=\(a) b=\(b) abs(fa-fb)=\(abs(b-a)) acc=\(acc)" )
        
        let mx = b - fb * (b - a)/(fb - fa)
        
        let fmx = f(mx)
        
        if fmx ==  0.0 { return mx }
        
        if fmx < 0 {
            (a, fa) = (mx, fmx)
        }
        else {
            (b, fb) = (mx, fmx)
        }
        
        let dx = abs(a-b)
        
        if dx < acc || dx == lastdx { return mx }
        
        lastdx = dx
    }
    return nil
}


func brent( _ f: (Double) -> Double, x1: Double, x2: Double, tol: Double ) -> Double? {
    
    /// ** brent **
    /// Root finder - Brent's method
    
    let nmax = 100
    
    let eps = 3.0e-8
    
    var (a, b)   = (x1, x2)
    var (fa, fb) = (f(a), f(b))
    
    if ( fa * fb > 0.0 ) { return nil }
    
    if ( fa == 0.0 ) { return fa }
    
    var (c, fc) = (b, fb)
    var d = b - c
    var e = d

    for n in 1...nmax {
        
        if fb*fc > 0 {
            c = a; fc = fa; d = b-a; e = d
        }

        if abs(fc) < abs(fb) {
            a = b; b = c; c = a; fa = fb; fb = fc; fc = fa
        }
        
        let tol1 = 2.0 * eps * abs(b) + 0.5*tol
        
        let m = (c - b) * 0.5
        
        print( "Bisection n=\(n) a=\(a) b=\(b) c=\(c) abs(m)=\(abs(m)) tol1=\(tol1)" )

        if abs(m) <= tol1 || fb == 0.0 { return b }
        
        if abs(e) >= tol1 && abs(fa) > abs(fb) {
            
            let s = fb/fa
            
            var p: Double
            var q: Double
            
            if a == c {
                p = 2.0 * m * s
                q = 1.0 - s
                
                print( "Brent - Secant" )
            }
            else {
                let r = fb/fc
                q = fa/fc
                p = s * (2.0 * m * q * (q - r) - (b - a) * (r - 1.0))
                q = (q - 1.0) * (r - 1.0) * (s - 1.0)
                
                print( "Brent - IQI" )
            }
            
            if p > 0.0 { q = -q }
            p = abs(p)
            
            let min1 = 3.0*m*q - abs(tol1*q)
            let min2 = abs(e*q)
            
            if 2*p < min(min1, min2) {
                e = d; d = p/q
            }
            else {
                d = m; e = d
            }
        }
        else {
            // Bisection
            d = m; e = d
            print( "Brent - Bisection" )
        }
        
        (a, fa) = (b, fb)
        
        if abs(d) > tol1 {
            b += d
        }
        else {
            b += (m > 0.0 ? abs(tol1) : -abs(tol1))
        }
        
        fb = f(b)
    }
    return nil
}


func libBisection( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Root (Bisection):  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        if let root = bisection(f, x1: a, x2: b, acc: 10e-8 ) {
            
            model.enterRealValue(root)
        }
        return KeyPressResult.stateError
    }
}


func libSecant( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Root (Secant):  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        if let root = secant(f, x1: a, x2: b, acc: 10e-8 ) {
            
            model.enterRealValue(root)
        }
        return KeyPressResult.stateError
    }
}


func libBrent( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Root (Brent):  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        if let root = brent(f, x1: a, x2: b, tol: 1e-10 ) {
            
            model.enterRealValue(root)
        }
        return KeyPressResult.stateError
    }
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
        
        let (result, _) = neville(pts, x: xValue )
        
        model.enterRealValue(result)
        return KeyPressResult.stateChange
    }
}


func libTrapezoidalRule( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Trapezoid Rule:  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = trapezoid( f, a: a, b: b)
        
        model.enterRealValue(result)
        
        return KeyPressResult.stateChange
    }
}


func libSimpsonsRule( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Simpsons Rule:  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = simpson( f, a: a, b: b)
        
        model.enterRealValue(result)
        
        return KeyPressResult.stateChange
    }
}


func libRombergRule( _ model: CalculatorModel ) -> KeyPressResult {
    
    return model.withModalFunc( prompt: "ç{UnitText}Romberg Rule:  ƒ()", regLabels: ["x-lower", "x-upper"] ) { model, f in
        
        let (a, b) = model.state.popRealXY()
        
        let result = romberg( f, a: a, b: b)
        
        model.enterRealValue(result)
        
        return KeyPressResult.stateChange
    }
}
