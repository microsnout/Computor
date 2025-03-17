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
    
    @State var orientation = UIDevice.current.orientation
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()

    
    var body: some View {
        
        Group {
            if orientation.isLandscape {
                LandscapeView( model: model )
            }
            else {
                ZStack {
                    Rectangle()
                        .fill(Color("Background"))
                        .edgesIgnoringSafeArea( .all )
                    
                    KeyStack( keyPressHandler: model ) {
                        NavigationStack {
                            VStack( spacing: 5 ) {
                                VStack( spacing: 0 ) {
                                    AuxiliaryDisplayView( model: model, auxView: $model.aux.activeView )
                                    
                                    DotIndicatorView( currentView: $model.aux.activeView )
                                        .padding( .top, 4 )
                                        .frame( maxHeight: 8)
                                    
                                    HStack {
                                        Text("Computor").foregroundColor(Color("Frame"))/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/().italic()
                                        
                                        Spacer()
                                        
                                        NavigationLink( destination: SettingsView() ) {
                                            Image( systemName: "gearshape").foregroundColor(Color("Frame"))
                                        }
                                    }
                                    .frame( maxHeight: 22 )
                                }
                                .padding(0)
                                
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
            }
        }
        .task {
            do {
                try await model.loadState()
            } catch {
                //                fatalError(error.localizedDescription)
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
        .onReceive(orientationChanged) { _ in
            self.orientation = UIDevice.current.orientation
        }
    }
}


struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView()
            .preferredColorScheme(.light)
    }
}

