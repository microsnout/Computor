//
//  AuxDisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI

enum AuxDispView: String, CaseIterable, Identifiable {
    case memoryList, memoryDetail, macroList, valueBrowser
    
    var id: String {
        rawValue
    }
    
    var backColor: Color {
        Color(rawValue)
    }
    
    static let themeMap: [AuxDispView : Theme] = [
        .memoryList : Theme.lightBlue,
        .memoryDetail : Theme.lightGreen,
        .macroList : Theme.lightYellow,
        .valueBrowser: Theme.lightRed,
    ]
    
    var theme: Theme {
        AuxDispView.themeMap[self] ?? Theme.lightGrey
    }
}


struct AuxiliaryDisplayView: View {
    @StateObject var model: CalculatorModel
    
    @Binding var auxView: AuxDispView
    
    @State private var scrollPosId: String? = AuxDispView.memoryList.id
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                
                MemoryListView( model: model )
                    .id( AuxDispView.memoryList.id )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)

                MemoryDetailView( model: model )
                    .id( AuxDispView.memoryDetail.id )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)

                MacroListView( model: model )
                    .id( AuxDispView.macroList.id )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)

                ValueBrowserView( model: model )
                    .id( AuxDispView.valueBrowser.id )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
            }
            .scrollTargetLayout()
        }
        .scrollPosition( id: $scrollPosId )
        .scrollTargetBehavior(.viewAligned)
        .onChange( of: auxView ) { oldView, newView in
            withAnimation() {
                scrollPosId = newView.id
            }
        }
        .padding([.leading, .trailing, .top, .bottom], 0)
        .background( Color("Display") )
        .border(Color("Frame"), width: 3)
    }
}


struct AuxiliaryDisplayView_Previews: PreviewProvider {
    
    static var previews: some View {
        @StateObject  var model = CalculatorModel()
        
        @State var view = AuxDispView.memoryList
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            VStack {
                AuxiliaryDisplayView( model: model, auxView: $view )
                    .preferredColorScheme(.light)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
        }
    }
}
