//
//  AuxMacroListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


let psMacroDetail = PadSpec(
    keySpec: ksMemDetail,
    cols: 6,
    keys: [
        Key(.macroPlay, image: "play" ),
        Key(.macroStep, image: "playpause" ),
        Key(.macroStop, image: "stop" ),
        Key(.macroRename, "ƒ{0.8}Caption", size: 2),
    ]
)


struct MacroLibraryView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        
        // if we are recording OR there is a selected symbol, we are in detail view
        
        if model.aux.macroKey != SymbolTag(.null) || model.aux.recState != .none {

            // Detailed view of selected macro
            MacroDetailView(model: model)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
        else {
            // List of all available macros
            MacroListView(model: model)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
    }
}


struct MacroListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
        
        VStack {
            AuxHeaderView( theme: Theme.lightYellow ) {
                HStack {
                    Spacer()
                    RichText("Macro Library", size: .small, weight: .bold )
                    Spacer()
                    
                    // New macro creation button
                    Image( systemName: "plus")
                        .padding( [.trailing], 5 )
                        .onTapGesture {
                            model.aux.recState = .stop
                        }
                }
            }

            if model.state.memory.isEmpty {
                Spacer()
                VStack {
                    // Placeholder for empty memory list
                    Text("Macro List")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                Spacer()
            }
            else {
                ScrollView {
                    
                    LazyVStack {
                        
                        ForEach ( model.appState.macroTable, id: \.symTag ) { mr in
                            
                            
                            let sym = mr.symTag.getRichText()
                            let caption = mr.caption ?? "ç{GrayText}-caption-"
                            
                            VStack {
                                HStack {
                                    
                                    VStack( alignment: .leading, spacing: 0 ) {
                                        
                                        HStack {
                                            // Tag Symbol
                                            RichText( sym, size: .small, weight: .bold, design: .serif )
                                            
                                            // Caption text
                                            RichText( caption, size: .small, weight: .bold )
                                        }
                                        
                                        // Second line of row
                                        RichText( "2nd Line", size: .small, weight: .bold ).padding( [.leading], 20 )
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    // Button controls at right of rows
                                    HStack( spacing: 20 ) {
                                        Button( action: {  } ) {
                                            Image( systemName: "arrowshape.down" )
                                        }
                                        Button( action: {  } ) {
                                            Image( systemName: "trash" )
                                        }
                                    }.padding( [.trailing], 20 )
                                }
                                .onTapGesture {
                                    withAnimation {
                                        model.aux.macroKey = mr.symTag
                                        model.aux.macroSeq = mr.opSeq
                                    }
                                }
                            }
                            
                            Divider()
                        }
                    }
                    .padding( .horizontal, 0)
                    .padding( [.top], 0 )
                }
            }
        }
    }
}


struct MacroDetailView: View, KeyPressHandler {
    @StateObject var model: CalculatorModel
    
    @State private var renameSheet = false

    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        
        switch event.kc {
            
        case .macroRecord:
            model.aux.recState = .record
            
        case .macroRename:
            renameSheet = true
            
        default:
            break
        }
        return KeyPressResult.null
    }

    var body: some View {
        let symTag: SymbolTag = model.aux.macroKey
        
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
                        .padding( [.leading], 10 )
                        .onTapGesture {
                            withAnimation {
                                model.aux.macroKey = SymbolTag(.null)
                            }
                        }
                    
                    Spacer()
                    RichText(captionTxt, size: .small, weight: .bold )
                    Spacer()
                }
            }
            
            // Side by side views, macro op list and other fields
            HStack {
                
                // List of macro ops with line numbers
                VStack {
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            let list = model.aux.macroSeq
                            
                            VStack(spacing: 7) {
                                ForEach (list.indices, id: \.self) { x in
                                    let op: MacroOp = list[x]
                                    let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                                    let text = op.getRichText(model)
                                    
                                    HStack {
                                        RichText( line, size: .small )
                                        RichText( text, size: .small, weight: .bold )
                                        Spacer()
                                    }
                                }
                                .onChange( of: list.count ) {
                                    if list.count > 1 {
                                        proxy.scrollTo( list.indices[list.endIndex - 1] )
                                    }
                                }
                            }
                            .padding([.leading, .trailing], 20)
                            .padding([.top, .bottom], 10)
                        }
                    }
                    .frame( width: 150 )
                }
                
                // Right panel fields
                HStack {
                    let caption = model.aux.macroCap.isEmpty ? "ç{GrayText}-caption-" : model.aux.macroCap
                    
                    VStack( alignment: .leading, spacing: 10 ) {
                        
                        Spacer().frame( height: 5 )
                        
                        // CAPTION
                        RichText( "ƒ{1.2}ç{UnitText}\(caption)", size: .small, weight: .bold )
                        
                        // SYMBOL
                        HStack( spacing: 0 ) {
                            RichText("ç{GrayText}Symbol:", size: .small, weight: .regular).padding( [.trailing], 5 )
                            RichText( symName, size: .small, weight: .bold )
                            Spacer()
                        }
                        
                        // Assigned Key
                        HStack( spacing: 0 ) {
                            RichText("ç{GrayText}Assigned key:", size: .small, weight: .regular).padding( [.trailing], 5 )
                            RichText( fnText, size: .small, weight: .bold )
                            Spacer()
                        }

                        Spacer()
                    }
                    Spacer()
                }
                //.border(.red)
            }
            
            // Macro detail key menu
            KeypadView( padSpec: psMacroDetail, keyPressHandler: self)
        }
        .padding( [.bottom], 10 )
        .sheet(isPresented: $renameSheet) {
            ZStack {
                Color("ListBack").edgesIgnoringSafeArea(.all)
                AuxRenameView( name: model.aux.macroCap )
                {
                    model.aux.macroCap = $0
                    print($0)
                }
                    .presentationDetents([.fraction(0.4)])
                    .presentationBackground( Color("ListBack") )
            }
        }
    }
}


//struct MacroListView_Previews: PreviewProvider {
//    
//    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        
//        // FIX: MacroKey not working here, keys not defined yet?
//        newModel.aux.list = MacroOpSeq( [ MacroValue( tv: TaggedValue(.real, reg: 3.33)) ] )
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MacroListView_Previews.addSampleMacro( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    MacroListView( model: model)
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
