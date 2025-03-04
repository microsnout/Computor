//
//  AuxMacroListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MacroListView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let name = model.getKeyText( model.aux.macroKey )
            
        if name != nil || model.aux.isRecording  {
            VStack {
                let captionTxt = "Macro " + ( name ?? "ç{StatusRedText}REC" )
                
                AuxHeaderView( theme: Theme.lightYellow ) {
                    
                    HStack {
                        Spacer()
                        
                        RichText(captionTxt, size: .small )
                        
                        Spacer()
                    }
                }
                
                ScrollView {
                    ScrollViewReader { proxy in
                        let list = model.aux.list
                        
                        VStack(spacing: 7) {
                            ForEach (list.opSeq.indices, id: \.self) { x in
                                let op: MacroOp = list.opSeq[x]
                                let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                                let txt = op.getRichText(model)
                                
                                HStack {
                                    RichText( line, size: .small )
                                    RichText( txt, size: .small, weight: .bold )
                                    Spacer()
                                }
                            }
                            .onChange( of: list.opSeq.indices.count ) {
                                if list.opSeq.count > 1 {
                                    proxy.scrollTo( list.opSeq.indices[list.opSeq.endIndex - 1] )
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
                    RichText( "Macro List", size: .small  )
                }
                
                Spacer()
            }
        }
    }
}


struct MacroListView_Previews: PreviewProvider {
    
    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
        let newModel = model
        
        // FIX: MacroKey not working here, keys not defined yet?
        newModel.aux.list = MacroOpSeq( [ MacroValue( tv: TaggedValue(.real, reg: 3.33)) ] )
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
                    MacroListView( model: model)
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
