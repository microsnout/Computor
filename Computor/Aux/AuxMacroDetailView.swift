//
//  AuxMacroDetailView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-20.
//
import SwiftUI


struct FnKeyItem: Identifiable {
    let id = UUID()
    let kcFn: KeyCode
}


struct AssignedKeyPicker: View {

    @StateObject var model: CalculatorModel
    
    @State private var kcSelected: KeyCode = .null
    
    
    func getKeyList( _ map: KeyMapRec ) -> [FnKeyItem] {
        
        let kcAll: [KeyCode] = [.F1, .F2, .F3, .F4, .F5, .F6]
        
        return kcAll.map { kc in
            FnKeyItem( kcFn: kc )
        }
    }

    
    var body: some View {
        
        let keyList: [FnKeyItem] = getKeyList( model.kstate.keyMap )
        
        Picker( selection: $kcSelected, label: Text("Key:").font(.footnote) ) {
            
            ForEach( keyList ) { key in
                Text(key.kcFn.str).font(.footnote).tag(key.kcFn)
            }
        }
        .pickerStyle(.menu)
        .font(.footnote)
    }
}


struct MacroDetailView: View {
    
    var mr: MacroRec
    
    @StateObject var model: CalculatorModel
    
    @State private var editSheet   = false
    
    @State private var symbolSheet = false
    
    @State private var refreshView = false
    
    var body: some View {
        let symTag: SymbolTag = mr.symTag
        
        let symName  = symTag.getRichText()
        
        let modSymName = model.aux.macroMod.modSym
        
        let modZero = modSymName == modZeroSym
        
        let kcFn: KeyCode? = model.getKeyAssignment(for: symTag, in: model.aux.macroMod)
        
        let fnText = kcFn == nil ? "" : "F\(kcFn!.rawValue % 10)"
        
        VStack( spacing: 0 ) {
            let captionTxt = modZero ? "\(symName)" : "\(modSymName)ç{ModText}/ç{}\(symName)"
            
            AuxHeaderView( theme: Theme.lightYellow ) {
                
                // Header bar definition
                HStack {
                    // Navigation Back button
                    Image( systemName: "chevron.left")
                        .padding( [.leading], 5 )
                        .onTapGesture {
                            if mr.isEmpty {
                                model.db.deleteMacro( SymbolTag(.null), from: model.aux.macroMod)
                            }
                            
                            withAnimation {
                                model.aux.clearMacroState()
                            }
                        }
                    
                    Spacer()
                    RichText(captionTxt, size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                }
            }
            
            // Side by side views, macro op list and other fields
            HStack( spacing: 0 ) {
                
                // List of macro ops with line numbers
                VStack {
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            let list = mr.opSeq
                            
                            VStack(spacing: 1) {
                                ForEach (list.indices, id: \.self) { x in
                                    let op: MacroOp = list[x]
                                    let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                                    let text = op.getRichText(model)
                                    
                                    HStack {
                                        RichText( line, size: .small )
                                        RichText( text, size: .small, weight: .bold )
                                        Spacer()
                                    }
                                    .frame( height: 18 )
                                    .frame( maxWidth: .infinity )
                                    .if ( isEven(x+1) ) { view in
                                        view.background( Color("SuperLightGray") )
                                    }
                                }
                                .onChange( of: list.count ) {
                                    if list.count > 1 {
                                        proxy.scrollTo( list.indices[list.endIndex - 1] )
                                    }
                                }
                            }
                            .padding([.leading, .trailing], 2)
                            .padding([.top, .bottom], 10)
                        }
                    }
                }
                .frame( width: 150 )
                // .border(.blue)
                // .showSizes([.current])
                
                Divider()
                
                // Right panel fields
                HStack {
                    let caption = mr.caption ?? "ç{GrayText}-caption-"
                    
                    let modSymStr = model.aux.macroMod.modSym
                    
                    VStack( alignment: .leading, spacing: 10 ) {
                        
                        Spacer().frame( height: 5 )
                        
                        // SYMBOL
                        HStack( spacing: 0 ) {
                            RichText("ç{GrayText}Symbol:", size: .small, weight: .regular).padding( [.trailing], 5 )
                            RichText( symName, size: .small, weight: .bold )
                            Spacer()
                            
                            // PENCIL EDIT BUTTON
                            Button {
                                editSheet = true
                            } label: {
                                Image( systemName: "square.and.pencil")
                            }
                        }.onTapGesture {
                            symbolSheet = true
                        }
                        
                        // CAPTION
                        RichText( "ƒ{1.2}ç{UnitText}\(caption)", size: .small, weight: .bold )
                            .onTapGesture {
                                editSheet = true
                            }

                        // Assigned Key
                        HStack( spacing: 0 ) {
                            RichText("ç{GrayText}Key:", size: .small, weight: .regular).padding( [.trailing], 5 )
                            RichText( fnText, size: .small, weight: .bold )
                            Spacer()
                        }
                        
                        // Module name
                        HStack( spacing: 0 ) {
                            RichText("ç{GrayText}Module:", size: .small, weight: .regular).padding( [.trailing], 5 )
                            RichText( "ƒ{0.9} \(modSymStr)", size: .small, weight: .bold )
                            Spacer()
                        }
                        
                        Spacer()
                        
                        // RECORDING EDIT CONTROLS
                        HStack( spacing: 25 ) {
                            
                            // RECORD
                            Button {
                                _ = model.keyPress( KeyEvent(.macroRecord) )
                            } label: {
                                Image( systemName: "record.circle.fill").frame( minWidth: 0 )
                            }
                            .accentColor( Color("RedMenuIcon") )
                            .disabled( model.aux.recState != .stop )
                            
                            // PLAY
                            Button {
                                _ = model.playMacroSeq( mr.opSeq )
                            } label: {
                                Image( systemName: "play.fill").frame( minWidth: 0 )
                            }
                            .disabled( model.aux.recState != .stop || model.aux.macroRec?.opSeq.isEmpty ?? true )
                            
                            // STOP
                            Button {
                                _ = model.keyPress( KeyEvent(.macroStop) )
                            } label: {
                                Image( systemName: "stop.fill").frame( minWidth: 0 )
                            }
                            .disabled( !model.aux.recState.isRecording  )
                            
                        }
                        .frame( maxWidth: .infinity )
                        .padding( [.bottom], 5 )
                    }
                    Spacer()
                }
                .id(refreshView)
                .padding( [.leading], 10)
                // .border(.red)
                // .showSizes([.current])
            }
        }
        .padding( [.bottom, .leading, .trailing], 5 )
        
