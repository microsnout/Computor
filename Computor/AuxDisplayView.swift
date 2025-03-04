//
//  AuxDisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI

enum AuxDispView: String {
    case memoryList, memoryDetail, macroList, valueBrowser
    
    var id: String {
        rawValue
    }

    var ID: String {
        rawValue
    }
}


struct AuxiliaryDisplayView: View {
    @StateObject var model: CalculatorModel
    
    @Binding var auxViewId: String
    
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
        .onChange( of: auxViewId ) { oldId, newId in
            scrollPosId = newId
        }
        .padding([.leading, .trailing, .top, .bottom], 0)
        .background( Color("Display") )
        .border(Color("Frame"), width: 3)
    }
}


struct AuxiliaryDisplayView_Previews: PreviewProvider {
    
    @State private var pos = ScrollPosition( id: AuxDispView.memoryList.id )
    
    static var previews: some View {
        @StateObject  var model = CalculatorModel()
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            VStack {
//                AuxiliaryDisplayView( model: model, scrollPos: $pos )
//                    .preferredColorScheme(.light)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
        }
    }
}
