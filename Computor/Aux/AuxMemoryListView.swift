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

    @State private var memorySheet: Bool = false

    
    var body: some View {
        @Bindable var bindableModel = model
        
        VStack {
            
            // Header bar
            AuxHeaderView( theme: Theme.lightBlue ) {
                
                HStack {
                    Spacer()
                    RichText( "Memory", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                    
                    // BUTTON - New memory creation button
                    Image( systemName: "plus")
                        .foregroundColor( Color("AuxHeaderText") )
                        .padding( [.trailing], 5 )
                        .onTapGesture {
                            withAnimation {
                                memorySheet = true
                            }
                        }

                    // BUTTON - View expand and shrink button
                    Image( systemName: model.aux.expanded ? Const.Icon.shrink : Const.Icon.expand )
                        .foregroundColor( Color("AuxHeaderText") )
                        .padding( [.trailing], 5 )
                        .onTapGesture {
                            withAnimation {
                                model.aux.expanded.toggle()
                            }
                        }
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
                    
                    VStack {
                        HStack {
                            
                            // Memory two line description
                            VStack( alignment: .leading, spacing: 0 ) {
                                
                                HStack {
                                    // Tag Symbol
                                    RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                    
                                    // Caption text
                                    RichText(caption, size: .small, weight: .regular, design: .serif, defaultColor: "UnitText" )
                                }
                                
                                // Memory value display
                                RichText( "ƒ{0.9}\(txt)", size: .small, weight: .bold, design: .serif ).padding([.leading], Const.UI.listItemIndent )
                            }
                            .padding( [.leading ], Const.UI.listItemPadding )
                            .frame( height: Const.UI.listItemHeight )
                            
                            Spacer()
                            
                            
                            // Button controls at right of rows
                            HStack( spacing: Const.UI.listItemSpacing ) {
                                
                                let controlList = controls(item, model)
                                
                                ForEach( controlList, id: \.self ) { cntl in
                                    
                                    Button( action: { cpc(cntl, item, model) } ) {
                                        Image( systemName: cntl.icon )
                                    }
                                }
                                
                            }.padding( [.trailing], 20 )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                cpc(.select, item, model)
                            }
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


