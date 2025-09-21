//
//  HelpView.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-10.
//

import SwiftUI


struct HelpPageView: View {
    
    @State var pageFile: String = ""
    
    @State private var pageText: String = ""
    
    var body: some View {
        
        let blocks = pageText.components(separatedBy: "####\n")
        
        List {
            ForEach( 0..<blocks.count, id:\.self ) { x in
                let txt = blocks[x]
                let letter = txt.hasPrefix("@@")
                let link = txt.hasPrefix("$$")
                
                if letter {
                    let lines = txt.split( separator: "\n")
                    let line  = String( lines[0].dropFirst(2) )
                    
                    ZStack( alignment: .leading ) {
                        RichText( line, size: .large, weight: .bold, design: .default, defaultColor: "AccentText")
                    }
                }
                else if link {
                    let lines = txt.split( separator: "\n")
                    let line  = String( lines[0].dropFirst(2) )
                    let strs  = line.split( separator: "/")
                    
                    ZStack( alignment: .leading ) {
                        VStack( alignment: .leading ) {
                            NavigationLink {
                                HelpPageView( pageFile: String(strs[1]) )
                            }
                            label: {
                                RichText( String(strs[0]), size: .normal, weight: .black, design: .monospaced, defaultColor: "ModText")
                            }
                            
                            if lines.count > 1 {
                                RichText( String(lines[1]), size: .small, weight: .medium, design: .default )
                            }
                        }
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
        
        .onAppear() {
            if let fileURL = Bundle.main.url( forResource: pageFile, withExtension: "txt") {
                
                do {
                    let fileContents = try String( contentsOf: fileURL, encoding: .utf8 )
                    pageText = fileContents
                }
                catch {
                    print("Error loading file contents: \(error.localizedDescription)")
                }
                
            } else {
                // File not found in the bundle
                print("Error: \(pageFile).txt not found in bundle.")
            }
        }
    }
}


struct HelpView: View {
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                HelpPageView( pageFile: "root")
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SectionHeaderText( text: "Help" )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
    }
}
