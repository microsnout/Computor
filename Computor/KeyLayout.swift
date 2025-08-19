//
//  KeyLayout.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-02.
//
import SwiftUI


// ***************************************************
// Keypad Definitions

let ksNormal = KeySpec( width: 42, height: 35,
                        keyColor: "KeyColor", textColor: "KeyText")

let ksSoftkey = KeySpec( width: 42, height: 25,
                         keyColor: "KeyColor", textColor: "KeyText")

let ksSubFn = KeySpec( width: 48, height: 30,
                       keyColor: "PopBack", textColor: "PopText")

let ksSubpad = KeySpec( width: 42, height: 30,
                        keyColor: "PopBack", textColor: "PopText")

let ksUnits = KeySpec( width: 60, height: 25,
                       keyColor: "KeyColor", textColor: "KeyText")

let ksModalPop = KeySpec( width: 30, height: 30,
                          keyColor: "ModalKeyColor", textColor: "ModalKeyText")

let psUnits = PadSpec (
    keySpec: ksUnits,
    cols: 5,
    keys: [ Key(.noop, "Angle"),
            Key(.noop, "Volume"),
            Key(.noop, "Length"),
            Key(.noop, "Speed"),
            Key(.noop, "User")
          ]
)

let psNumeric = PadSpec(
    keySpec: ksNormal,
    cols: 3,
    keys: [ Key(.d7, "ƒ{1.2}7"), Key(.d8, "ƒ{1.2}8"), Key(.d9, "ƒ{1.2}9"),
            Key(.d4, "ƒ{1.2}4"), Key(.d5, "ƒ{1.2}5"), Key(.d6, "ƒ{1.2}6"),
            Key(.d1, "ƒ{1.2}1"), Key(.d2, "ƒ{1.2}2"), Key(.d3, "ƒ{1.2}3"),
            Key(.d0, "ƒ{1.2}0"), Key(.dot, "ƒ{1.2}."),  Key(.sign, "ƒ{1.2}+/-")
          ]
)

let psEnter = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.enter, "Enter", size: 2), Key(.eex, "EE") ]
    )

let psOperations = PadSpec(
    keySpec: ksNormal,
    cols: 3,
    keys: [ Key(.divide, "ƒ{1.4}÷"),  Key(.deg, "ƒ{0.9}deg\u{00B0}"), Key(.y2x, "y^{x}"),
            Key(.times,  "ƒ{1.4}×"),  Key(.percent, "%"),             Key(.inv, "1/x"),
            Key(.minus,  "ƒ{1.4}−"),  Key(.xy, "ƒ{0.9}X\u{21c6}Y"),   Key(.x2, "x^{2}"),
            Key(.plus,   "ƒ{1.4}+"),  Key(.roll, "R\u{2193}"),        Key(.sqrt, "\u{221a}x")
          ])

let psClear = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.back, "ƒ{0.8}BACK/UNDO", size: 2), Key(.clX, "ƒ{0.8}ClrX") ]
    )

let psSoftkeyL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.F1),
            Key(.F2),
            Key(.F3)
          ]
)

let psSoftkeyR = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.F4),
            Key(.F5),
            Key(.F6)
          ]
)

let psUnitsL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.mL, "mL"),
            Key(.lb, "lb"),
            Key(.kg, "kg")
          ]
)

let psUnitsR = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.hr,  "hr"),
            Key(.mi,  "mi"),
            Key(.km,  "km")
          ]
)

let psFunctionsL = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan"),
            ]
    )

let psFunctionsR = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.log, "log"),
                Key(.tenExp, "10^{x}"),
                Key(.pi,  "ƒ{1.3}\u{1d70b}")
            ]
    )

let psFunctions2L = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.lib,   "Lib"),
                Key(.stoX,  "ƒ{0.9}Sto"),
                Key(.rcl,  "ƒ{0.9}Rcl"),
            ]
    )

// ***

let psFunctions2R = PadSpec(
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.zRe, "ƒ{0.8}Re( )"),
            Key(.seq, "ƒ{0.8}Seq"),
            Key(.noop, "ç{GrayText}{ }"),
          ]
)

let psFunctions2Ro = PadSpec(
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.zRe, "ƒ{0.8}Re( )"),
            Key(.seq, "ƒ{0.8}Seq"),
            Key(.openBrace, "{"),
          ]
)

