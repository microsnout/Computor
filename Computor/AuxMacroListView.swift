//
//  AuxMacroListView.swift
//  Computor
//
//  Created by Barry Hall on 2025-02-28.
//
import SwiftUI


struct MacroListView: View {
    @StateObject var model: CalculatorModel

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                let list = model.aux.list
                
                VStack(spacing: 7) {
                    ForEach (list.opSeq.indices, id: \.self) { x in
                        let op: MacroOp = list.opSeq[x]
                        let line = String( format: "ç{LineNoText}={%3d }ç{}", x+1)
                        let txt = op.getRichText(model)

                        HStack {
                            RichText( line, size: .small )
                            RichText( txt, size: .small, weight: .bold )
                            Spacer()
                        }
                    }
                    .onChange( of: list.opSeq.indices.count ) {
                        if list.opSeq.count > 1 {
                            proxy.scrollTo( list.opSeq.indices[list.opSeq.endIndex - 1] )
                        }
                    }
                }
                .padding([.leading, .trailing], 20)
                .padding([.top, .bottom], 10)
            }
        }
    }
}

