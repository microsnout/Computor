//
//  AuxMemoryListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct AuxMemoryView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        
        if model.aux.memRec == nil {
            
            // List of all available macros
            MemoryListView(model: model)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        else {
            // Detailed view of selected macro
            MemoryDetailView( model: model, memRec: $model.aux.memRec )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }
}


struct MemoryListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
        VStack {
            
            // Header bar
            AuxHeaderView( theme: Theme.lightBlue ) {
                
                HStack {
                    Spacer()
                    RichText( "Memory List", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                }
            }
            
            if model.state.memory.isEmpty {
                Spacer()
                VStack {
                    // Placeholder for empty memory list
                    Text("Memory List")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                Spacer()
            }
            else {
                ScrollView {
                    LazyVStack {
                        ForEach ( model.state.memory ) { mr in
                            
                            let (txt, _) = mr.tv.renderRichText()
                            
                            let sym = mr.tag.getRichText()
                            
                            let caption: String = mr.caption ?? "-caption-"
                            
                            let color = mr.caption != nil ? "UnitText" : "GrayText"
                            
                            VStack {
                                HStack {
                                    
                                    // Memory two line description
                                    VStack( alignment: .leading, spacing: 0 ) {
                                        
                                        HStack {
                                            // Tag Symbol
                                            RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                            
                                            // Caption text
                                            RichText(caption, size: .small, weight: .regular, design: .serif, defaultColor: color )
                                        }
                                            
                                        // Memory value display
                                        RichText( "ƒ{0.9}\(txt)", size: .small, weight: .bold, design: .serif ).padding([.leading], 10)
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    
                                    // Button controls at right of rows
                                    HStack( spacing: 20 ) {
                                        
                                        // ARROW DOWN
                                        Button( action: { model.memoryOp( key: .rclMem, tag: mr.tag ) } ) {
                                            Image( systemName: Const.Icon.arrowDown )
                                        }
                                        
                                        // TRASH CAN
                                        Button( action: {
                                            model.deleteMemoryRecords( set: [mr.tag] )
                                        } ) {
                                            Image( systemName: Const.Icon.trash )
                                        }
                                    }.padding( [.trailing], 20 )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        // Navigate to selected item
                                        model.aux.memRec = mr
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
    }
}