let psFunctions2Rc = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.zRe, "ƒ{0.8}Re( )"),
                Key(.seq, "ƒ{0.8}Seq"),
                Key(.closeBrace, "}"),
            ]
    )

// ***

let psFormatL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.fix, "fix"),
            Key(.sci, "sci"),
            Key(.multiValue, "\u{27e8}..\u{27e9}"),
        ],
    fontSize: 14.0
)

let psFormatR = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.matrix, "ƒ{0.8}={[ ]}"),
            Key(.fixL, "ƒ{0.8}.00\u{2190}"),
            Key(.fixR, "ƒ{0.8}.00\u{2192}"),
        ],
    fontSize: 14.0
)

func initKeyLayout() {
    SubPadSpec.define( .F0,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.clrFn, "Clear"),
                        Key(.recFn, "Rec"),
                        Key(.stopFn, "Stop"),
                        Key(.editFn, "Edit"),
                       ]
    )
    
    SubPadSpec.copySpec(from: .F0, list: [.F1, .F2, .F3, .F4, .F5, .F6])
    
    SubPadSpec.define( .sin,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.csc, "csc",    caption: "cosecant" ),
                        Key(.acsc, "acsc",  caption: "Inverse csc"),
                        Key(.asin, "asin",  caption: "Inverse sin" ),
                        Key(.sinh, "sinh",  caption: "Hyperbolic sin" ),
                        Key(.asinh, "asinh",caption: "Inverse sinh" ),
                       ],
                       caption: "Sin functions"
    )
    
    SubPadSpec.define( .cos,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.sec, "sec",    caption: "secant"),
                        Key(.asec, "asec",  caption: "Inverse secant"),
                        Key(.acos, "acos",  caption: "Inverse cos"),
                        Key(.cosh, "cosh",  caption: "Hyperbolic cos"),
                        Key(.acosh, "acosh",caption: "Inverse cosh"),
                       ],
                       caption: "Cos functions"
    )
    
    SubPadSpec.define( .tan,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.cot, "cot",    caption: "cotangent"),
                        Key(.acot, "acot",  caption: "Inverse cot"),
                        Key(.asin, "atan",  caption: "Inverse tan"),
                        Key(.tanh, "tanh",  caption: "Hyperbolic tan"),
                        Key(.atanh, "atanh",caption: "Inverse tanh"),
                       ],
                       caption: "Tan functions"
    )
    
    SubPadSpec.define( .log,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.log, "log"),
                        Key(.ln, "ln"),
                        Key(.log2, "log_{2}"),
                        Key(.logY, "log_{y}x")
                       ]
    )

    SubPadSpec.define( .tenExp,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.tenExp, "10^{x}"),
                        Key(.eExp, "e^{x}"),
                        Key(.y2x, "y^{x}"),
                       ]
    )
    
    SubPadSpec.define( .xy,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.xy, "X\u{21c6}Y"),
                        Key(.xz, "X\u{21c6}Z"),
                        Key(.yz, "Y\u{21c6}Z"),
                       ]
    )

    SubPadSpec.define( .hr,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.us,  "\u{03BC}s"),
                        Key(.ms,  "ms"),
                        Key(.second, "sec"),
                        Key(.min, "min"),
                        Key(.hr,  "hr"),
                        Key(.day, "day"),
                        Key(.yr,  "yr"),
                       ]
    )

    SubPadSpec.define( .km,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.mm, "mm"),
                        Key(.cm, "cm"),
                        Key(.metre,  "m"),
                        Key(.km, "km"),
                       ]
    )

    SubPadSpec.define( .mi,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.inch, "in"),
                        Key(.ft, "ft"),
                        Key(.yd,  "yd"),
                        Key(.mi, "mi"),
                       ]
    )

    SubPadSpec.define( .clX,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.clX,  "ƒ{0.8}ClrX",   caption: "Clear X"),
                        Key(.clY,  "ƒ{0.8}ClrY",   caption: "Clear Y"),
                        Key(.clZ,  "ƒ{0.8}ClrY",   caption: "Clear Z"),
                        Key(.clReg,"ƒ{0.8}CL Reg", caption: "Clear Registers"),
                       ],
                       caption: "Clear"
    )

    SubPadSpec.define( .deg,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.dm,   "dm"),
                        Key(.dms,  "dms"),
                        Key(.rad,  "rad"),
                        Key(.minA, "min"),
                       ]
    )

    SubPadSpec.define( .kg,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.mg,    "mg"),
                        Key(.gram,  "g"),
                        Key(.kg,    "kg"),
                        Key(.tonne, "tn"),
                       ]
    )

    SubPadSpec.define( .lb,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.oz,    "oz"),
                        Key(.lb,    "lb"),
                        Key(.stone, "st"),
                        Key(.ton,   "ton"),
                       ]
    )

    SubPadSpec.define( .mL,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.mL,    "mL"),
                        Key(.liter, "L"),
                        Key(.floz,  "fl-oz"),
                        Key(.cup,   "cup"),
                        Key(.pint,  "pint"),
                        Key(.quart, "quart"),
                        Key(.us_gal,"ƒ{0.9}US-gal"),
                        Key(.gal,   "gal"),
                       ]
    )
    
    SubPadSpec.define( .multiValue,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.spherical,  "ƒ{0.8}\u{27e8}\u{03c1}, \u{03b8}, \u{03c6}\u{27e9}ƒ{}", caption: "Spherical"),
                        Key(.polar,      "\u{27e8}\u{03c1}, ƒ{0.8}\u{03b8}ƒ{}\u{27e9}", caption: "Polar"),
                        Key(.complex,    "x ç{UnitText}+ç{} yç{UnitText}iç{}", caption: "Complex"),
                        Key(.vector,     "\u{27e8}x, y\u{27e9}", caption: "2D Vector"),
                        Key(.vector3D,   "ƒ{0.8}\u{27e8}x, y, z\u{27e9}ƒ{}", caption: "3D Vector"),

                        // Eliminate rational numbers for now
                        // Key(.rationalV, "x / y"),
                       ],
                       caption: "Vector"
    )

    SubPadSpec.define( .seq,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.seq,    "ƒ{0.8}Seq",    caption: "ƒ{0.9}Seq x values from z by y" ),
                        Key(.range,  "ƒ{0.8}Range",  caption: "Range 1 to x" ),
                        Key(.mapX,   "ƒ{0.8}Map-x",  caption: "Map f(x)"   ),
                        Key(.mapXY,  "ƒ{0.8}Map-xy", caption: "Map f(x,y)" ),
                        Key(.reduce, "ƒ{0.8}Reduce", caption: "Reduce x"   ),
                       ],
                       caption: "Sequence Operations"
    )

    SubPadSpec.define( .matrix,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.addRow, "ƒ{0.8}+Row",   caption: "Add New Row"),
                        Key(.addCol, "ƒ{0.8}+Col",   caption: "Add New Col"),
                        Key(.transpose, "={[]}^{T}", caption: "Transpose"),
                        Key(.identity, "I_{N}",      caption: "Identity"),
                       ],
                       caption: "Matrix Operations"
    )

    SubPadSpec.define( .x2,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.abs,    "|x|"),
                        Key(.x3,     "x^{3}"),
                       ]
    )

    SubPadSpec.define( .d0,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.d000,    "000"),
                       ]
    )

    SubPadSpec.define( .sqrt,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.sqrt,    "\u{221a}x"),
                        Key(.root3,   "ƒ{1.5}\u{221b}ƒ{}x"),
                       ]
    )

    SubPadSpec.define( .zRe,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.zRe,  "ƒ{0.9}Re(x)"),
                        Key(.zIm,  "ƒ{0.9}Im(x)"),
                        Key(.abs,  "|x|"),
                        Key(.zArg, "ƒ{0.9}Arg(x)"),
                        Key(.zConj,"ƒ{1.2}x\u{0305}"),
                        Key(.zNorm,"ƒ{0.7}Norm(x)"),
                       ]
    )

    SubPadSpec.define( .times,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.dotProduct,   "X\u{0305} \u{22c5} Y\u{0305}"),
                        Key(.crossProduct, "X\u{0305} ƒ{1.5}\u{2a2f}ƒ{} Y\u{0305}"),
                       ]
    )

    SubPadSpec.define( .stoX,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.stoY,    "StoY"),
                        Key(.stoZ,    "StoZ"),
                        Key(.popX,    "ƒ{0.9}PopX"),
                        Key(.popXY,   "ƒ{0.9}PopXY"),
                        Key(.popXYZ,  "ƒ{0.9}PopXYZ"),
                       ]
    )
    
    SubPadSpec.define( .roll,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.roll, "R\u{2193}"),
                        Key(.lastx, "LSTx"),
                       ]
    )

    // Modal subpad definitions
    // Used to popup keypad for Sto, Rcl
    Key.defineModalKey( .stoX, .globalMemory )
    Key.defineModalKey( .stoY, .globalMemory )
    Key.defineModalKey( .stoZ, .globalMemory )
    Key.defineModalKey( .rcl,  .globalMemory )
    Key.defineModalKey( .lib,  .selectMacro  )
}


