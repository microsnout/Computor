//
//  MemoryEditSheet.swift
//  Computor
//
//  Created by Barry Hall on 2026-01-01.
//

import SwiftUI

typealias MemorySheetContinuationClosure = ( _ tag: SymbolTag, _ str: String ) -> Void


struct MemoryEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var mTag: SymbolTag = SymbolTag.Null
    @State var caption: String = ""
    
    @State var model: CalculatorModel
    
    var scc: MemorySheetContinuationClosure
    
    @State private var symName: String = ""
    
    @State var dropCode: Int = 0
    
    func selectComputedMacroSym( _ tag: SymbolTag ) {
        
        // Set macro tag for computed memory
        symName = "\(tag.getRichText())  ƒ{0.8}[Computed]"
        mTag = SymbolTag(tag, mod: SymbolTag.computedMemMod)
    }
    
    
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
                
                NewSymbolPopup( tag: mTag, modCode: SymbolTag.globalMemMod ) { newTag in
                    mTag = newTag
                    symName = mTag.getRichText()
                }
            }
            
            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: "-caption-", text: $caption )
            
            // Computed Memory Macro Selection
            SheetCollapsibleView( code: 2, label: "={Computed Memory:}", drop: $dropCode ) {
                
                let tagGroupList: [SymbolTagGroup] = [SymbolTagGroup( label: model.activeModName, model: model, mod: model.activeModule )]
                
                SelectSymbolPopup( tagGroupList: tagGroupList, title: "Select Macro", sscc: selectComputedMacroSym ) { }
            }
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.7), .large] )
        .onAppear() {
            symName = (mTag == SymbolTag.Null) ? "" : mTag.getRichText()
        }
    }
}
