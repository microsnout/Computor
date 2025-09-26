//
//  DocumentView.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-21.
//

import SwiftUI


struct DocumentView: View {
    
    @StateObject var model: CalculatorModel
    
    // Open macro module edit sheet for adding or creating new modules
    @State private var addItem:    Bool = false
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
                        
                        HStack {
                            ZStack( alignment: .leadingFirstTextBaseline ) {
                                RichText( dfr.name, size: .normal, weight: .bold, design: .monospaced, defaultColor: "BlackText" )
                                RichText( caption, size: .normal, weight: .thin, design: .serif, defaultColor: "ModText" ).padding( [.leading], 60)
                            }
                            
                            Spacer()
                            
                            // DOT DOT DOT ellipsis menu
                            // ActionMenu( editItem: $editItem, dfr: mfr )
                        }
                        .deleteDisabled( dfr.isObjZero )
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
                    
                    // Add new module button is part of list
                    Button( action: { addItem = true } ) {
                        HStack {
                            Image( systemName: "plus.circle" )
                                .foregroundColor( Color("ModText") )
                            
                            RichText( "Add Calculator Document", size: .small, weight: .bold, design: .monospaced, defaultColor: "ModText" )
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
        
        // Add a new macro module
        .sheet( isPresented: $addItem ) {
            
            EditModuleSheet( submitLabel: "Create" ) { (name: String, caption: String) in
                
                if let dfr = model.db.createNewDocument(symbol: name) {

                    dfr.caption = caption.isEmpty ? nil : caption

                    // Save new mod file - index will be saved by on change handler
                    model.db.saveDocument(dfr)
                }
            }
        }
        
        // Edit name and caption of macro module
        .sheet( item: $editItem ) { (dfr: DocumentRec) in
            
            EditModuleSheet( editName: dfr.name , editCaption: dfr.caption ?? "", submitLabel: "Save" ) { (newName: String, newCaption: String) in
                
                model.db.setDocumentSymbolandCaption( dfr, newSym: newName, newCaption: newCaption.isEmpty ? nil : newCaption )
            }
        }
        
//        .onChange( of: model.db.docTable.objTable) { oldList, newList in
//
//            // Module file index has changed
//            model.db.saveIndex()
//            
//#if DEBUG
//            print("   Wrote index file:")
//            for dfr in newList {
//                print( "   \(dfr.docSym)")
//            }
//#endif
//        }
    }
    
    
    func deleteItems( at offsets: IndexSet) {
        
        list.remove(atOffsets: offsets)
        
//        for index in offsets {
//            
//            // Delete the Mod file
//            let dfr = list[index]
//            
//            model.db.deleteDocument(dfr)
//        }
    }
}
