//
//  AuxMemoryListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct AuxMemoryView: View {
    @State var model: CalculatorModel
    
    var body: some View {
        
        Group {
            if model.aux.memRec == nil {
                
                // List of all available macros
                MemoryListView(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
            else {
                // Detailed view of selected macro
                MemoryDetailView( model: model, memRec: $model.aux.memRec )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .onChange(of: model.aux.memRec ) { oldValue, newValue in
            // Force saving of document to persist this value
            model.changed()
        }
    }
}


struct MemoryListView: View {
    @State var model: CalculatorModel
    
    @State private var memorySheet: Bool = false

    var body: some View {
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
                ScrollView {
                    LazyVStack {
                        ForEach ( model.state.memory ) { mr in
                            
                            let (txt, _) = mr.tv.renderRichText()
                            
                            // Either a global memory tag or a macro tag for a computed memory
                            let sym = mr.symTag.isComputedMemoryTag ? "ç{AccentText}\(mr.symTag.getRichText())ç{}" : mr.symTag.getRichText()
                            
                            let caption: String = mr.getCaption(model)
                            
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
                                        RichText( "ƒ{0.9}\(txt)", size: .small, weight: .bold, design: .serif ).padding([.leading], 10)
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    
                                    // Button controls at right of rows
                                    HStack( spacing: 20 ) {
                                        
                                        // ARROW DOWN
                                        Button( action: { model.memoryOp( key: .rclMem, tag: mr.symTag ) } ) {
                                            Image( systemName: Const.Icon.arrowDown )
                                        }
                                        
                                        // TRASH CAN
                                        Button( action: {
                                            model.deleteMemoryRecords( set: [mr.symTag] )
                                        } ) {
                                            Image( systemName: Const.Icon.trash )
                                        }
                                    }.padding( [.trailing], 20 )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        // Navigate to selected item
                                        model.aux.memRec = mr
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
        .sheet( isPresented: $memorySheet) {
            
            // Edit Memory
            MemoryEditSheet( model: model ) {  newTag, newtxt in
                
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
