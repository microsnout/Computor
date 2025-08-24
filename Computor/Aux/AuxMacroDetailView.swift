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
        var symTag: SymbolTag = mr.symTag
        
        let symName  = symTag.getRichText()
        
        let kcFn: KeyCode? = model.kstate.keyMap.keyAssignment(symTag)
        
        let fnText = kcFn == nil ? "" : "F\(kcFn!.rawValue % 10)"
        
        VStack( spacing: 0 ) {
            let captionTxt = "Macro " + symName
            
            AuxHeaderView( theme: Theme.lightYellow ) {
                
                // Header bar definition
                HStack {
                    // Navigation Back button
                    Image( systemName: "chevron.left")
                        .padding( [.leading], 5 )
                        .onTapGesture {
                            if mr.isEmpty {
                                model.macroMod.deleteMacro()
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
                    
                    let modSymStr = model.macroMod.symStr
                    
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
//                            AssignedKeyPicker( model: model )
                            Spacer()
                        }
                        
                        // Module name
                        HStack( spacing: 0 ) {
                            RichText("ç{GrayText}Module:", size: .small, weight: .regular).padding( [.trailing], 5 )
                            RichText( "ƒ{0.9}ç{ModText}\(modSymStr)", size: .small, weight: .bold )
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
        
        // Macro Rename Sheet
        .sheet(isPresented: $editSheet) {
            
            MacroEditSheet( mr: mr, caption: mr.caption ?? "", model: model ) { newtxt in
                mr.caption = newtxt
                refreshView.toggle()
            }
        }
        
        // Macro Change Symbol
        .sheet( isPresented: $symbolSheet ) {
            
            VStack {
                NewSymbolPopup( tag: symTag ) { tag in
                    model.changeMacroSymbol(old: symTag, new: tag)
                    symTag = tag
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


struct MacroEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    var mr: MacroRec

    @State var caption: String

    @StateObject var model: CalculatorModel
    
    var scc: SheetContinuationClosure
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            SheetCollapsibleView( label: "={Symbol: }V_{cc}" ) {
                
                NewSymbolPopup( tag: mr.symTag ) { tag in
                    model.changeMacroSymbol(old: mr.symTag, new: tag)
                    mr.symTag = tag
                }
            }

            SheetTextField( label: "Caption:", placeholder: "-caption-", text: $caption )

            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.7), .fraction(0.9)] )
        .onSubmit {
            scc( caption )
            dismiss()
        }
    }
}
