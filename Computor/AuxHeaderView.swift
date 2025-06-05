//
//  AuxHeaderView.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-03.
//
import SwiftUI


struct AuxHeaderView<Content: View>: View {
    
    var theme: Theme
    
    @ViewBuilder let content: Content

    var body: some View {
        
        VStack {
            content
        }
        .frame( maxWidth: .infinity, maxHeight: 24 )
        .background( theme.mainColor )
    }
    
}



//struct AuxHeaderView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        @StateObject  var model = MacroListView_Previews.addSampleMacro( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    AuxHeaderView( theme: Theme.lightGreen ) {
//                        Text("Test")
//                    }
//                    .frame( maxWidth: .infinity )
//                    .preferredColorScheme(.light)
//                    
//                    Spacer()
//                }
//                .padding([.leading, .trailing, .top, .bottom], 0)
//                .background( Color("Display") )
//                .border(Color("Frame"), width: 3)
//            }
//            .padding(.horizontal, 30)
//            .padding(.vertical, 5)
//            .background( Color("Background"))
//        }
//    }
//}
