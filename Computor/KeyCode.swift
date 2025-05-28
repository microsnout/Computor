//
//  KeyCode.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import Foundation

enum KeyCode: Int, Codable {
    case null = 0
    
    case key0 = 1, key1, key2, key3, key4, key5, key6, key7, key8, key9
    
    case plus = 15, minus, times, divide
    
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
    
    // Softkeys
    case fn0 = 160, fn1, fn2, fn3, fn4, fn5, fn6
    
    // Macro Op
    case macroOp = 170, clrFn, recFn, stopFn, showFn, braceKey, openBrace, closeBrace, macro
    
    // Multi valued types
    case multiValue = 180, rational, vector, polar, complex, vector3D, spherical
    
    // Matrix operations
    case matrix = 190, range, seq, mapX, mapXY, reduce, addRow, addCol, dotProduct, crossProduct, transpose, identity
    
    // Memory operations
    case noop = 210, rcl, stoX, stoY, stoZ, popX, popXY, popXYZ, mPlus, mMinus, mRename, rclMem, stoMem

    case unitStart = 300
    
    // Length
    case km = 301, mm, cm, metre, inch, ft, yd, mi
    
    // Time
    case second = 310, min, hr, day, yr, ms, us
    
    // Angles
    case deg = 320, rad, dms, dm, minA
    
    // Mass
    case kg = 330, mg, gram, tonne, lb, oz, ton, stone
    
    // Capacity
    case mL = 340, liter, floz, cup, pint, quart, us_gal, gal
    
    // Temperature
    case degC = 350, degF
    
    case unitEnd = 399
    
    case letterL = 400, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

    case letterU = 450, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
    
    case greek  = 500, alpha, beta, gamma, delta, epsilon, zeta, eta, theta, iota, kappa, lambda, mu, nu, xi, omicron, pi, rho, sigma, tau, upsilon, phi, chi, psi, omega
    
    case lastCode = 999
    
    // *********
    
    var isUnit: Bool { return self.rawValue > KeyCode.unitStart.rawValue && self.rawValue < KeyCode.unitEnd.rawValue }
    
    var isDigit: Bool
    { return self.rawValue >= KeyCode.key0.rawValue && self.rawValue <= KeyCode.key9.rawValue }

    var isLowerAlpha: Bool
    { return self.rawValue >= KeyCode.a.rawValue && self.rawValue <= KeyCode.z.rawValue }
    
    var isUpperAlpha: Bool
    { return self.rawValue >= KeyCode.A.rawValue && self.rawValue <= KeyCode.Z.rawValue }
    
    var isGreekAlpha: Bool
    { return self.rawValue >= KeyCode.alpha.rawValue && self.rawValue <= KeyCode.omega.rawValue }

    static let digitSet:Set<KeyCode> = [.key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9]

    static let fnSet:Set<KeyCode> = [.fn1, .fn2, .fn3, .fn4, .fn5, .fn6, .openBrace]

    static let macroOpSet:Set<KeyCode> = [.macroOp, .clrFn, .recFn, .stopFn, .showFn, .openBrace]

    static let lowerAlpha = Array( "abcdefghijklmnopqrstuvwxyz" )
    static let upperAlpha = Array( "ABCDEFGHIJKLMNOPQRSTUVWXYZ" )

    static let greekAlpha = [
        "\u{03b1}", "\u{03b2}", "\u{03b3}", "\u{03b4}", "\u{03b5}", "\u{03b6}", "\u{03b7}", "\u{03b8}",
        "\u{03b9}", "\u{03ba}", "\u{03bb}", "\u{03bc}", "\u{03bd}", "\u{03be}", "\u{03bf}", "\u{03c0}",
        "\u{03c1}", "\u{03c3}", "\u{03c4}", "\u{03c5}", "\u{03c6}", "\u{03c7}", "\u{03c8}", "\u{03c9}" ]
}

