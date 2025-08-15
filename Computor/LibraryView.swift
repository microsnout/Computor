//
//  LibraryView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-01.
//

import SwiftUI

struct LibraryView: View {
    
    @StateObject var model: CalculatorModel

    var body: some View {
        
        NavigationStack {
            List {
                
                ForEach ( model.libRec.index.macroTable ) { modFileRec in
                    let caption = modFileRec.caption ?? "-caption"
                    
                    VStack( alignment: .leading ) {
                        Text( modFileRec.symbol )
                        Text( caption )
                    }
                }
                
                HStack {
                    Image( systemName: "plus.circle" )
                        .foregroundColor( .blue )
                    
                    Text( "Add Macro Module")
                    Spacer()
                }
                
            }
            .listStyle( .grouped )
            .navigationTitle("Macro Modules")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)

    }
}

//#Preview {
//    LibraryView()
//}
