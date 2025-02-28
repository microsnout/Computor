//
//  AuxMemoryListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MemoryListView: View {
    @StateObject var model: CalculatorModel

    let leadingOps: [(KeyCode, String, Color)] = [
        ( .rcl,    "RCL", .mint ),
        ( .sto,    "STO", .indigo ),
        ( .mPlus,  "M+",  .cyan  ),
        ( .mMinus, "M-",  .green )
    ]
    
    var body: some View {
        VStack {
            if model.state.memory.isEmpty {
                Text("Memory List\n(Press + to store X register)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            else {
                let strList = (0 ..< model.state.memory.count).map
                    { ( model.state.memory[$0].name,
                        model.state.memory[$0].value.renderRichText()) }
                
                List {
                    ForEach ( Array(strList.enumerated()), id: \.offset ) { index, item in
                        
                        // Not using render count for now
                        let (prefix, (value, _)) = item
                        
                        VStack( alignment: .leading, spacing: 0 ) {
                            let name: String = prefix ?? "-unnamed-"
                            
                            let color = prefix != nil ? Color("DisplayText") : Color(.gray)
                            
                            HStack {
                                // Memory name - tap to edit
                                Text(name).font(.footnote).bold().foregroundColor(color).listRowBackground(Color("List0"))
                                    .onTapGesture {
                                        model.aux.detailItemIndex = index
                                        model.aux.mode = .memoryDetail
                                    }
                            }
                            
                            // Memory value display
                            TypedRegister( text: value, size: .small ).padding( .horizontal, 20)
                        }
                        .listRowSeparatorTint(.blue)
                        .frame( height: 30 )
                        .swipeActions( edge: .leading, allowsFullSwipe: true ) {
                            // Memory Op buttons on leading edge
                            ForEach ( leadingOps.indices, id: \.self) { x in
                                let (key, text, color): (KeyCode, String, Color) = leadingOps[x]
                                Button {
                                    model.memoryOp( key: key, index: index )
                                } label: { Text(text).bold() }.tint(color)
                            }
                        }
                        .swipeActions( edge: .trailing, allowsFullSwipe: false) {
                            // Delete button on trailing edge
                            Button( role: .destructive) {
                                model.delMemoryItems( set: IndexSet( [index] ))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listRowSeparatorTint( Color("DisplayText"))
                }
                .listRowSpacing(0)
                .listStyle( PlainListStyle() )
                .padding( .horizontal, 0)
                .padding( .top, 0)
            }
        }
    }
}
