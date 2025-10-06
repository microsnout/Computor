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
            
            Group {
                DocumentView( model: model, list: $model.db.docTable.objTable)
                    .tabItem {
                        Label( "Documents", systemImage: "document.on.document" )
                    }
                
                ModuleView( model: model, list: $model.db.modTable.objTable )
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
                
#if DEBUG
                DebugView( model: model )
                    .tabItem {
                        Label( "Debug", systemImage: "wrench.and.screwdriver" )
                    }
#endif
                
            }
            .toolbarBackground( Color("Background"), for: .tabBar)
            .toolbarBackgroundVisibility(.visible, for: .tabBar)
        }
    }
}


//#Preview {
//    ControlView()
//}
