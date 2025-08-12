//
//  HelpView.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-10.
//

import SwiftUI

struct HelpView: View {
    
    @State private var page = "keyhelp"
    
    @State private var pageText: String = ""
    
    var body: some View {
        
        let blocks = pageText.components(separatedBy: "####\n")
        
        NavigationStack {
            
            List {
                ForEach( 0..<blocks.count, id:\.self ) { x in
                    let txt = blocks[x]
                    let letter = txt.hasPrefix("@@")
                    
                    if letter {
                        let lines = txt.split( separator: "\n")
                        let line  = String( lines[0].dropFirst(2) )

                        ZStack( alignment: .leading ) {
                            RichText( line, size: .large, weight: .bold, design: .default, defaultColor: "AccentText")
                        }
                    }
                    else {
                        let line = String( txt.dropLast(1) )
                        
                        ZStack( alignment: .leading ) {
                            Rectangle()
                                .fill(Color("ControlBack"))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle( cornerRadius: 15)
                                        .stroke( Color("Frame"), lineWidth: 3)
                                )
                            
                            RichText( line, size: .normal, weight: .medium, design: .default)
                                .padding(10)
                        }
                    }
                }
            }
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
        
        .onChange( of: page, initial: true ) {
            
            if let fileURL = Bundle.main.url( forResource: page, withExtension: "txt") {
                
                do {
                    let fileContents = try String( contentsOf: fileURL, encoding: .utf8 )
                    pageText = fileContents
                    // loadRTFContent()
                }
                catch {
                    print("Error loading file contents: \(error.localizedDescription)")
                }
                
            } else {
                // File not found in the bundle
                print("Error: \(page).md not found in bundle.")
            }
        }
    }
}


#Preview {
    HelpView()
}


// Unused code //

//    @State private var pageStack: [String] = ["root"]
//
//    @State private var pageIndex: Int = 0
//
//    @State private var attributedText: AttributedString = AttributedString("Loading RTF...")
//
//    private func gotoPage( _ p: String ) {
//        if p != page {
//
//            if pageIndex < (pageStack.count - 1) {
//                // Truncate page stack
//                pageStack.removeSubrange( (pageIndex+1) ..< pageStack.count )
//            }
//            pageStack.append(p)
//            page = p
//            pageIndex += 1
//        }
//    }
//
//    private func homePage() {
//        gotoPage("root")
//    }
//
//    private func pageBack() {
//        if pageIndex > 0 {
//            pageIndex -= 1
//            page = pageStack[pageIndex]
//        }
//    }
//
//    private func pageForward() {
//        if pageIndex < (pageStack.count-1) {
//            pageIndex += 1
//            page = pageStack[pageIndex]
//        }
//    }
//

//                   V Text( LocalizedStringKey(pageText) )

//                    Text( attributedText )
//                        .environment( \.openURL, .init( handler: { url in
//                            print( url )
//                            gotoPage( url.path() )
//                            return .handled
//                        }))
//                        .tint( Color("Frame"))

//            HStack {
//                Button( action: { homePage() } ) {
//                    Image( systemName: "house" )
//                }
//                Button( action: { pageBack() } ) {
//                    Image( systemName: "arrowshape.backward" )
//                }
//                Button( action: { pageForward() } ) {
//                    Image( systemName: "arrowshape.forward" )
//                }
//
//                Spacer()
//
//            }
//            .frame( height: 40 )

//    private func loadRTFContent() {
//
//        if let rtfData = pageText.data(using: .utf8) {
//
//            do {
//                let nsAttributedString = try NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
//                self.attributedText = AttributedString(nsAttributedString)
//            } catch {
//                print("Error loading RTF: \(error.localizedDescription)")
//            }
//        }
//    }
