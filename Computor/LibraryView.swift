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
        
        
        VStack {
            VStack {
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            }
            .frame( height: 80 )
            .frame( maxWidth: .infinity )
            .background(Color("SheetBack"))
            .cornerRadius( 12 , corners: UIRectCorner.bottomLeft.union(UIRectCorner.bottomRight) )

            Spacer()
        }
        .background(Color("PopBack"))
        .scrollContentBackground(.hidden)
    }
}

//#Preview {
//    LibraryView()
//}
