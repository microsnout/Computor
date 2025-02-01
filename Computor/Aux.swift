//
//  Aux.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-07.
//
import SwiftUI

enum AuxDispMode: Int {
    case memoryList = 0, memoryDetail, macroList
}

struct AuxState {
    var mode: AuxDispMode = .memoryList
    var list: [MacroOp] = []
    
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
            list = []
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
                if let last = list.last,
                   let value = last as? MacroValue
                {
                    if value.tv.tag == tagUntyped {
                        if let tag = TypeDef.kcDict[kc] {
                            var tv = value.tv
                            list.removeLast()
                            tv.tag = tag
                            list.append( MacroValue( tv: tv))
                            return
                        }
                    }
                }
            }
            
            list.append( MacroKey( kc: kc) )
            
            let ix = list.indices
            
            logM.debug("recordKey: \(ix)")
        }
    }
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if recording
        {
            list.append( MacroValue( tv: tv) )
        }
    }
    
    mutating func stopRecFn( _ kc: KeyCode ) {
        if kc == kcRecording {
            kcRecording = nil
            list = []
            mode = .memoryList
            SubPadSpec.disableList.removeAll()
        }
    }
}


// ************************************************************* //
// Auxiliary Display
//

enum AuxDisp: Int {
    case memoryList = 0, memoryDetail, auxList
}

struct MemoryDetailView: View {
    @StateObject var model: CalculatorModel
    var index: Int

    @State private var editText = ""
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        let nv = model.state.memory[index]
        let (textValue, _) = nv.value.renderRichText()
        
        Form {
            TextField( "-Unnamed-", text: $editText )
            .focused($nameFocused)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .onAppear {
                if let name = nv.name {
                    editText = name
                }
                nameFocused = true
            }
            .onSubmit {
                model.renameMemoryItem(index: index, newName: editText)
                model.aux.mode = .memoryList
            }

            TypedRegister( text: textValue, size: .large ).padding( .leading, 0)
        }
    }
}


struct MemoryListView: View {
    @StateObject var model: CalculatorModel

    @Binding var rowIndex: Int
    
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
                            let name: String = prefix ?? "-name-"
                            
                            let color = prefix != nil ? Color("DisplayText") : Color(.gray)
                            
                            HStack {
                                // Memory name - tap to edit
                                Text(name).font(.footnote).bold().foregroundColor(color).listRowBackground(Color("List0"))
                                    .onTapGesture {
                                        rowIndex = index
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
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .background( Color("MemoryDisplay") )
        .border(Color("Frame"), width: 3)
    }
}


struct MacroListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                let list = model.aux.list
                
                VStack(spacing: 7) {
                    ForEach (list.indices, id: \.self) { x in
                        let op: MacroOp = list[x]
                        let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                        let txt = op.getRichText(model)

                        HStack {
                            RichText( line, size: .small )
                            RichText( txt, size: .small, weight: .bold )
                            Spacer()
                        }
                    }
                    .onChange( of: list.indices.count ) {
                        if list.count > 1 {
                            proxy.scrollTo( list.indices[list.endIndex - 1] )
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
    
    @State var rowIndex = 0

    var body: some View {
        switch model.aux.mode {
        case .memoryList:
            MemoryListView( model: model, rowIndex: $rowIndex )
            
        case .memoryDetail:
            MemoryDetailView( model: model, index: rowIndex)
                .frame( maxWidth: .infinity, maxHeight: .infinity)
                .background( Color("Display") )
                .border(Color("Frame"), width: 3)
            
        case .macroList:
            MacroListView( model: model )
                .frame( maxWidth: .infinity, maxHeight: .infinity)
                .background( Color("Display") )
                .border(Color("Frame"), width: 3)
        }
    }
}

