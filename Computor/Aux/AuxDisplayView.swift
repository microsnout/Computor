//
//  AuxDisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI

enum AuxDispView: String, CaseIterable, Identifiable, Codable {
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
    
    @State var model: CalculatorModel
    
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
                    
                    AuxRegisterView( model: model, valueIndex: $model.aux.valueIndex )
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
            model.changed()
        }
        .onChange( of: scrollPos ) { oldPos, newPos in
            auxView = scrollPos ?? AuxDispView.memoryView
        }
        .padding([.leading, .trailing, .top, .bottom], 0)
        .background( Color("Display") )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color("Frame"), lineWidth: 3))
    }
}


struct AuxHeaderView<Content: View>: View {
    
    var theme: Theme
    
    @ViewBuilder let content: Content
    
    var body: some View {
        
        VStack {
            content
        }
        .frame( maxWidth: .infinity, maxHeight: Const.UI.auxFrameHeight )
        .background( theme.mainColor )
    }
    
}
