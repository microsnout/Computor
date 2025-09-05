//
//  LibraryView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-01.
//

import SwiftUI

struct LibraryView: View {
    
    @StateObject var model: CalculatorModel
    
    @State private var addItem: Bool = false
    
    var body: some View {
        
        NavigationStack {
            List {
                
                ForEach ( model.db.indexFile.macroTable ) { mfr in
                    
                    let caption = mfr.caption ?? "ç{GrayText}-caption-ç{}"
                    
                    VStack {
                        ZStack( alignment: .leadingFirstTextBaseline ) {
                            RichText( mfr.modSym, size: .normal, weight: .bold, design: .monospaced, defaultColor: "BlackText" )
                            RichText( caption, size: .normal, weight: .thin, design: .serif, defaultColor: "ModText" ).padding( [.leading], 60)
                        }
                    }
                }
                
                Button( action: { addItem.toggle() } ) {
                    HStack {
                        Image( systemName: "plus.circle" )
                            .foregroundColor( Color("ModText") )
                        
                        RichText( "Add Macro Module", size: .small, weight: .bold, design: .monospaced, defaultColor: "ModText" )
                        Spacer()
                    }
                }
                
            }
            .listStyle( .grouped )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Macro Modules")
                        .font(.system( .title3, design: .monospaced ))
                        .bold()
                        .foregroundColor( Color("AccentText") )
                        .padding(.vertical, 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
        .sheet( isPresented: $addItem ) {
            
            CreateModuleSheet() { name, caption in
                
                if let mfr = model.db.createNewMacroFile(symbol: name) {
                    
                    
                }
            }
        }
    }
}


struct CreateModuleSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var editName: String = ""
    @State private var editCaption: String = ""
    
    var cc: ( String, String ) -> Void
    
    var body: some View {
        
        VStack( alignment: .leading, spacing: 0 ) {
            
            Text("Name:")
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
                    Text("Create")
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

//#Preview {
//    LibraryView()
//}
