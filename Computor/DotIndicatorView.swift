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
                
                if viewCode == currentView {
                    Circle()
                        .fill( viewCode.theme.mediumColor )
                        .frame(width: 7, height: 7)
                }
                else {
                    
                    Circle()
                        .fill( Color("Background") )
                        .stroke( Color("Frame"), lineWidth: 1)
                        .frame(width: 7, height: 7)
                }
            }
        }
    }
}
