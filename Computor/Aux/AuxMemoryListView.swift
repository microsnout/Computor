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

    var body: some View {
        @Bindable var bindableModel = model
        
        VStack {
            
            // Header bar
            AuxHeaderView( theme: Theme.lightBlue ) {
                
                HStack {
                    Spacer()
                    RichText( "Memory", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                    ItemListMenu()
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

                AuxItemList<MemoryRec>( items: $bindableModel.state.memory, controls: memoryListControls ) { cntl, item, model in
                    
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

    var body: some View {
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
            }
            label: {
                Label( "Edit Memory List", systemImage: Const.Icon.edit )
            }
            
            Button {
                model.aux.expanded.toggle()
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



typealias ControlListClosure = ( _ item: ItemRec, _ model: CalculatorModel ) -> [ListControl]

typealias ControlPressClosure = ( _ cntl: ListControl,  _ item: ItemRec, _ model: CalculatorModel ) -> Void


func memoryListControls( _ item: ItemRec, _ model: CalculatorModel ) -> [ListControl] {
    
    if let mr = item as? MemoryRec {
        
        if let _ = model.activeModule.getLocalPlot(mr.symTag) {
            return [.plot, .recall, .delete]
        }
    }
    
    return [.recall, .delete]
}


struct AuxItemList<T>: View where T: ItemRec {
    @Environment(CalculatorModel.self) private var model
    
    @Binding var items: [T]

    var controls: ControlListClosure
    
    var cpc: ControlPressClosure

    var body: some View {
        
        ScrollView {
            LazyVStack {
                ForEach ( items ) { item in
                    
                    let txt = item.getSecondLineText()
                    
                    // Either a global memory tag or a macro tag for a computed memory
                    let sym = item.getRichSymText()
                    
                    let caption: String = item.getCaption(model)
                    
                    let divider = item.symTag == SymbolTag.Divider
                    
                    VStack {
                        HStack {
                            
                            if divider {
                                
                                HStack {
                                    Spacer()
                                    
                                    RichText(caption, size: .normal, weight: .regular, design: .serif, defaultColor: "BlackText" )
                                    
                                    Spacer()
                                }
                                .frame( height: 18 )
                            }
                            else {
                                // Memory two line description
                                VStack( alignment: .leading, spacing: 0 ) {
                                    
                                    HStack {
                                        // Tag Symbol
                                        RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                        
                                        // Caption text
                                        RichText(caption, size: .small, weight: .regular, design: .serif, defaultColor: "UnitText" )
                                    }
                                    
                                    // 2nd Line Item text - Value for memories
                                    RichText( "ƒ{0.9}\(txt)", size: .small, weight: .bold, design: .serif ).padding([.leading], Const.UI.listItemIndent )

                                }
                                .padding( [.leading ], Const.UI.listItemPadding )
                                .frame( height: Const.UI.listItemHeight )
                                .onTapGesture {
                                    withAnimation {
                                        cpc(.select, item, model)
                                    }
                                }
                            }

                            Spacer()
                            
                            // Button controls at right of rows
                            HStack( spacing: Const.UI.listItemSpacing ) {
                                
                                let controlList = divider ? [] : controls(item, model)

                                ForEach( controlList, id: \.self ) { cntl in
                                    
                                    Button( action: { cpc(cntl, item, model) } ) {
                                        Image( systemName: cntl.icon )
                                    }
                                }
                                
                            }
                            .padding( [.trailing], 20 )
                        }
                        .contentShape(Rectangle())
                        .if ( divider ) { view in
                            view.background(.veryLightBlue)
                        }
                        
                        Divider()
                    }
                }
            }
            .padding( .horizontal, 0)
            .padding( .top, 0)
        }

    }
}



struct ListDividerEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var caption: String = ""
    
    @Environment(CalculatorModel.self) private var model
    
    var ldc: ( _ newCap: String ) -> Void
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                Button( action: { ldc(caption); dismiss() } ) {
                    RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                }
            }
            .padding( [.top], 5 )
            
            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: Const.Placeholder.xcaption, text: $caption )
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.7), .large] )
        .onAppear() {
        }
    }
}
