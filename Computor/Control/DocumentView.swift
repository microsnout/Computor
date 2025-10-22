//
//  DocumentView.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-21.
//

import SwiftUI


struct DocumentView: View {
    
    @Environment(\.dismiss) private var dismiss

    @StateObject var model: CalculatorModel
    
    // Open macro module edit sheet for adding or creating new modules
    @State private var addItem:    Bool = false
    @State private var saveItem:   Bool = false
    @State private var editItem:   DocumentRec? = nil
    
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: DocumentRec?
    
    @Binding var list: [DocumentRec]

    var body: some View {
        
        NavigationStack {
            VStack {
                
                List {
                    
                    ForEach ( list ) { (dfr: DocumentRec) in
                        
                        let caption =  (dfr.caption ?? "ç{GrayText}-caption-ç{}")
                        
                        VStack {
                            HStack {
                                
                                // Document name and caption
                                ZStack( alignment: .leadingFirstTextBaseline ) {
                                    RichText( dfr.name, size: .normal, weight: .bold, design: .monospaced, defaultColor: "BlackText" )
                                    RichText( caption, size: .normal, weight: .thin, design: .serif, defaultColor: "ModText" ).padding( [.leading], 60)
                                }
                                
                                Spacer()
                                
                                // LOAD - Calculator Icon to load this document
                                Button( action: { model.loadDocument(dfr.name); dismiss() } ) {
                                    Image( systemName: "candybarphone" )
                                }
                                .padding( [.trailing], 10 )
                                
                                // DOT DOT DOT ellipsis menu
                                DocumentActionMenu( editItem: $editItem, mfr: dfr )
                            }
                            .deleteDisabled( dfr.isObjZero )
                            
                            // Date Display
                            HStack {
                                RichText( dfr.dateCreated.formatted(date: .abbreviated, time: .omitted), size: .small, weight: .light, design: .default, defaultColor: "BlackText" )
                                Spacer()
                            }
                        }
                    }
                    .onMove { fromOffsets, toOffset in
                        
                        // Re-arrange macro module list
                        list.move( fromOffsets: fromOffsets, toOffset: toOffset)
                    }
                    .onDelete { offsets in
                        
                        // Pop up confirmation dialog
                        itemToDelete = list[offsets.first!]
                        showingDeleteConfirmation = true
                    }
                    .alert( "Delete \(itemToDelete?.name ?? "item")?", isPresented: $showingDeleteConfirmation ) {
                        
                        Button("Delete", role: .destructive) {
                            if let item = itemToDelete {
                                // Perform the actual deletion here (e.g., remove from array, Core Data, SwiftData)
                                // Example for array: items.removeAll(where: { $0.id == item.id })
                                
                                // model.db.docTable.objTable.removeAll( where: $0.name == item.name )
                                
                                model.db.deleteDocument(item)
                            }
                            itemToDelete = nil // Clear the item to delete
                        }
                        
                        Button("Cancel", role: .cancel) {
                            itemToDelete = nil // Clear the item to delete
                        }
                    }
                    
                    // SAVE AS
                    Button( action: { saveItem = true } ) {
                        HStack {
                            Image( systemName: "document.circle" )
                                .foregroundColor( Color("ModText") )
                            
                            RichText( "Save Document As..", size: .small, weight: .bold, design: .monospaced, defaultColor: "ModText" )
                            Spacer()
                        }
                    }

                    // ADD NEW
                    Button( action: { addItem = true } ) {
                        HStack {
                            Image( systemName: "plus.circle" )
                                .foregroundColor( Color("ModText") )
                            
                            RichText( "New Calculator Document", size: .small, weight: .bold, design: .monospaced, defaultColor: "ModText" )
                            Spacer()
                        }
                    }

                }
                .listStyle(.grouped)
                
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SectionHeaderText( text: "Calculator Documents" )
                }
                
                ToolbarItem( placement: .topBarTrailing ) {
                    EditButton()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding()
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
        
        // Save current module to..
        .sheet( isPresented: $saveItem ) {
            
            EditModuleSheet( submitLabel: "Save" ) { (name: String, caption: String) in
                
                if model.activeDocName == docZeroSym {
                    
                    if let docRec = model.db.getDocumentFileRec( name: model.activeDocName ) {
                        
                        model.db.setDocumentSymbolandCaption( docRec, newSym: name, newCaption: caption.isEmpty ? nil : caption )
                        
                        model.activeDocName = name
                        
                        _ = model.db.getDocZero()
                        
                        dismiss()
                    }
                }
            }
        }

        // Add a new macro module
        .sheet( isPresented: $addItem ) {
            
            EditModuleSheet( submitLabel: "Create" ) { (name: String, caption: String) in
                
                _ = model.db.createNewDocument(symbol: name, caption: caption.isEmpty ? nil : caption )
            }
        }
        
        // Edit name and caption of macro module
        .sheet( item: $editItem ) { (dfr: DocumentRec) in
            
            EditModuleSheet( editName: dfr.name , editCaption: dfr.caption ?? "", submitLabel: "Save" ) { (newName: String, newCaption: String) in
                
                model.db.setDocumentSymbolandCaption( dfr, newSym: newName, newCaption: newCaption.isEmpty ? nil : newCaption )
            }
        }
        
    }
}


struct DocumentActionMenu: View {
    
    @Binding var editItem: DocumentRec?
    
    var mfr: DocumentRec
    
    var body: some View {
        
        Menu {
            
            // EDIT
            Button {
                // Open module edit sheet
                editItem = mfr
            }
            label: {
                Label( "Edit name and caption", systemImage: "pencil")
            }
            
            // SHARE
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
        .disabled( mfr.isDocZero )
    }
}
