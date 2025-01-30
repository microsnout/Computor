//
//  DisplayView.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2021-10-28.
//
import SwiftUI


typealias TextSizeSpec = ( body: CGFloat, subscript: CGFloat, baseline: CGFloat )

enum TextSize: Int, Hashable {
    case small = 0, normal, large
}

let textSpecTable: [TextSize: TextSizeSpec] = [
    .small  : ( 12.0,  8.0, 6.0 ),
    .normal : ( 14.0, 10.0, 6.0 ),
    .large  : ( 16.0, 12.0, 6.0 )
]

func getTextSpec( _ size: TextSize ) -> TextSizeSpec {
    return textSpecTable[size] ?? (14.0, 10.0, 6.0)
}

struct TypedRegister: View {
    let text: String
    let size: TextSize
    
    var body: some View {
        HStack( alignment: .bottom, spacing: 0 ) {
            RichText( text, size: size, weight: .bold, design: .serif )
        }
        .frame( height: 18 )
    }
}


struct Display: View {
    @StateObject var model: CalculatorModel
    
    @AppStorage(.settingsPriDispTextSize)
    private var priDispTextSize = TextSize.normal

    let rowHeightTable: [TextSize : Double] = [.small : 29, .normal : 32, .large : 35]
    
    var body: some View {
        let _ = Self._printChanges()
        
        let midText = model.status.midText
        
        let rightText = model.isKeyRecording() ? "ç{StatusRedText}RECç{}" : ""
        
        let rowHeight = rowHeightTable[priDispTextSize] ?? 35.0

        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color("Display"))
            
            VStack( alignment: .leading, spacing: 4) {
                // Status line above register displays
                HStack {
                    RichText("", size: .small)
                    Spacer()
                    RichText( midText, size: .small, weight: .bold)
                    Spacer()
                    RichText( rightText, size: .small )
                }.frame( height: 10 ).padding(0)
                
                ForEach (0 ..< model.rowCount, id: \.self) { index in
                    TypedRegister( text: model.renderRow(index: index), size: priDispTextSize )
                        .padding(.leading, 10)
                }
            }
            .frame( height: rowHeight*Double(model.rowCount) )
        }
        .padding( [.leading, .trailing], 10)
        .background(Color("Display"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Frame"), lineWidth: 6))
        .fixedSize(horizontal: false, vertical: true)
    }
}

