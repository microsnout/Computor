//
//  KeyCode.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import Foundation

enum KeyCode: Int, Codable {
    case key0 = 0, key1, key2, key3, key4, key5, key6, key7, key8, key9
    
    case plus = 10, minus, times, divide
    
    case dot = 20, enter, clX, clY, clZ, clReg, back, sign, eex
    
    case fixL = 30, fixR, roll, xy, xz, yz, lastx, percent
    
    case y2x = 40, inv, x2, sqrt, abs
    
    case sin = 50, cos, tan, asin, acos, atan, csc, sec, cot, acsc, asec, acot, sinh, cosh, tanh, asinh, acosh, atanh
    
    case log = 80, ln, log2, logY
    
    case tenExp = 90, eExp, exp, quad
    
    // Complex operations
    case zRe = 100, zIm, zArg, zConj, zNorm
    
    // Format
    case fix = 120, sci, eng
    
    case null = 150, noop, rcl, sto, mPlus, mMinus, mRename
    
    // Softkeys
    case fn0 = 160, fn1, fn2, fn3, fn4, fn5, fn6
    
    // Macro Op
    case macroOp = 170, clrFn, recFn, stopFn, showFn, openBrace, closeBrace, macro
    
    // Multi valued types
    case multiValue = 180, rational, vector, polar, complex, vector3D, spherical
    
    // Matrix operations
    case matrix = 190, range, seq, map, reduce, dotProduct, crossProduct
    
    case unitStart = 200
    
    // Length
    case km = 201, mm, cm, metre, inch, ft, yd, mi
    
    // Time
    case second = 210, min, hr, day, yr, ms, us
    
    // Angles
    case deg = 220, rad, dms, dm, minA
    
    // Mass
    case kg = 230, mg, gram, tonne, lb, oz, ton, stone
    
    // Capacity
    case mL = 240, liter, floz, cup, pint, quart, us_gal, gal
    
    // Temperature
    case degC = 250, degF
    
    case unitEnd = 299
    
    case letter = 300, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
    
    case greek  = 350, alpha, beta, gamma, delta, epsilon, zeta, eta, theta, iota, kappa, lambda, mu, nu, xi, omicron, pi, rho, sigma, tau, upsilon, phi, chi, psi, omega
    
    var isUnit: Bool { return self.rawValue > KeyCode.unitStart.rawValue && self.rawValue < KeyCode.unitEnd.rawValue }
    
    static let digitSet:Set<KeyCode> = [.key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9]

    static let fnSet:Set<KeyCode> = [.fn1, .fn2, .fn3, .fn4, .fn5, .fn6, .openBrace]

    static let macroOpSet:Set<KeyCode> = [.macroOp, .clrFn, .recFn, .stopFn, .showFn, .openBrace]
}

