//
//  AuxDisplayView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI

enum AuxDispMode: Int, Hashable {
    case memoryList = 0, memoryDetail, macroList
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
        HStack( spacing: 0) {
            VStack {
                Spacer()
                Image( systemName: "chevron.compact.left")
                    .onTapGesture {
                        if let new = auxLeft[model.aux.mode] {
                            model.aux.mode = new
                        }
                    }
                Spacer()
            }
            .padding([.leading], 0)
            .padding([.top], 10)
            .frame( minWidth: 18, maxWidth: 18, maxHeight: .infinity, alignment: .center)
            // .border(.green)

            switch model.aux.mode {
            case .memoryList:
                MemoryListView( model: model )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)

            case .memoryDetail:
                MemoryDetailView( model: model )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)

            case .macroList:
                MacroListView( model: model )
                    .frame( maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack {
                Spacer()
                Image( systemName: "chevron.compact.right")
                    .onTapGesture {
                        if let new = auxRight[model.aux.mode] {
                            model.aux.mode = new
                        }
                    }
                Spacer()
            }
            .padding([.trailing], 0)
            .padding([.top], 10)
            .frame( minWidth: 18, maxWidth: 18, maxHeight: .infinity, alignment: .center)
            // .border(.green)
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
