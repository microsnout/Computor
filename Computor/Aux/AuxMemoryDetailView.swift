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
                                    
                                    let sym = mr.symTag.getRichText()
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
                    
                    Button( action: { model.memoryOp( key: .mMinus, tag: mr.symTag ) } ) {
                        Text( "M-" )
                    }
                    
                    Button( action: { model.memoryOp( key: .rclMem, tag: mr.symTag ) } ) {
                        Image( systemName: "arrowshape.down" )
                    }
                    
                    Button( action: { model.memoryOp( key: .stoMem, tag: mr.symTag ) } ) {
                        Image( systemName: "arrowshape.up" )
                    }
                    
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
                    mr.symTag = newTag
                    mr.caption = newtxt.isEmpty ? nil : newtxt
                    refreshView.toggle()
                    
                    // Save changes to memory tag and caption immediately
                    model.changed()
                    model.saveDocument()
                }
            }
        }
    }
}


typealias MemorySheetContinuationClosure = ( _ tag: SymbolTag, _ str: String ) -> Void


struct MemoryEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var mTag: SymbolTag = SymbolTag.Null
    @State var caption: String = ""
    
    @State var model: CalculatorModel
    
    var scc: MemorySheetContinuationClosure
    
    @State private var symName: String = ""
    
    @State var dropCode: Int = 0
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                Button( action: { scc(mTag, caption); dismiss() } ) {
                    RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                }
            }
            .padding( [.top], 5 )
            
            // Symbol Editor
            SheetCollapsibleView( code: 1, label: "={Symbol: }\(symName)", drop: $dropCode ) {
                
                NewSymbolPopup( tag: mTag ) { newTag in
                    mTag = newTag
                    symName = mTag.getRichText()
                }
            }
            
            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: "-caption-", text: $caption )
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.7), .large] )
        .onAppear() {
            symName = (mTag == SymbolTag.Null) ? "" : mTag.getRichText()
        }
        .onSubmit {
            scc( mTag, caption )
            dismiss()
        }
    }
}
