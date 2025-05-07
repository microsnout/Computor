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
                          keyColor: "KeyColor", textColor: "KeyText")

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
    keys: [ Key(.key7, "ƒ{1.2}7"), Key(.key8, "ƒ{1.2}8"), Key(.key9, "ƒ{1.2}9"),
            Key(.key4, "ƒ{1.2}4"), Key(.key5, "ƒ{1.2}5"), Key(.key6, "ƒ{1.2}6"),
            Key(.key1, "ƒ{1.2}1"), Key(.key2, "ƒ{1.2}2"), Key(.key3, "ƒ{1.2}3"),
            Key(.key0, "ƒ{1.2}0"), Key(.dot, "ƒ{1.2}."),  Key(.sign, "ƒ{1.2}+/-")
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
    keys: [ Key(.divide, "ƒ{1.4}÷"), Key(.deg, "ƒ{0.9}deg\u{00B0}"), Key(.y2x, "y^{x}"),
            Key(.times,  "ƒ{1.4}×"),  Key(.percent, "%"),    Key(.inv, "1/x"),
            Key(.minus,  "ƒ{1.4}−"),  Key(.xy, "ƒ{0.9}X\u{21c6}Y"),    Key(.x2, "x^{2}"),
            Key(.plus,   "ƒ{1.4}+"),  Key(.roll, "R\u{2193}"),   Key(.sqrt, "\u{221a}x")
          ])

let psClear = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.back, "ƒ{0.8}BACK/UNDO", size: 2), Key(.clX, "CLx") ]
    )

let psSoftkeyL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.fn1),
            Key(.fn2),
            Key(.fn3)
          ]
)

let psSoftkeyR = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.fn4),
            Key(.fn5),
            Key(.fn6)
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
        keys: [ Key(.quad, "ƒ{0.8}Quadƒ{}"),
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
    SubPadSpec.define( .fn0,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.clrFn, "Clear"),
                        Key(.recFn, "Rec"),
                        Key(.stopFn, "Stop"),
                        Key(.showFn, "Show"),
                       ]
    )
    
    SubPadSpec.copySpec(from: .fn0, list: [.fn1, .fn2, .fn3, .fn4, .fn5, .fn6])
    
    SubPadSpec.define( .sin,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.csc, "csc"),
                        Key(.acsc, "acsc"),
                        Key(.asin, "asin"),
                        Key(.sinh, "sinh"),
                        Key(.asinh, "asinh"),
                       ]
    )
    
    SubPadSpec.define( .cos,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.sec, "sec"),
                        Key(.asec, "asec"),
                        Key(.acos, "acos"),
                        Key(.cosh, "cosh"),
                        Key(.acosh, "acosh"),
                       ]
    )
    
    SubPadSpec.define( .tan,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.cot, "cot"),
                        Key(.acot, "acot"),
                        Key(.asin, "atan"),
                        Key(.tanh, "tanh"),
                        Key(.atanh, "atanh"),
                       ]
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
                        Key(.clX,  "CLx",   caption: "Clear X"),
                        Key(.clY,  "CLy",   caption: "Clear Y"),
                        Key(.clZ,  "CLz",   caption: "Clear Z"),
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
                        Key(.complex,    "x ç{Units}+ç{} yç{Units}iç{}", caption: "Complex"),
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

    PadSpec.defineModal( .stoX, psAlpha )
    
    PadSpec.copySpec( from: .stoX, list: [.rcl, .stoY, .stoZ])
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


// ******************
