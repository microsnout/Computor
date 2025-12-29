//
//  SettingsView.swift
//  Computor
//
//  Created by Barry Hall on 2024-10-31.
//

import SwiftUI

extension String {
    static var settingsDarkModeKey : String { "settings.darkMode" }
    static var settingsSerifFontKey : String { "settings.serifFont" }
    static var settingsPriDispTextSize : String { "settings.priDispTextSize" }
    static var settingsAuxDispTextSize : String { "settings.auxDispTextSize" }
    // static var settingsSoftkeyUnits : String { "settings.softkeyUnits" }
    static var settingsKeyCaptions : String { "settings.keyCaptions" }
    static var settingsModalConfirmation : String { "settings.modalConfirmation" }
    static var settingsRecordExecute : String { "settings.recordExecute" }
    static var settingsYellowDots : String { "settings.yellowDots" }
}


struct SectionHeaderText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system( .headline, design: .monospaced ))
            .bold()
            .foregroundColor( Color("AccentText") )
            .padding(.vertical, 0)
    }
}


struct SettingsView: View {
    @State var model: CalculatorModel
    
    @AppStorage(.settingsDarkModeKey)
    private var darkMode = false
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsPriDispTextSize)
    private var priDispTextSize = TextSize.normal
    
    @AppStorage(.settingsAuxDispTextSize)
    private var auxDispTextSize = TextSize.normal
    
    // @AppStorage(.settingsSoftkeyUnits)
    @State private var softkeyUnits = SoftkeyUnits.mixed

    @AppStorage(.settingsKeyCaptions)
    private var keyCaptions = true

    @AppStorage(.settingsModalConfirmation)
    private var modalConfirmation = true

    @AppStorage(.settingsRecordExecute)
    private var recordExecute = true

    @AppStorage(.settingsYellowDots)
    private var yellowDots = true

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Group {
                        // SECTION COLORS
                        Section( header: SectionHeaderText( text: "Colors")  ) {
                            Toggle("Display Dark Mode", isOn: $darkMode)
                                .tint( Color("Frame"))
                        }
                        
                        // SECTION TEXT
                        Section( header: SectionHeaderText( text: "Text Size").foregroundColor(Color("DisplayText"))  ) {
                            
                            Picker( selection: $priDispTextSize, label: Text("Primary Display")) {
                                Text("Small").tag(TextSize.small)
                                Text("Medium").tag(TextSize.normal)
                                Text("Large").tag(TextSize.large)
                            }
                            
                            Picker( selection: $auxDispTextSize, label: Text("Auxiliary Display")) {
                                Text("Small").tag(TextSize.small)
                                Text("Medium").tag(TextSize.normal)
                                Text("Large").tag(TextSize.large)
                            }
                        }
                        
                        // SECTION KEYBOARD
                        Section( header: SectionHeaderText( text: "Keyboard").foregroundColor(Color("DisplayText")) ) {
                            
                            Group {
                                Toggle("Key help captions", isOn: $keyCaptions)
                                Toggle("Subkey Yellow Dots", isOn: $yellowDots)
                                Toggle("Parameter Confirmation", isOn: $modalConfirmation)
                            }
                            .tint( Color("Frame"))
                            .listRowSeparator(.hidden)
                            
                           Picker( selection: $softkeyUnits, label: Text("Unit Keys")) {
                                Text("Default").tag(SoftkeyUnits.mixed)
                                Text("Metric").tag(SoftkeyUnits.metric)
                                Text("Imperial").tag(SoftkeyUnits.imperial)
                                Text("Physics").tag(SoftkeyUnits.physics)
                                Text("Electrical").tag(SoftkeyUnits.electrical)
                                Text("Navigation").tag(SoftkeyUnits.navigation)
                            }
                        }
                    }
                    .listSectionSeparator(.hidden, edges: .top)
                    .listSectionSeparatorTint( Color("AccentText"))
                }
                .listStyle( .grouped )
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SectionHeaderText( text: "Settings" )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding()
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
        .onAppear() {
            softkeyUnits = model.kstate.unitSet
        }
        .onChange( of: softkeyUnits ) {
            
            model.kstate.unitSet = softkeyUnits
            model.changed()
        }
    }
}
