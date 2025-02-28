//
//  AuxMemoryRenameView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MemoryRenameView: View {
    @StateObject var model: CalculatorModel
    
    @FocusState private var nameFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @State private var editName = ""

    var body: some View {
        let index = model.aux.detailItemIndex
        let value = model.state.memory[index]
        
        Form {
            TextField( "-Unnamed-", text: $editName )
            .focused($nameFocused)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .onAppear {
                if let name = value.name {
                    editName = name
                }
                nameFocused = true
            }
            .onSubmit {
                model.renameMemoryItem(index: index, newName: editName)
                dismiss()
            }
        }
        .scrollContentBackground(.hidden) // iOS 16+
    }
}

