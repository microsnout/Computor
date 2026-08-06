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
    
    var icon: String { listControlSysNames[self] ?? ""  }
}


let listControlSysNames: [ListControl: String] = [
    .select: "",
    .delete: Const.Icon.trash,
    .move:   Const.Icon.move,
    .recall: Const.Icon.arrowDown,
    .store:  Const.Icon.arrowUp,
    .play:   Const.Icon.play,
    .plot:   Const.Icon.plot,
]


typealias ControlListClosure = ( _ item: ItemRec, _ model: CalculatorModel ) -> [ListControl]

typealias ControlPressClosure = ( _ cntl: ListControl,  _ item: ItemRec, _ model: CalculatorModel ) -> Void


struct AuxItemList<T>: View where T: ItemRec {
    @Environment(CalculatorModel.self) private var model
    
    @Binding var items: [T]
    
    @Binding var isEditing: Bool
    
    var controls: ControlListClosure
    
    var cpc: ControlPressClosure
    
    var body: some View {
        
        List {
            ForEach ( items ) { item in
                
                let txt = item.getSecondLineText()
                
                // Either a global memory tag or a macro tag for a computed memory
                let sym = item.getRichSymText()
                
                let caption: String = item.getCaption(model)
                
                let divider = item.symTag == SymbolTag.Divider
                
                VStack( spacing: 0 ) {
                    HStack {
                        
                        if divider {
                            
                            HStack {
                                Color("MenuIcon")
                                    .frame( height: 3 )
                                    .padding( [.leading], 20 )
                                
                                RichText(caption, size: .normal, weight: .regular, design: .serif, defaultColor: "BlackText" )
                                
                                Color("MenuIcon")
                                    .frame( height: 3 )
                            }
                            .frame( height: 18 )
                        }
                        else {
                            // Memory two line description
                            VStack( alignment: .leading, spacing: 0 ) {
                                
                                HStack {
                                    // Tag Symbol
                                    RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                    
                                    // Caption text
                                    RichText(caption, size: .small, weight: .regular, design: .serif, defaultColor: "UnitText" )
                                }
                                
                                // 2nd Line Item text - Value for memories
                                RichText( "ƒ{0.9}\(txt)", size: .small, weight: .bold, design: .serif ).padding([.leading], Const.UI.listItemIndent )
                            }
                            .frame(height: Const.UI.listItemHeight )
                            .padding( [.leading ], Const.UI.listItemPadding )
                            .onTapGesture {
                                withAnimation {
                                    cpc(.select, item, model)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Button controls at right of rows
                        HStack( spacing: Const.UI.listItemSpacing ) {
                            
                            let controlList = isEditing ? [.delete] : divider ? [] : controls(item, model)
                            
                            ForEach( controlList, id: \.self ) { cntl in
                                
                                Button( action: { cpc(cntl, item, model) } ) {
                                    Image( systemName: cntl.icon )
                                }
                                .buttonStyle(.borderless)
                            }
                            
                        }
                        .padding( [.trailing], 20 )
                    }
                    .contentShape(Rectangle())
                    
                    // .if ( divider ) { view in
                    //     view.background(.lightGrey)
                    // }
                    
                    if ( !divider ) {
                        Divider()
                            .padding( [.top], 5 )
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .onMove(perform: moveItem)
        }
        .listStyle(.plain)
        .listRowSpacing(5)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.defaultMinListHeaderHeight, 0)
        .scrollContentBackground(.hidden)
    }
    
    private func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        model.changed()
    }
}


struct ListDividerEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var caption: String = ""
    
    @Environment(CalculatorModel.self) private var model
    
    var ldc: ( _ newCap: String ) -> Void
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                Button( action: { ldc(caption); dismiss() } ) {
                    RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                }
            }
            .padding( [.top], 5 )
            
            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: Const.Placeholder.xcaption, text: $caption )
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.7), .large] )
        .onAppear() {
        }
    }
}
