//
//  ControlView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-01.
//

import SwiftUI

struct ControlView: View {
    
    @Environment(CalculatorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        
        TabView {
            
            Group {
                ModuleView( list: $model.db.modTable.objTable )
                    .tabItem {
                        Label( "Modules", systemImage: Const.Icon.cntlModules )
                    }
                
                SettingsView()
                    .tabItem {
                        Label( "Settings", systemImage: Const.Icon.cntlSettings )
                    }
                
                HelpView()
                    .tabItem {
                        Label( "Help", systemImage: Const.Icon.cntlHelp )
                    }
                
#if DEBUG
                DebugView()
                    .tabItem {
                        Label( "Debug", systemImage: Const.Icon.cntlDebug )
                    }
#endif
                
            }
            .toolbarBackground( Color("Background"), for: .tabBar)
            .toolbarBackgroundVisibility(.visible, for: .tabBar)
        }
    }
}
