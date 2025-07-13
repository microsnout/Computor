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
        
        if model.aux.detailItemIndex == -1 {
            
            // List of all available macros
            MemoryListView(model: model)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        else {
            // Detailed view of selected macro
            MemoryDetailView(model: model, itemIndex: $model.aux.detailItemIndex)
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
                let memList = model.state.memory
                let count   = memList.count
                
                ScrollView {
                    LazyVStack {
                        ForEach ( 0 ..< count, id: \.self ) { index in
                            
                            let mr  = model.state.memory[index]
                            
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
                                            RichText(caption, size: .normal, weight: .regular, design: .serif, defaultColor: color )
                                        }
                                            
                                        // Memory value display
                                        TypedRegister( text: txt, size: .small ).padding( .horizontal, 20)
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    
                                    // Button controls at right of rows
                                    HStack( spacing: 20 ) {
                                        Button( action: { model.memoryOp( key: .rclMem, tag: mr.tag ) } ) {
                                            Image( systemName: "arrowshape.down" )
                                        }
                                        Button( action: { model.delMemoryItems(set: [index]) } ) {
                                            Image( systemName: "trash" )
                                        }
                                    }.padding( [.trailing], 20 )
                                }
                                .onTapGesture {
                                    withAnimation {
                                        model.aux.detailItemIndex = index
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


//struct MemoryListView_Previews: PreviewProvider {
//    
//    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        newModel.state.memory = []
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MemoryListView_Previews.addSampleMemory( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    MemoryListView( model: model)
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
//
//
//struct MemoryListView_Previews: PreviewProvider {
//    
//    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        newModel.state.memory = []
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MemoryListView_Previews.addSampleMemory( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    MemoryListView( model: model)
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
