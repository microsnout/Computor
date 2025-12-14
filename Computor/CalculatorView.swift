//
//  CalculatorView.swift
//  Computor
//
//  Created by Barry Hall on 2021-10-28.
//
import SwiftUI


struct CalculatorView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    // This method works better than below commented version on device, not as well on simulator
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass

    @State var model = CalculatorModel()
    
    @State private var timer: Timer?
    
    @State private var initializer = AppInitializer()
    
    var body: some View {
        
        Group {
            switch initializer.state {
                
            case .loading:
                LoadingView( msg: "Loading...")
                
            case .loaded:
                Group {
                    if hSizeClass == .regular && vSizeClass == .compact {
                        LandscapeView( model: model )
                    }
                    else {
                        PortraitView( model: model )
                    }
                }
                
            case .failed( let error ):
                LoadingView( msg: String( describing: error ) )
            }
            
            
        }
        .environment(model)
        .task {
            // This task runs the async initialization when the view appears
            await initializer.initialize(model)
        }
        .onAppear() {
            // Create regular timer pulse - 1 sec
            timer = Timer.scheduledTimer( withTimeInterval: Const.Model.clockTick, repeats: true) { _ in
                DispatchQueue.main.async {
                    _ = model.keyPress( KeyEvent(.clockTick) )
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, phase in
            if phase == .inactive {
                Task {
                    model.saveDocument()
                }
            }
        }
    }
}


@MainActor
@Observable
class AppInitializer {
    
    enum State {
        case loading
        case loaded
        case failed(Error)
    }
    
    var state: State = .loading
    
    func initialize( _ model: CalculatorModel ) async {
        do {
            // Load calculator documents and macro modules
            model.db.loadDatabase()

            // Activate doc0
            model.loadDocument( modZeroSym )

            // Set aux display view to mod zero
            model.aux.macroMod = model.db.getModuleFileRec(sym: modZeroSym) ?? ModuleRec( name: "?")
            
            // Simulate an asynchronous initialization task, e.g., network request, database setup
            // try await Task.sleep( for: .seconds(2))
            state = .loaded
        }
        catch {
            state = .failed(error)
        }
    }
}


struct PortraitView : View {
    
    @State var model: CalculatorModel
    
    @State private var presentSettings: Bool = false

    var body: some View {
        
        ZStack {
            PortraitBackground()
            
            KeyStack( keyPressHandler: model ) {
                VStack( spacing: 5 ) {
                    VStack( spacing: 0 ) {
                        
                        // Auxiliary Display
                        AuxDisplayGroup( model: model )
                        
                        // Computor title and settings control gear
                        TitleBar( model: model, presentSettings: $presentSettings )
                    }
                    .padding(0)
                    
                    // Main calculator display
                    DisplayView( model: model )
                    Spacer().frame( height: 3)

                    // Keypads
                    KeypadGroup( model: model )
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 5)
                .background( Color("Background"))
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet( isPresented: $presentSettings ) {
            ControlView( model: model )
                .presentationDetents( [.fraction(0.7), .fraction(1.0)] )
        }
    }
}


struct LoadingView : View {
    
    var msg: String
    
    var body: some View {
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
            
            VStack( spacing: 0 ) {
                Text(msg)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
            .background( Color("Background"))
            .ignoresSafeArea(.keyboard)
        }
    }
}


struct PortraitBackground: View {
    
    var body: some View {
        
        Group {
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
        }
    }
}


struct AuxDisplayGroup: View {
    
    @State var model: CalculatorModel
    
    var body: some View {
        
        Group {
            AuxiliaryDisplayView( model: model, auxView: $model.aux.activeView )
            
            DotIndicatorView( currentView: $model.aux.activeView )
                .padding( .top, 5 )
                .frame( maxHeight: 8)
        }
    }
}


struct TitleBar: View {
    
    var model: CalculatorModel

    @Binding var presentSettings: Bool

    var body: some View {
        
        HStack {
            let modName = model.activeModName == modZeroSym ? "" : model.activeModName
            
            Text(Const.Str.appName).foregroundColor(Color("Frame"))/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/().italic()
            
            Spacer()
            
            RichText( modName, size: .small, weight: .bold, design: .default, defaultColor: "AccentText" )
            Button {
                presentSettings = true
            } label: {
                Image( systemName: "gearshape").foregroundColor(Color("Frame"))
            }
        }
        .frame( maxHeight: 22 )
    }
}


struct KeypadGroup: View {
    
    var model: CalculatorModel
    
    var body: some View {
        
        Group {
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
                    KeypadView( padSpec: model.kstate.func2R, keyPressHandler: model )
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
        }
    }
}
