//
//  AuxMemoryDetailView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


let ksMemDetail = KeySpec( width: 36, height: 22,
                           keyColor: "AuxKey", textColor: "BlackText")

let psMemDetail = PadSpec(
        keySpec: ksMemDetail,
        cols: 6,
        keys: [
            Key(.mPlus,   "ƒ{0.8}M+"),
            Key(.mMinus,  "ƒ{0.8}M-"),
            Key(.rclMem,  "ƒ{0.8}Rcl"),
            Key(.stoMem,  "ƒ{0.8}Sto"),
            Key(.mRename, "ƒ{0.8}Caption", size: 2),
        ]
    )


struct MemoryDetailView: View {
    @StateObject var model: CalculatorModel
    
    @Binding var itemIndex: Int
    
    @State private var renameSheet = false
    
    @State private var position: Int? = 0

    struct MemoryDetailKeypress : KeyPressHandler {
        var model: CalculatorModel
        
        @Binding var renameSheet: Bool

        func keyPress(_ event: KeyEvent ) -> KeyPressResult {
            let index = model.aux.detailItemIndex
            let tag = model.state.memory[index].tag
            
            switch event.kc {
            case .rclMem, .stoMem, .mPlus, .mMinus:
                model.memoryOp(key: event.kc, index: index, tag: tag )
                
            case .mRename:
                renameSheet = true
                
            default:
                break
            }
            return KeyPressResult.stateChange
        }
    }
    
    var body: some View {
        VStack {
            AuxHeaderView( theme: Theme.lightGreen ) {
                RichText( "Memory Detail", size: .small, weight: .bold )
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
                                let nameStr = mr.caption ?? "-Unnamed-"
                                let (valueStr, _) = mr.tv.renderRichText()
                                let color = mr.caption != nil ? "DisplayText" : "GrayText"

                                VStack {
                                    RichText( "ƒ{1.5}ç{\(color)}\(nameStr)", size: .large )
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
            KeypadView( padSpec: psMemDetail,
                        keyPressHandler: MemoryDetailKeypress( model: model, renameSheet: $renameSheet))
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
