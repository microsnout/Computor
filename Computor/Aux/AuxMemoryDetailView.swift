//
//  AuxMemoryDetailView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MemoryDetailView: View {
    @StateObject var model: CalculatorModel
    
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
                                    
                                    let sym = mr.tag.getRichText()
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
                                    .id( mr.tag )
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
                                print( "scrollto \(mr.tag)" )
                                proxy.scrollTo( mr.id )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Detail Edit Controls
                HStack( spacing: 25 ) {
                    
                    Button( action: { model.memoryOp( key: .mPlus, tag: mr.tag ) } ) {
                        Text( "M+" )
                    }
                    
                    Button( action: { model.memoryOp( key: .mMinus, tag: mr.tag ) } ) {
                        Text( "M-" )
                    }
                    
                    Button( action: { model.memoryOp( key: .rclMem, tag: mr.tag ) } ) {
                        Image( systemName: "arrowshape.down" )
                    }
                    
                    Button( action: { model.memoryOp( key: .stoMem, tag: mr.tag ) } ) {
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
                
                MemoryEditSheet( mr: mr, caption: mr.caption ?? "", model: model ) { newtxt in
                    mr.caption = newtxt
                    refreshView.toggle()
                }
            }
        }
    }
}


struct MemoryEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    var mr: MemoryRec
    
    @State var caption: String
    
    @StateObject var model: CalculatorModel
    
    var scc: SheetContinuationClosure
    
    @State private var symName: String = ""
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                Button( action: { scc(caption); dismiss() } ) {
                    RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                }
            }
            .padding( [.top], 5 )
            
            // Symbol Editor
            SheetCollapsibleView( label: "={Symbol: }\(symName)" ) {
                
                NewSymbolPopup( tag: mr.tag ) { newTag in
                    mr.tag = newTag
                    symName = mr.tag.getRichText()
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
            symName = mr.tag.getRichText()
        }
        .onSubmit {
            scc( caption )
            dismiss()
        }
    }
}


//struct MemoryDetailView_Previews: PreviewProvider {
//    
//    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        newModel.state.memory = []
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
//                    MemoryDetailView( model: model, itemIndex: $model.aux.detailItemIndex )
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
//struct MemoryDetailView_Previews: PreviewProvider {
//    
//    static func addSampleMemory( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        newModel.state.memory = []
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
//                    MemoryDetailView( model: model, itemIndex: $model.aux.detailItemIndex )
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
