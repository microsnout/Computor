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
    @State private var editText = ""
    @FocusState private var nameFocused: Bool
    
    var index: Int
    var item: RowDataItem

    var body: some View {
        Form {
            TextField( "-Unnamed-", text: $editText )
            .focused($nameFocused)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .onAppear {
                if let name = item.prefix {
                    editText = name
                }
                nameFocused = true
            }
            .onSubmit {
                model.renameMemoryItem(index: index, newName: editText)
                model.aux.mode = .memoryList
            }

            TypedRegister( row: NoPrefix(item), size: .large ).padding( .leading, 0)
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
            let rows = model.state.memoryList
            
            if rows.isEmpty {
                Text("Memory List\n(Press + to store X register)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            else {
                List {
                    ForEach ( Array( rows.enumerated()), id: \.offset ) { index, item in
                        VStack( alignment: .leading, spacing: 0 ) {
                            let name = item.prefix != nil ? item.prefix! : "-name-"
                            
                            let color = item.prefix != nil ? Color("DisplayText") : Color(.gray)
                            
                            HStack {
                                // Memory name - tap to edit
                                Text(name).font(.footnote).bold().foregroundColor(color).listRowBackground(Color("List0"))
                                    .onTapGesture {
                                        rowIndex = index
                                        model.aux.mode = .memoryDetail
                                    }
                            }
                            
                            // Memory value display
                            TypedRegister( row: NoPrefix(item), size: .small ).padding( .horizontal, 20)
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
                            RichTextView(
                                inputStr: line,
                                bodyFont: .system( size: 12, weight: .regular, design: .serif),
                                subScriptFont: .system( size: 8, design: .default),
                                baseLine: 6.0,
                                defaultColor: "DisplayText")
                            
                            RichTextView(
                                inputStr: txt,
                                bodyFont: .system( size: 12, weight: .bold, design: .serif),
                                subScriptFont: .system( size: 8, weight: .bold, design: .default),
                                baseLine: 6.0,
                                defaultColor: "DisplayText")
                            
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
        let rows = model.state.memoryList
        
        switch model.aux.mode {
        case .memoryList:
            MemoryListView( model: model, rowIndex: $rowIndex )
            
        case .memoryDetail:
            MemoryDetailView( model: model, index: rowIndex, item: rows[rowIndex])
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

