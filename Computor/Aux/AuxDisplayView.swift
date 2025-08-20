//
//  AuxDisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI

enum AuxDispView: String, CaseIterable, Identifiable {
    case memoryView, macroView, registerView, plotView
    
    var id: String {
        rawValue
    }
    
    var backColor: Color {
        Color(rawValue)
    }
    
    static let themeMap: [AuxDispView : Theme] = [
        .memoryView  : Theme.lightBlue,
        .macroView   : Theme.lightYellow,
        .registerView: Theme.lightRed,
        .plotView    : Theme.lightPurple,
    ]
    
    var theme: Theme {
        AuxDispView.themeMap[self] ?? Theme.lightGrey
    }
}


struct AuxiliaryDisplayView: View {
    
    /// Auxiliary Display - above the primary display
    ///  Horizontal scroll view of 4 panes: memorys, macros, registers and plots
    
    @StateObject var model: CalculatorModel
    
    @Binding var auxView: AuxDispView
    
    @State private var scrollPos: AuxDispView? = AuxDispView.memoryView
    
    var body: some View {
        ScrollView(.horizontal) {
            
            LazyHStack {
                Group {
                    AuxMemoryView( model: model )
                        .id( AuxDispView.memoryView )
                    
                    AuxMacroView( model: model )
                        .id( AuxDispView.macroView )
                    
                    AuxRegisterView( model: model )
                        .id( AuxDispView.registerView )
                    
                    AuxPlotView( model: model )
                        .id( AuxDispView.plotView )
                }
                .frame( maxHeight: .infinity)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
            }
            .scrollTargetLayout()
        }
        .scrollPosition( id: $scrollPos )
        .scrollTargetBehavior(.viewAligned)
        .onAppear() {
            scrollPos = auxView
        }
        .onChange( of: auxView ) { oldView, newView in
            withAnimation() {
                scrollPos = newView
            }
        }
        .onChange( of: scrollPos ) { oldPos, newPos in
            auxView = scrollPos ?? AuxDispView.memoryView
        }
        .padding([.leading, .trailing, .top, .bottom], 0)
        .background( Color("Display") )
        .border(Color("Frame"), width: 3)
    }
}


//struct AuxiliaryDisplayView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        @StateObject  var model = CalculatorModel()
//        
//        @State var view = AuxDispView.memoryList
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                AuxiliaryDisplayView( model: model, auxView: $view )
//                    .preferredColorScheme(.light)
//            }
//            .padding(.horizontal, 30)
//            .padding(.vertical, 5)
//        }
//    }
//}