let psAlpha =
PadSpec(
    keySpec: ksModalPop,
    cols: 6,
    keys: [
        Key(.A, "A"), Key(.B, "B"), Key(.C, "C"), Key(.D, "D"), Key(.E, "E"), Key(.F, "F"),
        Key(.G, "G"), Key(.H, "H"), Key(.I, "I"), Key(.J, "J"), Key(.K, "K"), Key(.L, "L"),
        Key(.M, "M"), Key(.N, "N"), Key(.O, "O"), Key(.P, "P"), Key(.Q, "Q"), Key(.R, "R"),
        Key(.S, "S"), Key(.T, "T"), Key(.U, "U"), Key(.V, "V"), Key(.W, "W"), Key(.X, "X"),
        Key(.Y, "Y"), Key(.Z, "Z"),
    ],
    caption: "Memory"
)


let psAlphaLower =
    PadSpec(
        keySpec: ksModalPop,
        cols: 6,
        keys: [
            Key(.a, "a"), Key(.b, "b"), Key(.c, "c"), Key(.d, "d"), Key(.e, "e"), Key(.f, "f"),
            Key(.g, "g"), Key(.h, "h"), Key(.i, "i"), Key(.j, "j"), Key(.k, "k"), Key(.l, "l"),
            Key(.m, "m"), Key(.n, "n"), Key(.o, "o"), Key(.p, "p"), Key(.q, "q"), Key(.r, "r"),
            Key(.s, "s"), Key(.t, "t"), Key(.u, "u"), Key(.v, "v"), Key(.w, "w"), Key(.x, "x"),
            Key(.y, "y"), Key(.z, "z"),
        ],
        caption: "Memory"
)

