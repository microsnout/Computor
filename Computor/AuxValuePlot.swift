//
//  AuxValuePlot.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-06.
//
import SwiftUI

//            Canvas { gc, size in
//                gc.translateBy(x: size.width / 2, y: size.height / 2)
//                let rectangle = Rectangle().path(in: .zero.insetBy(dx: -5, dy: -5))
//                gc.fill(rectangle, with: .color(.green))
//            }
//


struct ValuePlotView: View {
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let nv = model.state.stack[regX]
        
        let nameStr = nv.name ?? "-Unnamed-"
        
        let color = nv.name != nil ? "DisplayText" : "GrayText"

        VStack {
            AuxHeaderView( theme: Theme.lightPurple ) {
                RichText( "\(nameStr) Register", size: .small )
            }
            
            
            let (valueStr, _) = nv.value.renderRichText()
            
            Canvas { context, size in
                context.stroke(
                    Path(ellipseIn: CGRect(origin: .zero, size: size)),
                    with: .color(.green),
                    lineWidth: 4)
            }
            .padding(10)
        }
    }
}


struct ValuePlotView_Previews: PreviewProvider {
    
    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
        let newModel = model
        
        // FIX: MacroKey not working here, keys not defined yet?
        newModel.state.stack[regX].value = TaggedValue(.real, reg: 3.33)
        return newModel
    }
    
    static var previews: some View {
        @StateObject  var model = MacroListView_Previews.addSampleMacro( CalculatorModel())
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            VStack {
                VStack {
                    ValuePlotView( model: model)
                        .frame( maxWidth: .infinity, maxHeight: .infinity)
                        .preferredColorScheme(.light)
                }
                .padding([.leading, .trailing, .top, .bottom], 0)
                .background( Color("Display") )
                .border(Color("Frame"), width: 3)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
            .background( Color("Background"))
        }
    }
}

