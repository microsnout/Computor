//
//  SymbolPopup.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-19.
//
import SwiftUI


struct MemoryKeyView: View {
    
    /// A view of a single memory key
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    let mTag: SymbolTag
    let keySpec: KeySpec
    
    var body: some View {
        
        let keyW = keySpec.width
        
        VStack {
            // Reduce font size for symbols over 3 chars
            let tagText: String = mTag.getRichText()
            let text = mTag.isShortSym ? tagText : "ƒ{0.6}\(tagText)"
            
            // This is the key itself
            Rectangle()
                .foregroundColor( Color(keySpec.keyColor) )
                .frame( width: keyW, height: keySpec.height )
                .cornerRadius( keySpec.radius )
                .shadow( radius: 2 )
                .overlay(
                    RichText( text, size: .normal, weight: .bold, defaultColor: keySpec.textColor)
                )
        }
        .frame( width: keyW, height: keySpec.height )
    }
}


struct SymbolTagGroup: Identifiable {
    
    struct PlainTag: TaggedItem {
        var symTag: SymbolTag
        var caption: String? { nil }
        
        init( _ tag: SymbolTag) {
            self.symTag = tag
        }
    }
    
    var label: String
    var itemList: [any TaggedItem]
    var id: UUID = UUID()

    var tagList: [SymbolTag] {
        itemList.map { $0.symTag }
    }
    
    // Plain list of tags, used by User lib because getting captions requires loading mod
    init( label: String, tagList: [SymbolTag]) {
        self.label = label
        self.itemList = tagList.map { PlainTag($0) }
    }
    
    // List of items containing tag and caption, used by standard lib
    init( label: String, itemList: [any TaggedItem]) {
        self.label = label
        self.itemList = itemList
    }
}


struct SelectSymbolPopup<Content: View>: View {
    
    /// Select from list of existing symbol tags, could be memories or macros
    
    @Environment(CalculatorModel.self) var model
    @EnvironmentObject var keyData: KeyData
    
    let keySpec: KeySpec = ksSoftkey
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Parameters
    var tagGroupList: [SymbolTagGroup]
    var title: String
    
    @ViewBuilder let footer: Content
    
    @State private var isExpanded: Set<String> = []

    // System Image names
    var expIcon: String = Const.Icon.bulletList
    var defIcon: String = Const.Icon.gridList

    var body: some View {
        
        VStack( spacing: 0) {
            Text( title ).padding( [.top, .bottom], 10 )
            
            ScrollView( [.vertical] ) {
                
                Grid {
                    
                    ForEach ( tagGroupList ) { tg in
                        
                        let itemList = tg.itemList
                        
                        let tagList = itemList.map { $0.symTag }

                        let tagRowList: [[SymbolTag]] = tagList.chunked(into: 4)
                        
                        HStack {
                            RichText( tg.label, size: .small, weight: .heavy, design: .monospaced, defaultColor: "AccentText" )
                            
                            Spacer()
                            
                            Button( "", systemImage: isExpanded.contains(tg.label) ? defIcon : expIcon ) {
                                withAnimation {
                                    if isExpanded.contains(tg.label) {
                                        _ = isExpanded.remove(tg.label)
                                    }
                                    else {
                                        _ = isExpanded.insert(tg.label)
                                    }
                                }
                            }
                        }
                        
                        if isExpanded.contains(tg.label) {
                            
                            ForEach ( 0..<itemList.count, id: \.self ) { index in
                                
                                let item = itemList[index]
                                
                                let caption: String = item.caption ?? "-caption-"
                                
                                GridRow {
                                    
                                    MemoryKeyView( mTag: item.symTag, keySpec: keySpec )
                                        .onTapGesture {
                                            if let kcOp = keyData.pressedKey {
                                                // Send event for memory op
                                                _ = model.keyPress( KeyEvent( kcOp.kc, mTag: item.symTag ) )
                                                
                                                hapticFeedback.impactOccurred()
                                            }
                                            
                                            // Close modal popup
                                            keyData.pressedKey = nil
                                            keyData.modalKey = .none
                                        }
                                    
                                    Color.clear
                                        .frame( width: keySpec.width, height: keySpec.height )

                                    Color.clear
                                        .frame( width: keySpec.width, height: keySpec.height )

                                    Color.clear
                                        .frame( width: keySpec.width, height: keySpec.height )
                                }
                                
                                HStack {
                                    RichText( caption, size: .small, weight: .regular, design: .default, defaultColor: "ModText" )
                                    Spacer()
                                }
                            }
                            
                        }
                        else {
                            ForEach ( tagRowList.indices, id: \.self ) { r in
                                
                                let row = tagRowList[r]
                                
                                GridRow {
                                    
                                    let n = row.count
                                    
                                    ForEach ( row.indices, id: \.self ) { c in
                                        
                                        MemoryKeyView( mTag: row[c], keySpec: keySpec )
                                            .onTapGesture {
                                                if let kcOp = keyData.pressedKey {
                                                    // Send event for memory op
                                                    _ = model.keyPress( KeyEvent( kcOp.kc, mTag: row[c] ) )
                                                    
                                                    hapticFeedback.impactOccurred()
                                                }
                                                
                                                // Close modal popup
                                                keyData.pressedKey = nil
                                                keyData.modalKey = .none
                                            }
                                    }
                                    
                                    // Pad the row to 4 col so the frame doesn't shrink
                                    if n < 4 {
                                        ForEach ( 1 ... 4-n, id: \.self ) { _ in
                                            Color.clear
                                                .frame( width: keySpec.width, height: keySpec.height )
                                        }
                                    }
                                }
                                .padding( [.top], 5 )
                            }
                        }
                        
                        Divider()
                    }
                }
            }
            .frame( minWidth: 212, maxWidth: 212 )
            .padding( [.top, .bottom], 5 )
            .padding( [.leading, .trailing], 10 )
            .background( Color("Display") )
            .border(Color("Frame"), width: 2)
            
            // New.. Button for global memory popup
            footer
        }
        .frame( maxHeight: 340 )
        .padding( [.leading, .trailing], 20 )
    }
}
