//
//  CalculatorView.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2021-10-28.
//

import SwiftUI

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}


// ***************************************************
// Keypad Definitions

let ksNormal = KeySpec( width: 42, height: 35,
                        keyColor: Color("KeyColor"), textColor: Color("KeyText"))

let ksSoftkey = KeySpec( width: 42, height: 25,
                         keyColor: Color("KeyColor"), textColor: Color("KeyText"))

let ksSubFn = KeySpec( width: 48, height: 30,
                       keyColor: Color("PopBack"), textColor: Color("PopText"))

let ksSubpad = KeySpec( width: 42, height: 30,
                        keyColor: Color("PopBack"), textColor: Color("PopText"))

let ksUnits = KeySpec( width: 60, height: 25,
                       keyColor: Color("KeyColor"), textColor: Color("KeyText"))

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
    keys: [ Key(.divide, "ƒ{1.4}÷"), Key(.deg, "deg\u{00B0}"), Key(.y2x, "y^{x}"),
            Key(.times,  "ƒ{1.4}×"),  Key(.percent, "%"),    Key(.inv, "1/x"),
            Key(.minus,  "ƒ{1.4}−"),  Key(.xy, "X\u{21c6}Y"),    Key(.x2, "x^{2}"),
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
    keys: [ Key(.noop, ""),
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
    keys: [ Key(.noop),
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
                        Key(.asin, "sin^{-1}"),
                       ]
    )
    
    SubPadSpec.define( .cos,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.asin, "cos^{-1}"),
                       ]
    )
    
    SubPadSpec.define( .tan,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.asin, "tan^{-1}"),
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
                        Key(.sec, "sec"),
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
                        Key(.m,  "m"),
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
                        Key(.clX,  "X"),
                        Key(.clY,  "Y"),
                        Key(.clZ,  "Z"),
                        Key(.clReg,"Reg"),
                       ],
                       caption: "Clear"
    )

    SubPadSpec.define( .deg,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.dms, "dms"),
                        Key(.rad,  "rad"),
                        Key(.deg,"deg"),
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
    
    SubPadSpec.define( .multiValue,
                       keySpec: ksSubFn,
                       keys: [
                        Key(.rationalV, "x / y"),
                        Key(.vector2V,  "\u{27e8}x , y\u{27e9}"),
                        Key(.polarV,    "Stop"),
                        Key(.complexV,  "x ç{Units}+ç{} yç{Units}iç{}"),
                       ]
    )
}

// ******************


struct CalculatorView: View {
    @StateObject  var model = CalculatorModel()
    
    var body: some View {
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            KeyStack() {
                NavigationStack {
                    VStack {
                        AuxiliaryDisplay( model: model )
                        
                        // App name and drag handle
                        HStack {
                            Text("Computor").foregroundColor(Color("Frame"))/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/().italic()
                            Spacer()
                            
                            EditButton()
                            
                            Button( action: { model.addMemoryItem() }) {
                                Image( systemName: "plus") }

                            NavigationLink( destination: SettingsView() ) {
                                Image( systemName: "gearshape").foregroundColor(Color("Frame"))
                            }
                        }
                        .frame( height: 25 )
                        
                        // Main calculator display
                        Display( model: model )
                        
                        Spacer().frame( height: 15)
                        
                        HStack {
                            KeypadView( padSpec: psSoftkeyL, keyPressHandler: model )
                            Spacer()
                            KeypadView( padSpec: psSoftkeyR, keyPressHandler: model )
                        }
                        HStack {
                            KeypadView( padSpec: psUnitsL, keyPressHandler: model )
                            Spacer()
                            KeypadView( padSpec: psUnitsR, keyPressHandler: model )
                        }
                        HStack {
                            KeypadView( padSpec: psFunctionsL, keyPressHandler: model )
                            Spacer()
                            KeypadView( padSpec: psFunctionsR, keyPressHandler: model )
                        }
                        Divider()
                        HStack {
                            VStack( spacing: 15 ) {
                                KeypadView( padSpec: psNumeric, keyPressHandler: model )
                                KeypadView( padSpec: psEnter, keyPressHandler: model )
                            }
                            Spacer()
                            VStack( spacing: 15 ) {
                                KeypadView( padSpec: psOperations, keyPressHandler: model )
                                KeypadView( padSpec: psClear, keyPressHandler: model )
                            }
                        }
                        Divider()
                        HStack {
                            KeypadView( padSpec: psFormatL, keyPressHandler: model )
                            Spacer()
                            KeypadView( padSpec: psFormatR, keyPressHandler: model )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 5)
                    .background( Color("Background"))
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}


//struct CalculatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        CalculatorView()
//            .padding()
//    }
//}

