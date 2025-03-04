//
//  CalculatorView.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2021-10-28.
//
import SwiftUI


struct CalculatorView: View {
    
    @Environment(\.scenePhase) private var scenePhase

    @StateObject var model = CalculatorModel()
    
    var body: some View {
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            KeyStack() {
                NavigationStack {
                    VStack( spacing: 5 ) {
                        AuxiliaryDisplayView( model: model, auxViewId: $model.aux.activeView )

                        // App name and drag handle
                        HStack {
                            Text("Computor").foregroundColor(Color("Frame"))/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/().italic()
                            
                            Spacer()
                            
                            NavigationLink( destination: SettingsView() ) {
                                Image( systemName: "gearshape").foregroundColor(Color("Frame"))
                            }
                        }
                        .frame( height: 25 )
                        
                        // Main calculator display
                        DisplayView( model: model )
                        
                        Spacer().frame( height: 3)
                        
                        VStack( spacing: 7 ) {
                            HStack {
                                KeypadView( padSpec: psSoftkeyL, keyPressHandler: model )
                                Spacer()
                                KeypadView( padSpec: psSoftkeyR, keyPressHandler: model )
                            }
                            HStack {
                                KeypadView( padSpec: psUnitsL, keyPressHandler: model )
                                Spacer()
                                KeypadView( padSpec: psUnitsR, keyPressHandler: model )
                            }
                            HStack {
                                KeypadView( padSpec: psFunctions2L, keyPressHandler: model )
                                Spacer()
                                KeypadView( padSpec: psFunctions2R, keyPressHandler: model )
                            }
                            HStack {
                                KeypadView( padSpec: psFunctionsL, keyPressHandler: model )
                                Spacer()
                                KeypadView( padSpec: psFunctionsR, keyPressHandler: model )
                            }
                        }
                        
                        VStack( spacing: 5) {
                            Divider()
                            HStack {
                                VStack( spacing: 10 ) {
                                    KeypadView( padSpec: psNumeric, keyPressHandler: model )
                                    KeypadView( padSpec: psEnter, keyPressHandler: model )
                                }
                                Spacer()
                                VStack( spacing: 10 ) {
                                    KeypadView( padSpec: psOperations, keyPressHandler: model )
                                    KeypadView( padSpec: psClear, keyPressHandler: model )
                                }
                            }
                        }
                        VStack( spacing: 5 ) {
                            Divider().frame(height: 1)
                            HStack {
                                KeypadView( padSpec: psFormatL, keyPressHandler: model )
                                Spacer()
                                KeypadView( padSpec: psFormatR, keyPressHandler: model )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 5)
                    .background( Color("Background"))
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .task {
            do {
                try await model.loadState()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        .onChange(of: scenePhase) { oldPhase, phase in
            if phase == .inactive {
                Task {
                    do {
                        try await model.saveState()
                    }
                    catch {
                        fatalError(error.localizedDescription)
                    }
                }
            }
        }
    }
}


struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView()
            .preferredColorScheme(.light)
    }
}

