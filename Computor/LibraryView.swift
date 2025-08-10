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
        
        
        List {
            Section ( header: SectionHeaderText( text: "MODULES" ) ) {
                
            }
            .listSectionSeparator(.hidden, edges: .top)
            .listSectionSeparatorTint( Color("AccentText"))

        }
        .listStyle( .grouped )
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
    }
}

//#Preview {
//    LibraryView()
//}
