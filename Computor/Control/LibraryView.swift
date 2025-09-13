//
//  LibraryView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-01.
//

import SwiftUI


struct LibraryView: View {
    
    @StateObject var model: CalculatorModel
    
    // Open macro module edit sheet for adding or creating new modules
    @State private var addItem:    Bool = false
    @State private var editItem:   MacroFileRec? = nil
    
    @Binding var list: [MacroFileRec]
    
    var body: some View {
        
        NavigationStack {
            VStack {
                List {
                    
                    ForEach ( list ) { mfr in

                        let caption =  mfr.isModZero ? "" : (mfr.caption ?? "ç{GrayText}-caption-ç{}")
                        
                        HStack {
                            ZStack( alignment: .leadingFirstTextBaseline ) {
                                RichText( mfr.modSym, size: .normal, weight: .bold, design: .monospaced, defaultColor: "BlackText" )
                                RichText( caption, size: .normal, weight: .thin, design: .serif, defaultColor: "ModText" ).padding( [.leading], 60)
                            }
                            
                            Spacer()
                            
                            // DOT DOT DOT ellipsis menu
                            ActionMenu( editItem: $editItem, mfr: mfr )
                        }
                        .deleteDisabled( mfr.isModZero )
                    }
                    .onMove { fromOffsets, toOffset in
                        // Re-arrange macro module list
                        list.move(fromOffsets: fromOffsets, toOffset: toOffset)
                    }
                    .onDelete( perform: deleteItems)

                    // Add new module button is part of list
                    Button( action: { addItem = true } ) {
                        HStack {
                            Image( systemName: "plus.circle" )
                                .foregroundColor( Color("ModText") )
                            
                            RichText( "Add Macro Module", size: .small, weight: .bold, design: .monospaced, defaultColor: "ModText" )
                            Spacer()
                        }
                    }
                    
                }
                .listStyle(.grouped)
                
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SectionHeaderText( text: "Macro Modules" )
                }
                
                ToolbarItem( placement: .topBarTrailing ) {
                    EditButton()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
        
        // Add a new macro module
        .sheet( isPresented: $addItem ) {
            
            EditModuleSheet( submitLabel: "Create" ) { (name: String, caption: String) in
                
                if let mfr = model.db.createNewMacroFile(symbol: name) {
                    
                    mfr.caption = caption.isEmpty ? nil : caption
                    mfr.mfile = ModuleFile(mfr)
                    
                    // Save new mod file - index will be saved by on change handler
                    model.db.saveModule(mfr)
                }
            }
        }
        
        // Edit name and caption of macro module
        .sheet( item: $editItem ) { (mfr: MacroFileRec) in
            
            EditModuleSheet( editName: mfr.modSym , editCaption: mfr.caption ?? "", submitLabel: "Save" ) { (newName: String, newCaption: String) in
                
                model.setModuleSymbolandCaption( mfr, newSym: newName, newCaption: newCaption.isEmpty ? nil : newCaption )
            }
        }
        
        .onChange( of: list ) { oldList, newList in
            
            // Module file index has changed
            model.db.saveIndex()
            
#if DEBUG
            print("   Wrote index file:")
            for mfr in newList {
                print( "   \(mfr.modSym)")
            }
#endif
        }
    }
    
    
    func deleteItems( at offsets: IndexSet) {
        
        for index in offsets {
            
            // Delete the Mod file
            let mfr = list[index]
            model.deleteModule(mfr)
        }
        
        // Then remove the mfr rec from index file
        list.remove( atOffsets: offsets)
    }
}


struct ActionMenu: View {
    
    @Binding var editItem: MacroFileRec?
    
    var mfr: MacroFileRec
    
    var body: some View {
        Menu {
            Button {
                // Open module edit sheet
                editItem = mfr
            }
            label: {
                Label( "Edit symbol and caption", systemImage: "pencil")
            }
            
            Button {
                // No implementation yet
            }
            label: {
                Label( "Share module", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        label: {
            Label("", systemImage: "ellipsis")
        }
        .disabled( mfr.isModZero )
    }
}


struct EditModuleSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var editName: String = ""
    @State var editCaption: String = ""
    
    var submitLabel: String
    
    @FocusState private var nameFocus: Bool
    
    var cc: ( String, String ) -> Void
    
    var body: some View {
        
        VStack( alignment: .leading, spacing: 0 ) {
            
            Text("Name:")
                .focused( $nameFocus )
                .foregroundColor(.white)
                .background( Color.clear )
                .padding( [.leading, .top], 20 )
            
            
            TextField( "-Name-", text: $editName )
                .font(.system(size: 18).monospaced())
                .textInputAutocapitalization(.characters)
                .textCase(.uppercase)
                .disableAutocorrection(true)
                .onAppear {
                    // if let name = value.caption {
                    //     editName = name
                    // }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 ) {
                        nameFocus = true
                    }
                }
                .onChange(of: editName) { oldValue, newValue in
                    let list = Array(newValue)
                    
                    if list.count == 1 && list[0].isNumber {
                        // Don't allow names beginning with digits
                        editName = ""
                    }
                    else {
                        // Filter out all chars except letters and digits, limit length to 6
                        editName = String( list.filter( { $0.isLetter || $0.isNumber } ).prefix(6) ).uppercased()
                    }
                }
                .frame( maxWidth: 100 )
                .textFieldStyle(.roundedBorder)
                .padding( [.leading, .trailing], 20 )
                .padding( [.top], 10)
                .foregroundColor(.black)
            
            Text("Caption:")
                .foregroundColor(.white)
                .background( Color.clear )
                .padding( [.leading, .top], 20 )
            
            
            TextField( "-Caption-", text: $editCaption )
                .textFieldStyle(.roundedBorder)
                .padding( [.leading, .trailing], 20 )
                .padding( [.top], 10)
                .foregroundColor(.black)
            
            Text( "Enter module name, up to 6 characters, letters or numbers. Caption is an optional description of module." )
                .foregroundColor(.white)
                .background( Color.clear )
                .padding( [.top], 30 )
                .padding( [.leading, .trailing], 40 )
            
            HStack {
                Spacer()
                
                // CANCEL
                Button( action: { editName = ""; editCaption = ""; dismiss() } ) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .background( Color.clear )
                }
                Spacer()
                
                // CREATE
                Button( action: { cc(editName, editCaption); dismiss() } ) {
                    Text(submitLabel)
                        .foregroundColor( editName.count > 0 ? .white : Color("GrayText"))
                        .background( Color.clear )
                }
                .disabled( editName.count == 0 )
                Spacer()
            }
            .padding( [.top], 30 )
            
            Spacer()
        }
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.5)] )
    }
}
