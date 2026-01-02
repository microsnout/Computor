//
//  AuxMemoryDetailView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MemoryDetailView: View {
    @State var model: CalculatorModel
    
    @Binding var memRec: MemoryRec?
    
    @State private var renameSheet = false
    
    @State private var position: MemoryRec? = nil
    
    @State private var refreshView = false
    
    @State private var computedMem: Bool = false

    var body: some View {
        if let mr = model.aux.memRec {
            
            VStack {
                
                // HEADER
                AuxHeaderView( theme: Theme.lightBlue ) {
                    HStack {
                        
                        // Back to Memory List
                        Image( systemName: "chevron.left")
                            .padding( [.leading], 10 )
                            .onTapGesture {
                                withAnimation {
                                    model.aux.memRec = nil
                                }
                            }
                        
                        Spacer()
                        RichText( "Memory Detail", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                        Spacer()
                    }
                }
                
                Spacer()
                
                if model.state.memory.isEmpty {
                    
                    // PLACEHOLDER VIEW
                    Text("Memory Detail")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                else {
                    
                    // DETAIL VIEW
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            LazyVStack {
                                
                                ForEach( model.state.memory ) { mr in
                                    
                                    let computed: Bool = mr.symTag.isComputedMemoryTag
                                    let sym = computed ? "ç{AccentText}\(mr.symTag.getRichText())ç{}" : mr.symTag.getRichText()
                                    let caption = mr.caption ?? "-Unnamed-"
                                    let (valueStr, _) = mr.tv.renderRichText()
                                    let color = mr.caption != nil ? "UnitText" : "GrayText"

                                    VStack {
                                        //  SYMBOL
                                        RichText("ƒ{1.5}\(sym)", size: .large, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                        
                                        // CAPTION
                                        RichText( "ƒ{1.2}ç{\(color)}\(caption)", size: .large, design: .serif )
                                            .onTapGesture {
                                                renameSheet = true
                                            }
                                        
                                        TypedRegister( text: valueStr, size: .large ).padding( .leading, 0)
                                    }
                                    .id( mr.symTag )
                                    .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition( id: $position )
                        .onChange( of: position ) { oldRec, newRec in
                            
                            if newRec != nil  {
                                model.aux.memRec = newRec
                            }
                        }
                        .onChange(  of: memRec, initial: true ) {
                            if let mr = memRec {
                                print( "scrollto \(mr.symTag)" )
                                proxy.scrollTo( mr.id )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Detail Edit Controls
                HStack( spacing: 25 ) {
                    
                    Button( action: { model.memoryOp( key: .mPlus, tag: mr.symTag ) } ) {
                        Text( "M+" )
                    }
                    .disabled(computedMem)

                    Button( action: { model.memoryOp( key: .mMinus, tag: mr.symTag ) } ) {
                        Text( "M-" )
                    }
                    .disabled(computedMem)

                    Button( action: { model.memoryOp( key: .rclMem, tag: mr.symTag ) } ) {
                        Image( systemName: "arrowshape.down" )
                    }
                    
                    Button( action: { model.memoryOp( key: .stoMem, tag: mr.symTag ) } ) {
                        Image( systemName: "arrowshape.up" )
                    }
                    .disabled(computedMem)

                    // PENCIL EDIT BUTTON
                    Button {
                        renameSheet = true
                    } label: {
                        Image( systemName: "square.and.pencil")
                    }
                }
                .frame( maxWidth: .infinity )
                .padding( [.bottom], 5 )
            }
            .padding( [.top], 0 )
            .padding( [.bottom], 10 )
            .onChange( of: mr ) { oldRec, newRec in
                position = newRec
            }
            
            // Edit Memory
            .sheet( isPresented: $renameSheet) {
                
                MemoryEditSheet( mTag: mr.symTag, caption: mr.caption ?? "", model: model ) { newTag, newtxt in
                    
                    model.changeMemorySymbol( from: mr.symTag, to: newTag)
                    model.setMemoryCaption( of: newTag, to: newtxt.isEmpty ? nil : newtxt )
                    
                    refreshView.toggle()
                    
                    // Save changes to memory tag and caption immediately
                    model.changed()
                    model.saveDocument()
                }
                .presentationDetents([.fraction(0.9)])
            }
        }
    }
}

