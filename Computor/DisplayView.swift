//
//  DisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2021-10-28.
//
import SwiftUI


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


struct StatusView: View {
    @State var model: CalculatorModel

    var body: some View {
        
        let leftText = model.status.leftText
        
        let midText = model.status.midText
        
        let rightText = model.aux.isRec ? Const.Str.record : model.aux.recState == .debug ? Const.Str.debug : model.status.rightText
        
        HStack {
            RichText(leftText, size: .small, weight: .bold)
            Spacer()
            RichText( midText, size: .small, weight: .bold)
            Spacer()
            RichText( rightText, size: .small, weight: .bold )
        }
        .frame( height: 8 )
        .padding(0)
    }
}


struct DisplayView: View {
    @State var model: CalculatorModel
    
    @AppStorage(.settingsPriDispTextSize)
    private var priDispTextSize = TextSize.normal
    
    let rowHeightTable: [TextSize : Double] = [.small : 29, .normal : 32, .large : 35]
    
    var body: some View {
        // let _ = Self._printChanges()
        
        let rowHeight = rowHeightTable[priDispTextSize] ?? 35.0

        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color("Display"))
            
            VStack( alignment: .leading, spacing: 4) {
                // Status line above register displays
                StatusView( model: model )
                
                ForEach (0 ..< model.displayRows, id: \.self) { index in
                    TypedRegister( text: model.renderRow(index: index), size: priDispTextSize )
                        .padding(.leading, 10)
                }
            }
            .frame( height: rowHeight*Double(model.displayRows) )
        }
        .padding( [.leading, .trailing], 10)
        .background(Color("Display"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Frame"), lineWidth: 6))
        .fixedSize(horizontal: false, vertical: true)
    }
}


//struct DisplayView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        @State var model = CalculatorModel()
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                DisplayView( model: model )
//                    .preferredColorScheme(.light)
//            }
//            .padding(.horizontal, 30)
//            .padding(.vertical, 5)
//        }
//    }
//}
