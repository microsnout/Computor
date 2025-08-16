//
//  ControlView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-01.
//

import SwiftUI

struct ControlView: View {
    
    @StateObject var model: CalculatorModel

    var body: some View {
        
        TabView {
            
            LibraryView( model: model )
                .tabItem {
                    Label( "Modules", systemImage: "book.pages" )
                }
                .toolbarBackground( Color("Background"), for: .tabBar)
                .toolbarBackgroundVisibility(.visible, for: .tabBar)
            
            SettingsView()
                .tabItem {
                    Label( "Settings", systemImage: "slider.horizontal.3" )
                }
                .toolbarBackground( Color("Background"), for: .tabBar)
                .toolbarBackgroundVisibility(.visible, for: .tabBar)

            HelpView()
                .tabItem {
                    Label( "Help", systemImage: "books.vertical" )
                }
                .toolbarBackground( Color("Background"), for: .tabBar)
                .toolbarBackgroundVisibility(.visible, for: .tabBar)
        }
    }
}


//#Preview {
//    ControlView()
//}
