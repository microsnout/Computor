//
//  Numerical.swift
//  Computor
//
//  Created by Barry Hall on 2025-11-04.
//
import Foundation


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

