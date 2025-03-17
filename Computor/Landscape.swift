//
//  Landscape.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-15.
//
import SwiftUI


struct LandscapeView : View {
    
    @StateObject var model: CalculatorModel

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            KeyStack( keyPressHandler: model ) {
                
                VStack( spacing: 0 ) {
                    AuxiliaryDisplayView( model: model, auxView: $model.aux.activeView )
                    
                    DotIndicatorView( currentView: $model.aux.activeView )
                        .padding( .top, 4 )
                        .frame( maxHeight: 8)
                }
            }
        }
    }
}
