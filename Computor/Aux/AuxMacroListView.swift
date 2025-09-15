//
//  AuxMacroListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct AuxMacroView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        
        // if we are recording OR there is a selected symbol, we are in detail view
        
        if let mr = model.aux.macroRec {

            // Detailed view of selected macro
            MacroDetailView( mr: mr, model: model )
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
    
    @State private var deleteDialog = false
    
    @State private var dialogRec: MacroRec? = nil
    @State private var modSelSheet: Bool = false

    var body: some View {
        
        // Symbol for currently selected macro module
        let modSymStr = model.aux.macroMod.modSym
        
        VStack {
            AuxHeaderView( theme: Theme.lightYellow ) {
                HStack {
                    Spacer()
                    
                    // Macro List Header Title
                    Button( action: { modSelSheet = true } ) {
                        RichText("ç{GrayText}Macro Module:ç{} ƒ{0.9}\(modSymStr)", size: .small, weight: .bold, defaultColor: "ModText" )
                    }
                    Spacer()
                    
                    // New macro creation button
                    Image( systemName: "plus")
                        .foregroundColor( Color("AuxHeaderText") )
                        .padding( [.trailing], 5 )
                        .onTapGesture {
                            withAnimation {
                                model.createNewMacro()
                            }
                        }
                }
            }

            if model.aux.macroMod.symList.isEmpty {
                Spacer()
                VStack {
                    // Placeholder for empty macro list
                    Text("Macro List")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                Spacer()
            }
            else {
                ScrollView {
                    
                    LazyVStack {
                        
                        ForEach ( model.aux.macroMod.macroList ) { mr in
                            
                            let sym = mr.symTag.getRichText()
                            let caption = mr.caption ?? "ç{GrayText}-caption-"
                            let color = mr.caption != nil ? "UnitText" : "GrayText"
                            let kcKey = model.kstate.keyMap.keyAssignment(mr.symTag)
                            let key   = kcKey == nil ? "" : "F\(kcKey!.rawValue % 10)"

                            VStack {
                                HStack {
                                    
                                    VStack( alignment: .leading, spacing: 0 ) {
                                        
                                        HStack {
                                            // Tag Symbol
                                            RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )

                                            // Caption text
                                            RichText( caption, size: .normal, weight: .regular, design: .serif, defaultColor: color )
                                        }
                                        
                                        // Second line of row
                                        RichText( "ƒ{0.9}Key: ç{BlackText}\(key)", size: .small, weight: .heavy, design: .serif, defaultColor: "GrayText" ).padding([.leading], 10)
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    // Button controls at right of rows
                                    HStack( spacing: 20 ) {
                                        
                                        // PLAY
                                        Button( action: {  } ) {
                                            Image( systemName: "play" )
                                        }
                                        
                                        // DELETE
                                        Button( action: {
                                            deleteDialog = true
                                            dialogRec = mr
                                        } ) {
                                            Image( systemName: "trash" )
                                        }
                                        .confirmationDialog("Confirm Deletion", isPresented: $deleteDialog, presenting: dialogRec) { mr in
                                            
                                            Button("Delete", role: .destructive) {
                                                dialogRec = nil
                                                
                                                // Delete this sym from Aux mod
                                                model.aux.macroMod.deleteMacro( mr.symTag )
                                                
                                                // Clear a key assignment for this macro if any
                                                if let kcFn = model.kstate.keyMap.keyAssignment( mr.symTag ) {
                                                    model.kstate.keyMap.clearKeyAssignment(kcFn)
                                                }
                                            }
                                            
                                            Button("Cancel", role: .cancel) {
                                                // User cancelled, do nothing
                                                dialogRec = nil
                                            }
                                        }
                                        
                                    }.padding( [.trailing], 20 )
                                }
                                .contentShape(Rectangle()) 
                                .onTapGesture {
                                    withAnimation {
                                        model.aux.loadMacro(mr)
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
        .sheet( isPresented: $modSelSheet ) {
            
            // Choose a Module to display in Aux
            ModuleSelectSheet( model: model )
        }
    }
}


struct ModuleSelectSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            SheetHeaderText( txt: "Select Module:" )
            
            SelectModulePopup( db: model.db ) { mfc in
                
                // Set displayed module mfc
                model.aux.macroMod = mfc
                dismiss()
            }
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.5), .large] )
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
