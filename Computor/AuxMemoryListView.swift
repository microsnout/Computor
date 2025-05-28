//
//  AuxMemoryListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MemoryListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
        VStack {
            AuxHeaderView( theme: Theme.lightBlue ) {
                
                HStack {
                    Spacer()
                    RichText( "Memory List", size: .small, weight: .bold )
                    Spacer()
                }
            }
            
            Spacer()
            
            if model.state.memory.isEmpty {
                Text("Memory List\n(Press + to store X register)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            else {
                let memList = model.state.memory
                let count   = memList.count
                
                ScrollView {
                    LazyVStack {
                        ForEach ( 0 ..< count, id: \.self ) { index in
                            
                            let mr  = model.state.memory[index]
                            
                            let (txt, _) = mr.tv.renderRichText()
                            
                            VStack {
                                HStack {
                                    VStack( alignment: .leading, spacing: 0 ) {
                                        let name: String = mr.caption ?? "-unnamed-"
                                        
                                        let color = mr.caption != nil ? Color("DisplayText") : Color(.gray)
                                        
                                        HStack {
                                            // Memory caption - tap to edit
                                            Text(name).font(.footnote).bold().foregroundColor(color).listRowBackground(Color("List0"))
                                        }
                                            
                                        // Memory value display
                                        TypedRegister( text: txt, size: .small ).padding( .horizontal, 20)
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    
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
                                    model.aux.detailItemIndex = index
                                    model.aux.activeView = .memoryDetail
                                }
                                
                                Divider()
                            }
                        }
                    }
                    .padding( .horizontal, 0)
                    .padding( .top, 0)
                }
            }
            Spacer()
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
