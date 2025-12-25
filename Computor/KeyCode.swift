//
//  KeyCode.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import Foundation

enum KeyCode: Int, Codable {
    
    // Special Keycodes
    case null = 0, clockTick, enter, backUndo, lib, unit
    
    // Entry mode keys, chs is also a function
    case dot = 10, chs, eex, d000
    
    // Arithmetic Ops
    case plus = 20, minus, times, divide
    
    // Clear functions
    case clearX = 30, clearY, clearZ, clearReg
    
    // Display Format
    case fixL = 40, fixR
    
    // Register Exchange and other ops
    case xy, xz, yz, lastx, roll
    
    // Percentage and Statistical Functions
    case percent = 50, deltaPercent, totalPercent, mean, minX, maxX, stdDev
    
    case y2x = 60, inv, x2, sqrt, abs, x3, root3
    
    // Trigonometric Functions
    case sin = 70, cos, tan, asin, acos, atan, atan2, csc, sec, cot, acsc, asec, acot, sinh, cosh, tanh, asinh, acosh, atanh
    
    // Integer Operations
    case floor = 90, ceiling, round, factorial, sign, intDivide, modulo, gcd, lcm, hcf
    
    // Logarithmic Functions
    case log = 100, ln, log2, logY
    
    // Exponential Functions
    case tenExp = 110, eExp, twoExp
    
    // Constants
    case pi2 = 120, pi3, pi4, pi6
    
    // Complex operations
    case zRe = 200, zIm, zArg, zConj, zNorm
    
    // Format
    case fix = 220, sci, eng
    
    // Softkeys - Top row F1..F6 and Unit row U1..U6
    case F0 = 260, F1, F2, F3, F4, F5, F6, U1, U2, U3, U4, U5, U6
    
    // Macro Op
    case macroOp = 280, clrFn, recFn, stopFn, editFn, braceKey, openBrace, closeBrace, macro
    
    // Multi valued types
    case multiValue = 290, rational, vector, polar, complex, vector3D, spherical
    
    // Matrix operations
    case matrix = 300, range, seq, mapX, mapXY, reduce, addRow, addCol, dotProduct, crossProduct, transpose, identity
    
    // Memory operations
    case noop = 320, rcl, stoX, stoY, stoZ, popX, popXY, popXYZ, mPlus, mMinus, mRename, rclMem, stoMem, noopBrace
    
    // Macro recorder operations
    case macroRecord = 340, macroStop, macroPlay, macroSlowPlay, macroStep, macroRename

    case unitStart = 400
    
    // Length
    case km = 401, mm, cm, metre, inch, ft, yd, mi, NM
    
    // Time
    case second = 410, min, hr, day, yr, ms, us
    
    // Angles
    case deg = 420, rad, dms, dm, minA
    
    // Mass
    case kg = 430, mg, gram, tonne, lb, oz, ton, stone
    
    // Capacity
    case mL = 440, liter, floz, cup, pint, quart, us_gal, gal
    
    // Temperature
    case degC = 450, degF
    
    case unitEnd = 499
    
    // *********
    // Sym chars: 26+26+24+10+12+26 = 124 chars - 3 digits
    
    case symbolCharNull = 500
         
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

    case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
    
    case alpha, beta, gamma, delta, epsilon, zeta, eta, theta, iota, kappa, lambda, mu, nu, xi, omicron, pi, rho, sigma, tau, upsilon, phi, chi, psi, omega
    
    case d0, d1, d2, d3, d4, d5, d6, d7, d8, d9
    
    case starSym, plusSym, primeSym, doublePrimeSym, fullStopSym, percentSym, hashSym
    case funcSym, deltaSym, nablaSym, sumSym, integralSym
    
    case scriptA, scriptB, scriptC, scriptD, scriptE, scriptF, scriptG, scriptH, scriptI, scriptJ, scriptK, scriptL, scriptM
    case scriptN, scriptO, scriptP, scriptQ, scriptR, scriptS, scriptT, scriptU, scriptV, scriptW, scriptX, scriptY, scriptZ
    
    case blankChar, modalChar
    
    case symbolCharEnd
    
    // *********
    
    case newMacro = 700
    
    case lastCode = 999
    
    var str: String {
        
        if self.isLowerAlpha {
            let ix = self.rawValue - KeyCode.a.rawValue
            return String( KeyCode.lowerAlpha[ix] )
        }
        if self.isUpperAlpha {
            let ix = self.rawValue - KeyCode.A.rawValue
            return String( KeyCode.upperAlpha[ix] )
        }
        if self.isGreekAlpha {
            let ix = self.rawValue - KeyCode.alpha.rawValue
            return String( KeyCode.greekAlpha[ix] )
        }
        if self.isDigit {
            return String( self.rawValue - KeyCode.d0.rawValue )
        }
        if self.isExtraSym {
            let ix = self.rawValue - KeyCode.starSym.rawValue
            return String( KeyCode.extraSym[ix])
        }
        if self.isScriptAlpha {
            let ix = self.rawValue - KeyCode.scriptA.rawValue
            return String( KeyCode.scriptAlpha[ix])
        }
        return String( describing: self )
    }

