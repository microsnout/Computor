//
//  AuxMacroDetailView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-20.
//
import SwiftUI


struct MacroDetailView: View {
    
    var mr: MacroRec
    
    @StateObject var model: CalculatorModel
    
    @State private var refreshView = false
    
    @State private var editSheet   = false

    var body: some View {
        let symTag: SymbolTag = mr.symTag
        
        let symName  = symTag.getRichText()
        
        let modSymName = model.aux.macroMod.name
        
        let modZero = modSymName == modZeroSym
        
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
                                model.db.deleteMacro( SymbolTag.Null, from: model.aux.macroMod)
                            }
                            
                            withAnimation {
                                model.aux.stopMacroRecorder()
                            }
                        }
                    
                    Spacer()
                    RichText(captionTxt, size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // PENCIL EDIT BUTTON
                        Button {
                            editSheet = true
                        } label: {
                            Image( systemName: "square.and.pencil")
                        }
                    }
                }
            }
            
            // Side by side views, macro op list and other fields
            HStack( spacing: 0 ) {
                
                // List of macro ops with line numbers
                MacroCodeListing( mr: mr, model: model )
                
                Divider()
                
                // Right panel fields
                MacroDetailRightPanel( mr: mr, model: model, refreshView: $refreshView )
            }
        }
        .padding( [.bottom, .leading, .trailing], 5 )
        
        // Macro Edit Sheet
        .sheet(isPresented: $editSheet) {
            
            MacroEditSheet( mr: mr, caption: mr.caption ?? "", model: model ) { newCaption in
                
                model.changeMacroCaption( to: newCaption, for: mr.symTag, in: model.aux.macroMod)
                refreshView.toggle()
            }
        }
    }
}


struct MacroCodeListing: View {
    
    /// ** Macro Code Listing **
    
    var mr: MacroRec
    
    @StateObject var model: CalculatorModel
    
    func getIndentList( _ opList: MacroOpSeq ) -> [Int] {
        
        var indent = 0
        
        var lastOpModal: Bool = false
        
        var iList: [Int] = []
        
        let modalKeyCodes: Set<KeyCode> = [.mapX, .mapXY, .reduce]
        
        for op in opList {
            
            iList.append(indent)
            
            if let mEvent = op as? MacroEvent {
                
                let evt = mEvent.event
                
                switch evt.kc {
                    
                case .lib:
                    if let tag = evt.mTag {
                        
                        if tag.isSysMod {
                            
                            if let lf = SystemLibrary.getLibFunction( for: tag ) {
                                
                                if lf.nModalParm > 0 {
                                    lastOpModal = true
                                    indent += 1
                                }
                            }
                        }
                    }

                case .openBrace:
                    lastOpModal = false
                    
                case .closeBrace:
                    lastOpModal = false
                    indent -= 1
                    
                default:
                    if modalKeyCodes.contains(evt.kc) {
                        lastOpModal = true
                        indent += 1
                    }
                    else {
                        if lastOpModal {
                            indent -= 1
                        }
                        lastOpModal = false
                    }
                }
            }
        }
        return iList
    }
    
    
    func getIndentStr( _ n: Int ) -> String {
        let str  = [Character]( repeating: "\u{00B7}", count: n )
        return String(str)
    }
    
    var body: some View {
        
        VStack {
            
            ScrollView {
                ScrollViewReader { proxy in
                    let list = mr.opSeq
                    let indents = getIndentList(list)
                    
                    VStack(spacing: 1) {
                        ForEach (list.indices, id: \.self) { x in
                            let op: MacroOp = list[x]
                            let level = indents[x]
                            let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                            let text = op.getRichText(model)
                            let indentStr = getIndentStr(level)
                            
                            HStack {
                                RichText( line, size: .small )
                                if level > 0 {
                                    RichText( "={\(indentStr)}", size: .small )
                                }
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
        .frame( width: Const.UI.auxCodeListingWidth )
        // .border(.blue)
        // .showSizes([.current])
    }
}


struct MacroDetailRightPanel: View {
    
    /// ** Macro Detail Right Panel **
    
    var mr: MacroRec
    
    @StateObject var model: CalculatorModel
    
    @State private var symbolSheet = false
    
    @Binding var refreshView: Bool
    

    var body: some View {
        let symTag: SymbolTag = mr.symTag
        
        let symName  = symTag.getRichText()
        
        let kcFn: KeyCode? = model.getKeyAssignment(for: symTag, in: model.aux.macroMod)
        
        let fnText = kcFn == nil ? "" : "F\(kcFn!.rawValue % 10)"

        HStack {
            let caption = mr.caption ?? "ç{GrayText}-caption-"
            
            let modSymStr = model.aux.macroMod.name
            
            VStack( alignment: .leading, spacing: 5 ) {
                
                Spacer().frame( height: 5 )
                
                // SYMBOL
                HStack( spacing: 0 ) {
                    RichText("ç{GrayText}Symbol:", size: .small, weight: .regular).padding( [.trailing], 5 )
                    RichText( symName, size: .small, weight: .bold )
                    Spacer()
                }.onTapGesture {
                    // TODO: Consider eliminating this symbol sheet
                    symbolSheet = true
                }
                
                // CAPTION
                RichText( "ç{UnitText}\(caption)", size: .small, weight: .medium )
                
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
                        _ = model.playMacroSeq( mr.opSeq, in: model.aux.macroMod )
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
        
        // .border(.red)
        // .showSizes([.current])
    }
}

