//
//  AuxItemList.swift
//  Computor
//
//  Created by Barry Hall on 2026-04-12.
//

import SwiftUI


enum ListControl: Identifiable {
    case delete, move, recall, store, play, plot
    
    var id: Self { self }
}


let listControlSysNames: [ListControl: String] = [
    .delete: Const.Icon.trash,
    .move:   Const.Icon.move,
    .recall: Const.Icon.arrowDown,
    .store:  Const.Icon.arrowUp,
    .play:   Const.Icon.play,
    .plot:   Const.Icon.chart,
]


struct AuxItemList: View {
    @Environment(CalculatorModel.self) private var model
    
    @Binding var items: [ItemRec]
    
    @Binding var controlList: [ListControl]
    
    @State private var draggedItemId: String?

    var body: some View {
        
        ScrollView {
            LazyVStack {
                ForEach( $items, id: \.id ) { $mr in
                    
                    let item = $mr.wrappedValue
                    let sym = item.getRichSymText()
                    let caption = item.getCaption(model)
                    let secondLine = item.getSecondLineText()
                    
                    let plot = model.activeModule.getLocalPlot( item.symTag )
                    
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
                                RichText( "ƒ{0.9}\(secondLine)", size: .small, weight: .bold, design: .serif ).padding([.leading], 10)
                            }
                            .padding( [.leading ], 20)
                            .frame( height: 30 )
                            
                            Spacer()
                            
                            
                            // Button controls at right of rows
                            HStack( spacing: 20 ) {
                                
                                ForEach ( $controlList, id: \.id ) { $lc in
                                    
                                    let sysName = listControlSysNames[$lc.wrappedValue]
                                    
                                    Button( action: { } ) {
                                        Image( systemName: sysName ?? Const.Icon.arrowDown )
                                    }
                                }
                                
                                if let plotRec = plot {
                                    
                                    // PLOT BUTTON - Go to plot screen
                                    Button( action: {
                                        model.aux.activeView = .plotView
                                        model.aux.plotRec = plotRec
                                    } ) {
                                        Image( systemName: Const.Icon.chart )
                                    }
                                }
                                
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
//                        .onTapGesture {
//                            withAnimation {
//                                // Navigate to selected item
//                                model.aux.memRec = mr
//                            }
//                        }
                        
                        Divider()
                    }
                }
            }
            .padding( .horizontal, 0)
            .padding( .top, 0)
        }
    }

    var body2: some View {
        
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack {
                    
                    ForEach( $items, id: \.id ) { $mr in
                        
                        let item = $mr.wrappedValue
                        let sym = item.getRichSymText()
                        let caption = item.getCaption(model)
                        let secondLine = item.getSecondLineText()
                        
                        VStack {
                            //  SYMBOL
                            RichText("ƒ{1.5}\(sym)", size: .large, weight: .bold, design: .serif, defaultColor: "BlackText" )
                            
                            // CAPTION
                            RichText( "ƒ{1.2}\(caption)", size: .large, design: .serif, defaultColor: "UnitText" )
//                                .onTapGesture {
//                                    renameSheet = true
//                                }
                            
                            TypedRegister( text: secondLine, size: .large ).padding( .leading, 0)
                        }
                        .id( mr.symTag )
                        .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
//            .scrollPosition( id: $position )
//            .onChange( of: position ) { oldRec, newRec in
//                
//                if newRec != nil  {
//                    model.aux.memRec = newRec
//                }
//            }
//            .onChange(  of: memRec, initial: true ) {
//                if let mr = memRec {
//                    print( "scrollto \(mr.symTag)" )
//                    proxy.scrollTo( mr.id )
//                }
//            }
        }
        
    }
}
