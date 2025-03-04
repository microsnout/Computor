//
//  AuxValueBrowser.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-03.
//
import SwiftUI


struct ValueBrowserView: View {
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let nv = model.state.stack[regX]
        
        let nameStr = nv.name ?? "-Unnamed-"
        
        let color = nv.name != nil ? "DisplayText" : "GrayText"

        VStack {
            AuxHeaderView( caption: "Value Browser", theme: Theme.lightRed )
            Spacer()
            
            if nv.value.isSimple {
                let (valueStr, _) = nv.value.renderRichText()
                
                VStack {
                    RichText( "ƒ{1.5}ç{\(color)}\(nameStr)", size: .large )
                    TypedRegister( text: valueStr, size: .large ).padding( .leading, 0)
                }
                Spacer()
            }
            else {
                let tvMatrix = nv.value
                
                let ( _, rows, _ ) = tvMatrix.getShape()
                
                VStack( spacing: 0 ) {
                    RichText( "ƒ{1.2}ç{\(color)}\(nameStr)", size: .large )
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            
                            LazyVStack(spacing: 7) {
                                
                                ForEach (1...rows, id: \.self) { r in
                                    
                                    let line = String( format: "ç{LineNoText}={%3d }ç{}", r)
                                    
                                    let tv = tvMatrix.getValue( row: r, col: 1 ) ?? untypedZero
                                    
                                    let (valueStr, _) = tv.renderRichText()
                                    
                                    HStack {
                                        RichText( line, size: .small )
                                        RichText( valueStr, size: .small )
                                        Spacer()
                                    }
                                }
                            }
                            .padding([.leading, .trailing], 20)
                            .padding([.top, .bottom], 0)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}


struct ValueBrowserView_Previews: PreviewProvider {
    
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
                    ValueBrowserView( model: model)
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
