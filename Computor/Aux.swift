//
//  Aux.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-07.
//
import SwiftUI

enum AuxDispMode: Int, Hashable {
    case memoryList = 0, memoryDetail, macroList
}

struct AuxState {
    var mode: AuxDispMode = .memoryList
    var detailItemIndex: Int = 0
    var list = MacroOpSeq()
    var kcRecording: KeyCode? = nil
    var recording: Bool { kcRecording != nil }
    var pauseCount: Int = 0
    
    mutating func pauseRecording() {
        pauseCount += 1
    }

    mutating func resumeRecording() {
        pauseCount -= 1
    }
    
    mutating func startRecFn( _ kc: KeyCode ) {
        if fnSet.contains(kc) && kcRecording == nil {
            // We can start recording key kc
            // Start with an empty list of instructions
            // Auxiliary display mode to macro list
            kcRecording = kc
            list.clear()
            mode = .macroList
            
            // Disable all Fn keys except the one recording
            for key in fnSet {
                if key != kc {
                    SubPadSpec.disableList.insert(key)
                }
            }
        }
    }
    
    mutating func recordKeyFn( _ kc: KeyCode ) {
        if pauseCount > 0 {
            return
        }
        
        if recording
        {
            // Fold unit keys into value on stack if possible
            if kc.isUnit {
                if let last = list.opSeq.last,
                   let value = last as? MacroValue
                {
                    if value.tv.tag == tagUntyped {
                        if let tag = TypeDef.kcDict[kc] {
                            var tv = value.tv
                            list.opSeq.removeLast()
                            tv.tag = tag
                            list.opSeq.append( MacroValue( tv: tv))
                            return
                        }
                    }
                }
            }
            
            list.opSeq.append( MacroKey( kc: kc) )
            
            let ix = list.opSeq.indices
            
            logM.debug("recordKey: \(ix)")
        }
    }
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if recording
        {
            list.opSeq.append( MacroValue( tv: tv) )
        }
    }
    
    mutating func stopRecFn( _ kc: KeyCode ) {
        if kc == kcRecording {
            kcRecording = nil
            list.clear()
            mode = .memoryList
            SubPadSpec.disableList.removeAll()
        }
    }
}


// ************************************************************* //
// Auxiliary Display
//

let auxRight: [AuxDispMode : AuxDispMode] = [
    .memoryList : .memoryDetail,
    .memoryDetail : .macroList
]

let auxLeft: [AuxDispMode : AuxDispMode] = [
    .macroList : .memoryDetail,
    .memoryDetail : .memoryList
]


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


struct MemRenameView: View {
    @StateObject var model: CalculatorModel
    
    @FocusState private var nameFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @State private var editName = ""

    var body: some View {
        let index = model.aux.detailItemIndex
        let value = model.state.memory[index]
        
        Form {
            TextField( "-Unnamed-", text: $editName )
            .focused($nameFocused)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .onAppear {
                if let name = value.name {
                    editName = name
                }
                nameFocused = true
            }
            .onSubmit {
                model.renameMemoryItem(index: index, newName: editName)
                dismiss()
            }
        }
        .scrollContentBackground(.hidden) // iOS 16+
    }
}


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
                MemRenameView( model: model )
                .presentationDetents([.fraction(0.4)])
                .presentationBackground( Color("ListBack") )
            }
        }
    }
}


struct MemoryListView: View {
    @StateObject var model: CalculatorModel

    let leadingOps: [(KeyCode, String, Color)] = [
        ( .rcl,    "RCL", .mint ),
        ( .sto,    "STO", .indigo ),
        ( .mPlus,  "M+",  .cyan  ),
        ( .mMinus, "M-",  .green )
    ]
    
    var body: some View {
        VStack {
            if model.state.memory.isEmpty {
                Text("Memory List\n(Press + to store X register)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            else {
                let strList = (0 ..< model.state.memory.count).map
                    { ( model.state.memory[$0].name,
                        model.state.memory[$0].value.renderRichText()) }
                
                List {
                    ForEach ( Array(strList.enumerated()), id: \.offset ) { index, item in
                        
                        // Not using render count for now
                        let (prefix, (value, _)) = item
                        
                        VStack( alignment: .leading, spacing: 0 ) {
                            let name: String = prefix ?? "-unnamed-"
                            
                            let color = prefix != nil ? Color("DisplayText") : Color(.gray)
                            
                            HStack {
                                // Memory name - tap to edit
                                Text(name).font(.footnote).bold().foregroundColor(color).listRowBackground(Color("List0"))
                                    .onTapGesture {
                                        model.aux.detailItemIndex = index
                                        model.aux.mode = .memoryDetail
                                    }
                            }
                            
                            // Memory value display
                            TypedRegister( text: value, size: .small ).padding( .horizontal, 20)
                        }
                        .listRowSeparatorTint(.blue)
                        .frame( height: 30 )
                        .swipeActions( edge: .leading, allowsFullSwipe: true ) {
                            // Memory Op buttons on leading edge
                            ForEach ( leadingOps.indices, id: \.self) { x in
                                let (key, text, color): (KeyCode, String, Color) = leadingOps[x]
                                Button {
                                    model.memoryOp( key: key, index: index )
                                } label: { Text(text).bold() }.tint(color)
                            }
                        }
                        .swipeActions( edge: .trailing, allowsFullSwipe: false) {
                            // Delete button on trailing edge
                            Button( role: .destructive) {
                                model.delMemoryItems( set: IndexSet( [index] ))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listRowSeparatorTint( Color("DisplayText"))
                }
                .listRowSpacing(0)
                .listStyle( PlainListStyle() )
                .padding( .horizontal, 0)
                .padding( .top, 0)
            }
        }
    }
}


struct MacroListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
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


struct AuxiliaryDisplay: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        HStack( spacing: 0) {
            VStack {
                Spacer()
                Image( systemName: "chevron.compact.left")
                    .onTapGesture {
                        if let new = auxLeft[model.aux.mode] {
                            model.aux.mode = new
                        }
                    }
                Spacer()
            }
            .padding([.leading], 0)
            .padding([.top], 10)
            .frame( minWidth: 18, maxWidth: 18, maxHeight: .infinity, alignment: .center)
            // .border(.green)

            switch model.aux.mode {
            case .memoryList:
                MemoryListView( model: model )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)

            case .memoryDetail:
                MemoryDetailView( model: model )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)

            case .macroList:
                MacroListView( model: model )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack {
                Spacer()
                Image( systemName: "chevron.compact.right")
                    .onTapGesture {
                        if let new = auxRight[model.aux.mode] {
                            model.aux.mode = new
                        }
                    }
                Spacer()
            }
            .padding([.trailing], 0)
            .padding([.top], 10)
            .frame( minWidth: 18, maxWidth: 18, maxHeight: .infinity, alignment: .center)
            // .border(.green)
        }
        .padding([.leading, .trailing, .top, .bottom], 0)
    }
}

