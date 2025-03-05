//
//  DotIndicatorView.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-04.
//
import SwiftUI


struct DotIndicatorView: View {
    
    @Binding var currentView: AuxDispView
    
    var body: some View {
        
        HStack( spacing: 10 ) {
            ForEach( AuxDispView.allCases ) { viewCode in
                let color = viewCode == currentView ? viewCode.theme.mainColor : Color("Background")
                
                Circle()
                    .fill( color )
                    .stroke(.gray, lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