let psGreek =
    PadSpec(
        keySpec: ksModalPop,
        cols: 6,
        keys: [
            Key(.alpha,   "\u{03b1}"), Key(.beta,    "\u{03b2}"), Key(.gamma,   "\u{03b3}"), Key(.delta,   "\u{03b4}"), Key(.epsilon, "\u{03b5}"), Key(.zeta,    "\u{03b6}"),
            Key(.eta,     "\u{03b7}"), Key(.theta,   "\u{03b8}"), Key(.iota,    "\u{03b9}"), Key(.kappa,   "\u{03ba}"), Key(.lambda,  "\u{03bb}"), Key(.mu,      "\u{03bc}"),
            Key(.nu,      "\u{03bd}"), Key(.xi,      "\u{03be}"), Key(.omicron, "\u{03bf}"), Key(.pi,      "\u{03c0}"), Key(.rho,     "\u{03c1}"), Key(.sigma,   "\u{03c3}"),
            Key(.tau,     "\u{03c4}"), Key(.upsilon, "\u{03c5}"), Key(.phi,     "\u{03c6}"), Key(.chi,     "\u{03c7}"), Key(.psi,     "\u{03c8}"), Key(.omega,   "\u{03c9}"),
            Key(.noop), Key(.noop),
        ],
        caption: "Memory"
    )


let psDigits =
    PadSpec(
        keySpec: ksModalPop,
        cols: 6,
        keys: [
            Key(.d1, "1"), Key(.d2, "2"), Key(.d3, "3"), Key(.d4, "4"), Key(.d5, "5"), Key(.d6, "6"),
            Key(.d7, "7"), Key(.d8, "8"), Key(.d9, "9"), Key(.d0, "0"), Key(.noop), Key(.noop),
            Key(.noop), Key(.noop), Key(.noop), Key(.noop), Key(.noop), Key(.noop),
            Key(.noop), Key(.noop), Key(.noop), Key(.noop), Key(.noop), Key(.noop),
            Key(.noop), Key(.noop),
        ],
        caption: "Memory"
    )

// ******************