        // Macro Edit Sheet
        .sheet(isPresented: $editSheet) {
            
            MacroEditSheet( mr: mr, caption: mr.caption ?? "", model: model ) { newtxt in
                mr.caption = newtxt
                refreshView.toggle()
            }
        }
        
        // Symbol Change Symbol
        .sheet( isPresented: $symbolSheet ) {
            
            VStack {
                NewSymbolPopup( tag: symTag ) { tag in
                    model.changeMacroSymbol(old: symTag, new: tag)
                    symbolSheet = false
                    refreshView.toggle()
                }
            }
            .presentationDetents([.fraction(0.5)])
            .presentationBackground( Color("ControlBack") )
        }
    }
}


struct SheetHeaderText: View {
    
    var txt: String
    
    var body: some View {
        
        RichText( "ƒ{1.2}\(txt)", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
            .padding( [.top], 10 )
    }
}


struct SheetTextField: View {
    
    var label: String
    
    var placeholder: String
    
    @Binding var text: String
    
    var body: some View {
        
        VStack( alignment: .leading, spacing: 5 ) {
            SheetHeaderText( txt: label )
            
            TextField( placeholder, text: $text )
                .textFieldStyle(.roundedBorder)
                .padding( [.top], 0)
                .foregroundColor(.black)
        }
    }
}


typealias SheetContinuationClosure = ( _ str: String ) -> Void


struct SheetCollapsibleView<Content: View>: View {
    
    var label: String
    
    @ViewBuilder var content: Content
    
    @State private var isCollapsed = true
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            HStack {
                RichText( "ƒ{1.2}\(label)", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                
                Spacer()
                
                Button( "", systemImage: isCollapsed ? "chevron.down" : "chevron.up" ) {
                    
                    withAnimation {
                        isCollapsed.toggle()
                    }
                }
            }
            .padding(0)
            
            if !isCollapsed {
                content
                    .transition( .asymmetric( insertion: .push(from: .top), removal: .push( from: .bottom)) )
            }
            
            Divider()
                .overlay( Color(.white))
        }
        .accentColor( Color("WhiteText") )
        .padding([.top], 10)
    }
}


typealias KeyCodeContinuationClosure = ( _ kc: KeyCode ) -> Void


struct KeyAssignPopup: View, KeyPressHandler {
    
    var tag: SymbolTag
    var kccc: KeyCodeContinuationClosure
    
    @State private var kcAssigned: KeyCode = .null

    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        
        kcAssigned = event.kc
        kccc( event.kc )
        return KeyPressResult.noOp
    }
    
    var body: some View {
        
        VStack( alignment: .center ) {
            
            KeypadView( padSpec: psFnUn, keyPressHandler: self )
                .padding( [.leading, .trailing, .bottom, .top] )
        }
        .frame( maxWidth: .infinity )
        .accentColor( .black )
        .onAppear() {
            kcAssigned = tag.kc
        }
        .background() {
            
            Color( "SuperLightGray")
                .cornerRadius(10)
                .padding( [.leading, .trailing], 20 )
                .padding( [.top], 5 )
                .padding( [.bottom], 0 )
        }
    }
}


struct MacroMoveRec {
    
    var targetMod: String
}


