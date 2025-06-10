//
//  AuxMacroListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MacroLibraryView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        
        if model.aux.macroKey == SymbolTag(.null) {
            
            // List of all available macros
            MacroListView(model: model)
        }
        else {
            // Detailed view of selected macro
            MacroDetailView(model: model)
        }
    }
}


struct MacroListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
        
        VStack {
            AuxHeaderView( theme: Theme.lightYellow ) {
                
                HStack {
                    Spacer()
                    RichText("Macro Library", size: .small, weight: .bold )
                    Spacer()
                }
            }
            .padding( [.leading], 5 )

            ScrollView {
                
                LazyVStack( spacing: 5 ) {
                    
                    ForEach ( model.appState.macroTable, id: \.symTag ) { mr in
                        
                        let caption = mr.caption ?? "ç{GrayText}-caption-"
                        
                        HStack( spacing: 0 ) {
                            RichText( mr.symTag.getRichText(), size: .small, weight: .bold )
                                .frame( width: 50 )
                            
                            RichText( caption, size: .small, weight: .bold )
                            
                            Spacer()
                        }
                        .onTapGesture {
                            model.aux.macroKey = mr.symTag
                            model.aux.macroSeq = mr.opSeq
                        }
                    }
                }
                .padding( [.top], 0 )
            }
        }
    }
}


struct MacroDetailView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let name = model.getKeyText( model.aux.macroKey.kc )
            
        if name != nil || model.aux.isRecording  {
            VStack( spacing: 0 ) {
                let captionTxt = "Macro " + ( name ?? "ç{StatusRedText}REC" )
                
                AuxHeaderView( theme: Theme.lightYellow ) {
                    
                    HStack {
                        Image( systemName: "chevron.left")
                            .padding( [.leading], 10 )
                            .onTapGesture {
                                model.aux.macroKey = SymbolTag(.null)
                            }
                        
                        Spacer()
                        
                        RichText(captionTxt, size: .small, weight: .bold )
                        
                        Spacer()
                    }
                }
                
                ScrollView {
                    ScrollViewReader { proxy in
                        let list = model.aux.macroSeq
                        
                        VStack(spacing: 7) {
                            ForEach (list.indices, id: \.self) { x in
                                let op: MacroOp = list[x]
                                let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                                let text = op.getRichText(model)
                                
                                HStack {
                                    RichText( line, size: .small )
                                    RichText( text, size: .small, weight: .bold )
                                    Spacer()
                                }
                            }
                            .onChange( of: list.count ) {
                                if list.count > 1 {
                                    proxy.scrollTo( list.indices[list.endIndex - 1] )
                                }
                            }
                        }
                        .padding([.leading, .trailing], 20)
                        .padding([.top, .bottom], 10)
                    }
                }
            }
        }
        else {
            VStack {
                AuxHeaderView( theme: Theme.lightYellow ) {
                    RichText( "Macro List", size: .small, weight: .bold  )
                }
                
                Spacer()
            }
        }
    }
}


//struct MacroListView_Previews: PreviewProvider {
//    
//    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        
//        // FIX: MacroKey not working here, keys not defined yet?
//        newModel.aux.list = MacroOpSeq( [ MacroValue( tv: TaggedValue(.real, reg: 3.33)) ] )
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
//                    MacroListView( model: model)
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
