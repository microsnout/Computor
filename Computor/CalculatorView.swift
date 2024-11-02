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

let ksNormal = KeySpec( width: 45, height: 40,
                        keyColor: Color("KeyColor"), textColor: Color("KeyText"))

let ksSoftkey = KeySpec( width: 45, height: 30, fontSize: 14,
                         keyColor: Color("KeyColor"), textColor: Color("KeyText"))

let ksSubpad = KeySpec( width: 45, height: 30, fontSize: 14,
                        keyColor: Color(.brown), textColor: Color("KeyText"))

let ksUnits = KeySpec( width: 60, height: 25, fontSize: 14,
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
    keys: [ Key(.key7, "7"), Key(.key8, "8"), Key(.key9, "9"),
            Key(.key4, "4"), Key(.key5, "5"), Key(.key6, "6"),
            Key(.key1, "1"), Key(.key2, "2"), Key(.key3, "3"),
            Key(.key0, "0"), Key(.dot, "."),  Key(.sign, "+/-", fontSize: 15)
          ]
)

let psEnter = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.enter, "Enter", size: 2, fontSize: 15), Key(.eex, "EE", fontSize: 15) ]
    )

let psOperations = PadSpec(
    keySpec: ksNormal,
    cols: 3,
    keys: [ Key(.divide, "÷", fontSize: 24), Key(.deg, "deg", fontSize: 12), Key(.y2x, "y^{x}"),
            Key(.times, "×", fontSize: 24),  Key(.lastx, "log_{2}", fontSize: 12),    Key(.inv, image: .onex),
            Key(.minus, "−", fontSize: 24),  Key(.xy, "X\u{21c6}Y", fontSize: 12),    Key(.x2, "x^{2}"),
            Key(.plus,  "+", fontSize: 24),  Key(.roll, "R\u{2193}", fontSize: 12),   Key(.sqrt,image: .rx)
          ])

let psClear = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.back, "BACK/UNDO", size: 2, fontSize: 12.0), Key(.clX, "CLx", fontSize: 14.0) ]
    )

let psUnitsL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.deg, "deg"),
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
                Key(.pi,  "\u{1d70b}", fontSize: 20)
            ]
    )

let psFormatL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.fix, "fix"),
            Key(.sci, "sci"),
            Key(.percent, "%"),
        ],
    fontSize: 14.0
)

let psFormatR = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.currency, "$"),
            Key(.fixL, ".00\u{2190}", fontSize: 12.0),
            Key(.fixR, ".00\u{2192}", fontSize: 12.0),
        ],
    fontSize: 14.0
)

func initKeyLayout() {
    SubPadSpec.define( .sin,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.asin, "asin"),
                       ],
                       fontSize: 14.0
    )
    
    SubPadSpec.define( .cos,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.asin, "acos"),
                       ],
                       fontSize: 14.0
    )
    
    SubPadSpec.define( .tan,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.asin, "atan"),
                       ],
                       fontSize: 14.0
    )
    
    SubPadSpec.define( .log,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.log, "log"),
                        Key(.ln, "ln"),
                        Key(.log2, "log_{2}"),
                        Key(.logY, "log_{y}x")
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .tenExp,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.tenExp, "10^{x}"),
                        Key(.eExp, "e^{x}"),
                        Key(.y2x, "y^{x}"),
                       ],
                       fontSize: 14.0
    )
    
    SubPadSpec.define( .xy,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.xy, "X\u{21c6}Y", fontSize: 14.0),
                        Key(.xz, "X\u{21c6}Z", fontSize: 14.0),
                        Key(.yz, "Y\u{21c6}Z", fontSize: 14.0),
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .hr,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.sec, "sec"),
                        Key(.min, "min"),
                        Key(.hr,  "hr"),
                        Key(.day, "day"),
                        Key(.yr,  "yr"),
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .km,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.mm, "mm"),
                        Key(.cm, "cm"),
                        Key(.m,  "m"),
                        Key(.km, "km"),
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .mi,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.inch, "in"),
                        Key(.ft, "ft"),
                        Key(.yd,  "yd"),
                        Key(.mi, "mi"),
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .clX,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.clX,  "X"),
                        Key(.clY,  "Y"),
                        Key(.clZ,  "Z"),
                        Key(.clReg,"Reg"),
                       ],
                       fontSize: 14.0,
                       caption: "Clear"
    )

    SubPadSpec.define( .deg,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.rad,  "rad"),
                        Key(.deg,"deg"),
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .kg,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.mg,    "mg"),
                        Key(.gram,  "g"),
                        Key(.kg,    "kg"),
                        Key(.tonne, "tn"),
                       ],
                       fontSize: 14.0
    )

    SubPadSpec.define( .lb,
                       keySpec: ksSubpad,
                       keys: [
                        Key(.oz,    "oz"),
                        Key(.lb,    "lb"),
                        Key(.stone, "st"),
                        Key(.ton,   "ton"),
                       ],
                       fontSize: 14.0
    )
}

// ******************


struct CalculatorView: View {
    @StateObject  var model = CalculatorModel()
    
    let swipeLeadingOpTable: [(KeyCode, String, Color)] = [
        ( .rcl,    "RCL", .mint ),
        ( .sto,    "STO", .indigo ),
        ( .mPlus,  "M+",  .cyan  ),
        ( .mMinus, "M-",  .green )
    ]
    
    var body: some View {
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            KeyStack() {
                VStack {
                    VStack {
                        MemoryDisplay( model: model, leadingOps: swipeLeadingOpTable )
                        
                        // App name and drag handle
                        HStack {
                            Text("HP 33").foregroundColor(.black)/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/().italic()
                            Spacer()
                            Image( systemName: "gearshape")
                        }
                        .frame( height: 25 )
                        
                        // Main calculator display
                        Display( model: model )
                        
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

