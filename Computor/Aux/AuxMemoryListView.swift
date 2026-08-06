//
//  AuxMemoryListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct AuxMemoryView: View {
    @Environment(CalculatorModel.self) private var model

    var body: some View {
        @Bindable var bindableModel = model
        
        Group {
            if model.aux.memRec == nil {
                
                // List of all available macros
                MemoryListView()
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
            else {
                // Detailed view of selected macro
                MemoryDetailView( memRec: $bindableModel.aux.memRec )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .id( model.aux.memRec == nil ? "list" : "detail" )
        .animation( .easeInOut, value: model.aux.memRec == nil )
        .onChange(of: model.aux.memRec ) { oldValue, newValue in
            // Force saving of document to persist this value
            model.changed()
        }
    }
}


struct MemoryListView: View {
    @Environment(CalculatorModel.self) private var model
    
    @State var isEditing: Bool = false

    var body: some View {
        @Bindable var bindableModel = model
        
        VStack {
            
            // Header bar
            AuxHeaderView( theme: Theme.lightBlue ) {
                
                HStack {
                    Spacer()
                    RichText( "Memory", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                    ItemListMenu( isEditing: $isEditing )
                }
            }
            
            if model.state.memory.isEmpty {
                Spacer()
                VStack {
                    // Placeholder for empty memory list
                    Text("Memory")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                Spacer()
            }
            else {

                AuxItemList<MemoryRec>(  items: $bindableModel.state.memory, isEditing: $isEditing, controls: memoryListControls ) { cntl, item, model in
                    
                    if let mr = item as? MemoryRec {
                        
                        switch cntl {
                            
                        case .select:
                            // Navigate to selected item
                            if let mr = item as? MemoryRec {
                                
                                model.aux.memRec = mr
                            }

                        case .plot:
                            if let plotRec = model.activeModule.getLocalPlot(mr.symTag) {
                                model.aux.activeView = .plotView
                                model.aux.plotRec = plotRec
                            }

                        case .recall:
                            model.memoryOp( key: .rclMem, tag: item.symTag )
                            
                        case .delete:
                            model.deleteMemoryRecords( set: [item.symTag] )

                        default:
                            break
                        }
                    }
                }
            }
        }
    }
}



struct ItemListMenu: View {
    @Environment(CalculatorModel.self) private var model
    
    @State private var memorySheet: Bool = false
    @State private var dividerSheet: Bool = false
    
    @Binding var isEditing: Bool

    var body: some View {
        
        if isEditing {
            
            Button(action: {
                withAnimation {
                    isEditing = false
                }
            }) {
                RichText( "Done", size: .small, weight: .bold, defaultColor: "BlackText" )
                    .padding( [.trailing], 8 )
            }
        }
        else {
            Menu {
                Button {
                    withAnimation {
                        memorySheet = true
                    }
                }
                label: {
                    Label( "Add New Memory", systemImage: Const.Icon.plus )
                }
                
                Button {
                    withAnimation {
                        dividerSheet = true
                    }
                }
                label: {
                    Label( "Add Divider", systemImage: Const.Icon.listDivider )
                }
                
                Button {
                    withAnimation {
                        isEditing = true
                    }
                }
                label: {
                    Label( "Edit Memory List", systemImage: Const.Icon.edit )
                }
                
                Button {
                    withAnimation {
                        model.aux.expanded.toggle()
                    }
                }
                label: {
                    Label( model.aux.expanded ? "Collapse Memory List" : "Expand Memory List",
                           systemImage: model.aux.expanded ? Const.Icon.shrink : Const.Icon.expand )
                }
            }
            label: {
                Image( systemName: "ellipsis")
                    .foregroundColor( Color("AuxHeaderText") )
                    .padding( [.trailing], 10 )
            }
            .disabled( false )
            .sheet( isPresented: $memorySheet) {
                
                // Edit Memory
                MemoryEditSheet() {  newTag, newtxt in
                    
                    if newTag != SymbolTag.Null {
                        let _ = model.newGlobalMemory( newTag, caption: newtxt.isEmpty ? nil : newtxt )
                        model.changed()
                        model.saveDocument()
                        
                        print( "Create Memory: \(newTag.getRichText())" )
                    }
                }
                .presentationDetents([.fraction(0.9)])
            }
            .sheet( isPresented: $dividerSheet ) {
                
                ListDividerEditSheet() { newCaption in
                    
                    if !newCaption.isEmpty {
                        
                        let _ = model.newGlobalMemory( SymbolTag.Divider, caption: newCaption )
                        model.changed()
                        model.saveDocument()
                    }
                }
            }
        }
    }
}



func memoryListControls( _ item: ItemRec, _ model: CalculatorModel ) -> [ListControl] {
    
    if let mr = item as? MemoryRec {
        
        if let _ = model.activeModule.getLocalPlot(mr.symTag) {
            return [.plot, .recall]
        }
    }
    
    return [.recall]
}

