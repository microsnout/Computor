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
            Key(.rcl,     "ƒ{0.8}Rcl"),
            Key(.sto,     "ƒ{0.8}Sto"),
            Key(.mRename, "ƒ{0.8}Rename", size: 2),
        ]
    )


struct MemoryDetailView: View {
    @StateObject var model: CalculatorModel
    
    @State var renameSheet = false
    
    @State private var position: ScrollPosition = .init(idType: Int.self)

    struct MemoryDetailKeypress : KeyPressHandler {
        var model: CalculatorModel
        
        @Binding var renameSheet: Bool

        func keyPress(_ event: KeyEvent ) -> KeyPressResult {
            let index = model.aux.detailItemIndex
            
            switch event.kc {
            case .rcl, .sto, .mPlus, .mMinus:
                model.memoryOp(key: event.kc, index: index)
                
            case .mRename:
                renameSheet = true
                
            default:
                break
            }
            return KeyPressResult.stateChange
        }
        
        func getKeyText( _ kc: KeyCode ) -> String? { nil }
        
        func isKeyRecording( _ kc: KeyCode ) -> Bool { false }
    }


    var body: some View {
        VStack {
            Spacer()
            
            if model.state.memory.isEmpty {
                Text("Memory List\n(Press + to store X register)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack {
                            let count = model.state.memory.count
                            
                            ForEach( 0 ..< count, id: \.self ) { index in
                                let nv = model.state.memory[index]
                                let nameStr = nv.name ?? "-Unnamed-"
                                let (valueStr, _) = nv.value.renderRichText()
                                let color = nv.name != nil ? "DisplayText" : "GrayText"

                                VStack {
                                    RichText( "ƒ{1.5}ç{\(color)}\(nameStr)", size: .large )
                                    TypedRegister( text: valueStr, size: .large ).padding( .leading, 0)
                                }
                                .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition($position)
                    .onChange(of: position ) {
                        if let index: Int = position.viewID(type: Int.self) {
                            model.aux.detailItemIndex = index
                        }
                    }
                }
            }

            Spacer()
            KeypadView( padSpec: psMemDetail,
                        keyPressHandler: MemoryDetailKeypress( model: model, renameSheet: $renameSheet))
        }
        .padding( [.bottom, .top], 10 )
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


struct MemoryDetailView_Previews: PreviewProvider {
    
    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
        let newModel = model
        newModel.state.memory = NamedValue.getSampleData()
        return newModel
    }
    
    static var previews: some View {
        @StateObject  var model = MemoryListView_Previews.addSampleMemory( CalculatorModel())
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            VStack {
                VStack {
                    MemoryDetailView( model: model)
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
