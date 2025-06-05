//
//  AuxValueBrowser.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-03.
//
import SwiftUI


struct ValueBrowserView: View {
    
    @StateObject var model: CalculatorModel
    
    let lineNoFmt = "ç{LineNoText}={%3d }ç{}"
    let colNoFmt  = "ç{LineNoText}={%3d}ç{}"

    func shapeStr( _ rows: Int, _ cols: Int ) -> String {
        if rows*cols == 1 {
            return ""
        }
        
        return "[\(rows) x \(cols)]"
    }
    
    var body: some View {
        let tv = model.state.Xtv
        
        let nameStr = "X"
        
        let color = "DisplayText"
        
        let ( _, rows, cols ) = tv.getShape()

        VStack {
            AuxHeaderView( theme: Theme.lightRed ) {
                RichText( "\(nameStr) Register  \(shapeStr(rows, cols))", size: .small, weight: .bold )
            }
            
            Spacer()
            
            if tv.isSimple {
                // Non-matrix value
                
                let (valueStr, _) = tv.renderRichText()
                
                VStack {
                    RichText( "ƒ{1.5}ç{\(color)}\(nameStr)", size: .large, weight: .bold, design: .serif )
                    TypedRegister( text: valueStr, size: .large ).padding( .leading, 0)
                }
                Spacer()
            }
            else if tv.rows == 1 {
                // Row matrix
                
                VStack( spacing: 0 ) {
                    ScrollView {
                        LazyVStack( spacing: 7 ) {
                            
                            ForEach (1...cols, id: \.self) { c in
                                
                                let line = String( format: lineNoFmt, c)
                                
                                let tvValue = tv.getValue( r: 1, c: c ) ?? untypedZero
                                
                                let (valueStr, _) = tvValue.renderRichText()
                                
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
            }
            else {
                VStack( spacing: 0 ) {
                    Spacer()
                    ScrollView {
                        ScrollView( [.horizontal, .vertical] ) {
                            Grid {
                                GridRow {
                                    HStack {
                                        RichText( "ç{LineNoText}={ }ç{}", size: .small )
                                        Spacer()
                                    }
                                    .padding( 2)

                                    ForEach (1...cols, id: \.self) { c in
                                        let col = String( format: colNoFmt, c)
                                        
                                        HStack {
                                            RichText( col, size: .small )
                                            Spacer()
                                        }
                                        .padding( 2)
                                    }
                                }
                                
                                ForEach (1...rows, id: \.self) { r in
                                    
                                    let row = String( format: lineNoFmt, r)

                                    GridRow {
                                        HStack {
                                            RichText( row, size: .small )
                                            Spacer()
                                        }
                                        .padding( 2)

                                        ForEach (1...cols, id: \.self) { c in

                                            let tvValue = tv.getValue( r: r, c: c ) ?? untypedZero
                                            
                                            let (valueStr, _) = tvValue.renderRichText()
                                            
                                            HStack {
                                                RichText( valueStr, size: .small )
                                                Spacer()
                                            }
                                            .padding( 2)
                                        }
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


//struct ValueBrowserView_Previews: PreviewProvider {
//    
//    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        
//        // FIX: MacroKey not working here, keys not defined yet?
//        newModel.state.Xtv = TaggedValue(.real, reg: 3.33)
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MacroListView_Previews.addSampleMacro( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    ValueBrowserView( model: model)
//                        .frame( maxWidth: .infinity, maxHeight: .infinity)
//                        .preferredColorScheme(.light)
//                }
//                .padding([.leading, .trailing, .top, .bottom], 0)
//                .background( Color("Display") )
//                .border(Color("Frame"), width: 3)
//            }
//            .padding(.horizontal, 30)
//            .padding(.vertical, 5)
//            .background( Color("Background"))
//        }
//    }
//}
