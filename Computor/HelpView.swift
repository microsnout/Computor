//
//  HelpView.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-10.
//

import SwiftUI

struct HelpView: View {
    
    @State private var page = "root"
    
    @State private var pageText: String = ""
    
    
    var body: some View {
        
        VStack {
            HStack {
                Button( action: {  } ) {
                    Image( systemName: "house" )
                }
                Button( action: {  } ) {
                    Image( systemName: "arrowshape.backward" )
                }
                Button( action: {  } ) {
                    Image( systemName: "arrowshape.forward" )
                }
                
                Spacer()

            }
            .frame( height: 40 )
            
            ScrollView {
                VStack {
                    
                    Text( LocalizedStringKey(pageText) )
                        .environment( \.openURL, .init( handler: { url in
                            print( url )
                            page = url.path()
                            return .handled
                        }))
//                        .tint( Color("Frame"))
                                      
                }
                .padding()
                .frame( maxWidth: .infinity, maxHeight: .infinity)
            }
            .background( Color("Display") )
            .border( Color("Frame"), width: 3)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ListBack"))
        .scrollContentBackground(.hidden)
        .onChange( of: page, initial: true ) {
            
            if let fileURL = Bundle.main.url( forResource: page, withExtension: "md") {
                
                do {
                    let fileContents = try String( contentsOf: fileURL, encoding: .utf8 )
                    pageText = fileContents
                }
                catch {
                    print("Error loading file contents: \(error.localizedDescription)")
                }
                
            } else {
                // File not found in the bundle
                print("Error: \(page).md not found in bundle.")
            }
        }
    }
}


#Preview {
    HelpView()
}
