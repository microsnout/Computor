//
//  AuxDisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI

enum AuxDispMode: Int, Hashable {
    case memoryList = 0, memoryDetail, macroList, stackBrowser
}


let auxRight: [AuxDispMode : AuxDispMode] = [
    .memoryList : .memoryDetail,
    .memoryDetail : .macroList
]


let auxLeft: [AuxDispMode : AuxDispMode] = [
    .macroList : .memoryDetail,
    .memoryDetail : .memoryList
]


struct AuxiliaryDisplayView: View {
    @StateObject var model: CalculatorModel
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack {
                    
                    MemoryListView( model: model )
                        .frame( maxWidth: .infinity, maxHeight: .infinity)
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)

                    MemoryDetailView( model: model )
                        .frame( maxWidth: .infinity, maxHeight: .infinity)
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)

                    MacroListView( model: model )
                        .frame( maxWidth: .infinity, maxHeight: .infinity)
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)

                    ValueBrowserView( model: model )
                        .frame( maxWidth: .infinity, maxHeight: .infinity)
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .padding([.leading, .trailing, .top, .bottom], 0)
        .background( Color("Display") )
        .border(Color("Frame"), width: 3)
    }
}


struct AuxiliaryDisplayView_Previews: PreviewProvider {
    
    static var previews: some View {
        @StateObject  var model = CalculatorModel()
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            VStack {
                AuxiliaryDisplayView( model: model )
                    .preferredColorScheme(.light)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
        }
    }
}
