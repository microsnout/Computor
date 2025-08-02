//
//  ControlView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-01.
//

import SwiftUI

struct ControlView: View {
    var body: some View {
        
        TabView {
            
            LibraryView()
                .tabItem {
                    Label( "Modules", systemImage: "book.pages" )
                }
            
            SettingsView()
                .tabItem {
                    Label( "Settings", systemImage: "slider.horizontal.3" )
                }
            
            HelpView()
                .tabItem {
                    Label( "Help", systemImage: "books.vertical" )
                }
        }
    }
}


#Preview {
    ControlView()
}
