//
//  AuxRenameView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


typealias SubmitContinuationClosure = ( _ str: String ) -> Void


struct AuxRenameView: View {
    @FocusState private var nameFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @State private var editName = ""
    
    var name: String
    
    var scc: SubmitContinuationClosure
    
    var body: some View {
        
        Form {
            TextField( "-Caption-", text: $editName )
                .focused($nameFocused)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .onAppear {
                    editName = name
                    nameFocused = true
                }
                .onSubmit {
                    scc( editName )
                    dismiss()
                }
        }
        .scrollContentBackground(.hidden) // iOS 16+
    }
}


//struct MemoryRenameView_Previews: PreviewProvider {
//    
//    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        newModel.state.memory = []
//        newModel.aux.detailItemIndex = 2
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MemoryListView_Previews.addSampleMemory( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    MemoryRenameView( model: model)
//                        .frame( maxWidth: .infinity, maxHeight: .infinity)
//                        .preferredColorScheme(.light)
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
//
//
//struct MemoryRenameView_Previews: PreviewProvider {
//    
//    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        newModel.state.memory = []
//        newModel.aux.detailItemIndex = 2
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MemoryListView_Previews.addSampleMemory( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    MemoryRenameView( model: model)
//                        .frame( maxWidth: .infinity, maxHeight: .infinity)
//                        .preferredColorScheme(.light)
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
