//
//  HelpView.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-10.
//

import SwiftUI

struct HelpView: View {
    
    @State private var page = "root"
    
    @State private var pageText: String = ""
    
    @State private var pageStack: [String] = ["root"]
    
    @State private var pageIndex: Int = 0
    
    private func gotoPage( _ p: String ) {
        if p != page {
            
            if pageIndex < (pageStack.count - 1) {
                // Truncate page stack
                pageStack.removeSubrange( (pageIndex+1) ..< pageStack.count )
            }
            pageStack.append(p)
            page = p
            pageIndex += 1
        }
    }
    
    private func homePage() {
        gotoPage("root")
    }
    
    private func pageBack() {
        if pageIndex > 0 {
            pageIndex -= 1
            page = pageStack[pageIndex]
        }
    }
    
    private func pageForward() {
        if pageIndex < (pageStack.count-1) {
            pageIndex += 1
            page = pageStack[pageIndex]
        }
    }
    

    var body: some View {
        
        VStack {
            HStack {
                Button( action: { homePage() } ) {
                    Image( systemName: "house" )
                }
                Button( action: { pageBack() } ) {
                    Image( systemName: "arrowshape.backward" )
                }
                Button( action: { pageForward() } ) {
                    Image( systemName: "arrowshape.forward" )
                }
                
                Spacer()

            }
            .frame( height: 40 )
            
            ScrollView {
                VStack {
                    
                    Text( LocalizedStringKey(pageText) )
                        .environment( \.openURL, .init( handler: { url in
                            print( url )
                            gotoPage( url.path() )
                            return .handled
                        }))
//                        .tint( Color("Frame"))
                                      
                }
                .padding()
                .frame( maxWidth: .infinity, maxHeight: .infinity)
            }
            .background( Color("Display") )
            .border( Color("Frame"), width: 3)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ListBack"))
        .scrollContentBackground(.hidden)
        .onChange( of: page, initial: true ) {
            
            if let fileURL = Bundle.main.url( forResource: page, withExtension: "md") {
                
                do {
                    let fileContents = try String( contentsOf: fileURL, encoding: .utf8 )
                    pageText = fileContents
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