    // *********
    
    var isUnit: Bool { return self.rawValue > KeyCode.unitStart.rawValue && self.rawValue < KeyCode.unitEnd.rawValue }
    
    var isDigit: Bool
    { return self.rawValue >= KeyCode.d0.rawValue && self.rawValue <= KeyCode.d9.rawValue }

    var isLowerAlpha: Bool
    { return self.rawValue >= KeyCode.a.rawValue && self.rawValue <= KeyCode.z.rawValue }
    
    var isUpperAlpha: Bool
    { return self.rawValue >= KeyCode.A.rawValue && self.rawValue <= KeyCode.Z.rawValue }
    
    var isGreekAlpha: Bool
    { return self.rawValue >= KeyCode.alpha.rawValue && self.rawValue <= KeyCode.omega.rawValue }
    
    var isUnitKey: Bool
    { KeyCode.UnSet.contains(self) }

    var isFuncKey: Bool
    { KeyCode.fnSet.contains(self) || self.isUnitKey }
    
    var isExtraSym: Bool
    { return self.rawValue >= KeyCode.starSym.rawValue && self.rawValue <= KeyCode.integralSym.rawValue }
    
    var isScriptAlpha: Bool
    { return self.rawValue >= KeyCode.scriptA.rawValue && self.rawValue <= KeyCode.scriptZ.rawValue }
    
    
    // Set of keys that cause data entry mode to begin, digits and dot
    static let entryStartKeys = KeyCode.digitSet.union( Set<KeyCode>([.dot]) )
    
    // Set of keys valid in data entry mode, all of above plus sign, back and enter exp
    static let entryKeys =  entryStartKeys.union( Set<KeyCode>([.chs, .backUndo, .eex, .d000]) )

    static let digitSet:Set<KeyCode> = [.d0, .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9]

    static let fnSet:Set<KeyCode> = [.F1, .F2, .F3, .F4, .F5, .F6]

    static let UnSet:Set<KeyCode> = [.U1, .U2, .U3, .U4, .U5, .U6]
    
    static let extraSymSet:Set<KeyCode> = [
        starSym, plusSym, primeSym, doublePrimeSym, fullStopSym, percentSym,
        hashSym, funcSym, deltaSym, nablaSym, sumSym, integralSym
    ]

    static let macroOpSet:Set<KeyCode> = [.macroOp, .clrFn, .recFn, .stopFn, .editFn, .openBrace]

    static let lowerAlpha = Array( "abcdefghijklmnopqrstuvwxyz" )
    static let upperAlpha = Array( "ABCDEFGHIJKLMNOPQRSTUVWXYZ" )

    static let greekAlpha = [
        "\u{03b1}", "\u{03b2}", "\u{03b3}", "\u{03b4}", "\u{03b5}", "\u{03b6}", "\u{03b7}", "\u{03b8}",
        "\u{03b9}", "\u{03ba}", "\u{03bb}", "\u{03bc}", "\u{03bd}", "\u{03be}", "\u{03bf}", "\u{03c0}",
        "\u{03c1}", "\u{03c3}", "\u{03c4}", "\u{03c5}", "\u{03c6}", "\u{03c7}", "\u{03c8}", "\u{03c9}" ]
    
    static let extraSym = [
        "\u{002A}", // *
        "\u{002B}", // +
        "\u{0027}", // '
        "\u{0022}", // "
        "\u{002E}", // full stop
        "\u{0025}", // %
        "\u{0023}", // #
        "\u{0192}", // f with hook
        "\u{2206}", // delta
        "\u{2207}", // inverted delta
        "\u{2211}", // Sum
        "\u{222B}", // Integral
    ]
    
    static let scriptAlpha = [
        "\u{1D4D0}",  "\u{1D4D1}",  "\u{1D4D2}",  "\u{1D4D3}",  "\u{1D4D4}",  "\u{1D4D5}",
        "\u{1D4D6}",  "\u{1D4D7}",  "\u{1D4D8}",  "\u{1D4D9}",  "\u{1D4DA}",  "\u{1D4DB}",
        "\u{1D4DC}",  "\u{1D4DD}",  "\u{1D4DE}",  "\u{1D4DF}",  "\u{1D4E0}",  "\u{1D4E1}",
        "\u{1D4E2}",  "\u{1D4E3}",  "\u{1D4E4}",  "\u{1D4E5}",  "\u{1D4E6}",  "\u{1D4E7}",
        "\u{1D4E8}",  "\u{1D4E9}",
    ]
}

