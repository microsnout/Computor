//
//  AuxItemList.swift
//  Computor
//
//  Created by Barry Hall on 2026-04-12.
//

import SwiftUI


enum ListControl: Identifiable {
    case select, delete, move, recall, store, play, plot
    
    var id: Self { self }
}


let listControlSysNames: [ListControl: String] = [
    .select: "",
    .delete: Const.Icon.trash,
    .move:   Const.Icon.move,
    .recall: Const.Icon.arrowDown,
    .store:  Const.Icon.arrowUp,
    .play:   Const.Icon.play,
    .plot:   Const.Icon.chart,
]


typealias ControlPressedClosure = ( _ control: ListControl, _ item: ItemRec ) -> Void


struct AuxItemList<T>: View where T: ItemRec, T: Identifiable {
    @Environment(CalculatorModel.self) private var model
    
    @Binding var items: [T]
    
    var controlList: [ListControl]
    
    var cpc: ControlPressedClosure
    
    @State private var draggedItemId: String? = nil

    var body: some View {
        
        ScrollView {
            LazyVStack {
                ForEach( $items ) { $mr in
                    
                    let item = $mr.wrappedValue
                    let sym = item.getRichSymText()
                    let caption = item.getCaption(model)
                    let secondLine = item.getSecondLineText()
                    
                    let plot = model.activeModule.getLocalPlot( item.symTag )
                    
                    VStack {
                        HStack {
                            
                            // Memory two line description
                            VStack( alignment: .leading, spacing: 0 ) {
                                
                                HStack {
                                    // Tag Symbol
                                    RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                    
                                    // Caption text
                                    RichText(caption, size: .small, weight: .regular, design: .serif, defaultColor: "UnitText" )
                                }
                                
                                // Memory value display
                                RichText( "ƒ{0.9}\(secondLine)", size: .small, weight: .bold, design: .serif ).padding([.leading], 10)
                            }
                            .padding( [.leading ], 20)
                            .frame( height: 30 )
                            
                            Spacer()
                            
                            
                            // Button controls at right of rows
                            HStack( spacing: 20 ) {
                                
                                ForEach ( controlList, id: \.self ) { lc in
                                    
                                    let sysName = listControlSysNames[lc]
                                    
                                    Button( action: { cpc( lc, item) } ) {
                                        Image( systemName: sysName ?? Const.Icon.arrowDown )
                                    }
                                }
                            }.padding( [.trailing], 20 )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                // Navigate to selected item
                                cpc( .select, item)
                            }
                        }
                        
                        Divider()
                    }
                }
            }
            .padding( .horizontal, 0)
            .padding( .top, 0)
        }
    }

}
