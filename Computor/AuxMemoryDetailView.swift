//
//  AuxMemoryDetailView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MemoryDetailView: View {
    @StateObject var model: CalculatorModel
    
    @Binding var itemIndex: Int
    
    @State private var renameSheet = false
    
    @State private var position: Int? = 0

    var body: some View {
        if model.aux.detailItemIndex != -1 {
            VStack {
                AuxHeaderView( theme: Theme.lightBlue ) {
                    HStack {
                        Image( systemName: "chevron.left")
                            .padding( [.leading], 10 )
                            .onTapGesture {
                                withAnimation {
                                    model.aux.detailItemIndex = -1
                                }
                            }
                        
                        Spacer()
                        RichText( "Memory Detail", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                        Spacer()
                    }
                }
                
                Spacer()
                
                if model.state.memory.isEmpty {
                    Text("Memory Detail")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            LazyVStack {
                                let count = model.state.memory.count
                                
                                ForEach( 0 ..< count, id: \.self ) { index in
                                    
                                    let mr = model.state.memory[index]
                                    let sym = mr.tag.getRichText()
                                    let caption = mr.caption ?? "-Unnamed-"
                                    let (valueStr, _) = mr.tv.renderRichText()
                                    let color = mr.caption != nil ? "UnitText" : "GrayText"
                                    
                                    VStack {
                                        RichText("ƒ{1.5}\(sym)", size: .large, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                        
                                        RichText( "ƒ{1.2}ç{\(color)}\(caption)", size: .large, design: .serif )
                                            .onTapGesture {
                                                renameSheet = true
                                            }
                                        
                                        TypedRegister( text: valueStr, size: .large ).padding( .leading, 0)
                                    }
                                    .id( index )
                                    .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition( id: $position )
                        .onChange( of: position ) { oldIndex, newIndex in
                            model.aux.detailItemIndex = newIndex ?? 0
                        }
                    }
                }
                
                Spacer()
                
                // Detail Edit Controls
                HStack( spacing: 25 ) {
                    let mr = model.state.memory[model.aux.detailItemIndex]
                    
                    Button( action: { model.memoryOp( key: .mPlus, tag: mr.tag ) } ) {
                        Text( "M+" )
                    }
                    
                    Button( action: { model.memoryOp( key: .mMinus, tag: mr.tag ) } ) {
                        Text( "M-" )
                    }
                    
                    Button( action: { model.memoryOp( key: .rclMem, tag: mr.tag ) } ) {
                        Image( systemName: "arrowshape.down" )
                    }
                    
                    Button( action: { model.memoryOp( key: .stoMem, tag: mr.tag ) } ) {
                        Image( systemName: "arrowshape.up" )
                    }
                    
                    Button( action: {
                        model.delMemoryItems(set: [model.aux.detailItemIndex])
                        model.aux.detailItemIndex = -1
                    } ) {
                        Image( systemName: "trash" )
                    }
                }
                .frame( maxWidth: .infinity )
                .padding( [.bottom], 5 )
            }
            .padding( [.top], 0 )
            .padding( [.bottom], 10 )
            .onChange( of: itemIndex ) { oldIndex, newIndex in
                position = newIndex
            }
            .sheet(isPresented: $renameSheet) {
                ZStack {
                    Color("ListBack").edgesIgnoringSafeArea(.all)
                    MemoryRenameView( model: model )
                        .presentationDetents([.fraction(0.4)])
                        .presentationBackground( Color("ListBack") )
                }
            }
        }
    }
}


//struct MemoryDetailView_Previews: PreviewProvider {
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
//                    MemoryDetailView( model: model, itemIndex: $model.aux.detailItemIndex )
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
//struct MemoryDetailView_Previews: PreviewProvider {
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
//                    MemoryDetailView( model: model, itemIndex: $model.aux.detailItemIndex )
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