struct MacroEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    var mr: MacroRec

    @State var caption: String

    @StateObject var model: CalculatorModel
    
    var scc: SheetContinuationClosure
    
    @State private var symName: String = ""
    
    @State private var kcAssigned: KeyCode? = nil
    
    @State private var moveDialog = false
    @State private var moveRec = MacroMoveRec( targetMod: "")

    var body: some View {
        
        let kcStr: String = kcAssigned?.str ?? ""
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
            }
            .padding( [.top], 5 )
            
            // Symbol Editor
            SheetCollapsibleView( label: "={Symbol: }\(symName)" ) {
                
                NewSymbolPopup( tag: mr.symTag ) { tag in
                    model.changeMacroSymbol(old: mr.symTag, new: tag)
                    symName = mr.symTag.getRichText()
                }
            }
            
            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: "-caption-", text: $caption )
            
            // Assigned Key Editor
            SheetCollapsibleView( label: "={Assigned Key: }\(kcStr)" ) {
                
                KeyAssignPopup( tag: mr.symTag ) { kc in
                    
                    // Update state variable to display key
                    kcAssigned = kc
                    
                    // If macroMod is mod0 this will not change the tag
                    let remTag = model.db.getRemoteSymbolTag( for: mr.symTag, to: model.aux.macroMod )
                    
                    model.assignKeyTo( kc, tag: remTag )
                }
            }
            
            // Module Editor
            SheetCollapsibleView( label: "={Module: }" ) {
                
                SelectModulePopup( db: model.db ) { mfc in
                    
                    moveRec = MacroMoveRec( targetMod: mfc.modSym )
                    moveDialog = true
                }
            }
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.8), .large] )
        .onAppear() {
            symName = mr.symTag.getRichText()
            kcAssigned = model.kstate.keyMap.keyAssignment(mr.symTag)
        }
        .onSubmit {
            scc( caption )
            dismiss()
        }
        .confirmationDialog("Confirm Deletion", isPresented: $moveDialog, presenting: moveRec ) { mmr in
            
            Button("Move to Module: \(mmr.targetMod)") {
                //moveDialog = false
            }
            
            Button("Copy to Module: \(mmr.targetMod)") {
                //moveDialog = false
            }
            
            
            Button("Cancel", role: .cancel) {
                //moveDialog = false
            }
        }
    }
}


// **************


struct ModuleKeyView: View {
    
    /// A view of a single module key
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    let modSym: String
    let keySpec: KeySpec
    
    var body: some View {
        
        let keyW = keySpec.width
        
        VStack {
            
            Rectangle()
                .foregroundColor( Color(keySpec.keyColor) )
                .frame( width: keyW, height: keySpec.height )
                .cornerRadius( keySpec.radius )
                .overlay(
                    RichText( modSym, size: .normal, weight: .regular, defaultColor: keySpec.textColor)
                )
        }
        .frame( width: keyW, height: keySpec.height )
    }
}


typealias ModSelectClosure = ( _ mfr: ModuleFileRec ) -> Void


struct SelectModulePopup: View {
    
    /// Select from list of existing symbol tags, could be memories or macros
    
    @EnvironmentObject var model: CalculatorModel
    @EnvironmentObject var keyData: KeyData

    let keySpec: KeySpec = ksModuleKey
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Parameters
    var db: Database
    
    var msc: ModSelectClosure
    
    var body: some View {
        
        let modRowList: [[ModuleFileRec]] = db.indexFile.mfileTable.chunked(into: 3)
        
        VStack( alignment: .center, spacing: 0) {
            
            ScrollView( [.vertical] ) {
                
                VStack( alignment: .center ) {
                    Grid {
                        
                        ForEach ( modRowList.indices, id: \.self ) { r in
                            
                            let row = modRowList[r]
                            
                            GridRow {
                                
                                let n = row.count
                                
                                ForEach ( row.indices, id: \.self ) { c in
                                    
                                    let sym = row[c].modSym
                                    
                                    ModuleKeyView( modSym: sym, keySpec: keySpec )
                                        .onTapGesture {
                                            hapticFeedback.impactOccurred()
                                            
                                            msc( row[c] )
                                            
                                        }
                                }
                                
                                // Pad the row to 4 col so the frame doesn't shrink
                                if n < 3 {
                                    ForEach ( 1 ... 3-n, id: \.self ) { _ in
                                        Color.clear
                                            .frame( width: keySpec.width, height: keySpec.height )
                                    }
                                }
                            }
                            .padding( .top, 5 )
                        }
                    }
                }
                .padding( 15)
            }
            .accentColor( .black )
            .background() {
                
                Color( "SuperLightGray")
                    .cornerRadius(10)
                    .padding( [.leading, .trailing], 0 )
                    .padding( [.top, .bottom], 5 )
            }
        }
        .frame( maxWidth: .infinity )
        .padding( [.leading, .trailing], 20 )

//        .frame( maxHeight: 340 )
    }
}

