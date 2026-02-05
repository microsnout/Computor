//
//  Landscape.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-15.
//
import SwiftUI


struct LandscapeView : View {
    
    @Environment(CalculatorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        
        ZStack {
            Color( Color("SafeBack") )
                .edgesIgnoringSafeArea( .all )
            
            Rectangle()
                .fill(Color("Background"))
                .cornerRadius(15)
                .padding( [.leading, .trailing], 15 )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black, lineWidth: 1)
                        .padding( [.leading, .trailing], 15 )
                )
            
            KeyStack( keyPressHandler: model ) {
                
                VStack( spacing: 0 ) {
                    AuxiliaryDisplayView( auxView: $model.aux.activeView )
                    
                    DotIndicatorView( currentView: $model.aux.activeView )
                        .padding( .top, 4 )
                        .frame( maxHeight: 8)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 5)
                .background( Color("Background"))
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
