//
//  AuxValueBrowser.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-03.
//
import SwiftUI


struct AuxSimpleValueView: View {
    
    var reg: Int
    var tv: TaggedValue
    
    var body: some View {
        
        VStack {
            
            let nameStr = CalcState.stackRegNames[reg]
            let (valueStr, _) = tv.renderRichText()
            
            Spacer()
            RichText( "ƒ{1.5}ç{DisplayText}\(nameStr)", size: .large, weight: .bold, design: .serif )
            TypedRegister( text: valueStr, size: .large ).padding( .leading, 0)
            Spacer()
        }
    }
}


struct AuxRowMatrixView: View {
    
    var tv: TaggedValue

    var body: some View {
        
        let lineNoFmt = "ç{LineNoText}={%3d }ç{}"
        
        let ( _, _, cols ) = tv.getShape()

        VStack( spacing: 0 ) {
            ScrollView {
                LazyVStack( spacing: 7 ) {
                    
                    ForEach (1...cols, id: \.self) { c in
                        
                        let line = String( format: lineNoFmt, c)
                        
                        let tvValue = tv.getValue( r: 1, c: c ) ?? untypedZero
                        
                        let (valueStr, _) = tvValue.renderRichText()
                        
                        HStack {
                            RichText( line, size: .small )
                            RichText( valueStr, size: .small )
                            Spacer()
                        }
                    }
                }
                .padding([.leading, .trailing], 20)
                .padding([.top, .bottom], 0)
            }
        }
    }
}


struct AuxMatrixView: View {
    
    var tv: TaggedValue

    let lineNoFmt = "ç{LineNoText}={%3d }ç{}"
    let colNoFmt  = "ç{LineNoText}={%3d}ç{}"
    
    var body: some View {

        let ( _, rows, cols ) = tv.getShape()

        VStack( spacing: 0 ) {
            Spacer()
            ScrollView {
                ScrollView( [.horizontal, .vertical] ) {
                    Grid( horizontalSpacing: 0) {
                        GridRow {
                            HStack {
                                RichText( "ç{LineNoText}={ }ç{}", size: .small )
                                Spacer()
                            }
                            .padding( 2)
                            
                            ForEach (1...cols, id: \.self) { c in
                                let col = String( format: colNoFmt, c)
                                
                                HStack {
                                    RichText( col, size: .small )
                                    Spacer()
                                }
                                .padding( 2)
                            }
                        }
                        
                        ForEach (1...rows, id: \.self) { r in
                            
                            let row = String( format: lineNoFmt, r)
                            
                            GridRow {
                                HStack {
                                    RichText( row, size: .small )
                                    Spacer()
                                }
                                .padding( 2)
                                
                                ForEach (1...cols, id: \.self) { c in
                                    
                                    let tvValue = tv.getValue( r: r, c: c ) ?? untypedZero
                                    
                                    let (valueStr, _) = tvValue.renderRichText()
                                    
                                    HStack {
                                        RichText( valueStr, size: .small )
                                        Spacer()
                                    }
                                    .padding( 2)
                                }
                            }
                            .if ( isEven(r+1) ) { view in
                                view.background( Color("SuperLightGray") )
                            }
                        }
                    }
                    .padding([.leading, .trailing], 20)
                    .padding([.top, .bottom], 0)
                }
            }
            Spacer()
        }
    }
}


struct AuxRegisterView: View {
    
    @State var model: CalculatorModel
    
    @State private var position = ScrollPosition( edge: .bottom)
    
    @State private var currentId: Int? = nil
    
    @State private var regName: String = "X"

    func shapeStr( _ rows: Int, _ cols: Int ) -> String {
        if rows*cols == 1 {
            return ""
        }
        
        return "[\(rows) x \(cols)]"
    }
    
    
    var body: some View {
        let regSeq: [Int] = [regZ, regY, regX]

        VStack {
            AuxHeaderView( theme: Theme.lightRed ) {
                RichText( "Register \(regName)", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
            }
            
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack {
                        
                        ForEach( regSeq.indices, id: \.self ) { x in
                            
                            let register = regSeq[x]
                            
                            let value = model.state.stack[register]

                            VStack {
                                if value.isSimple {
                                    // Non-matrix value
                                    AuxSimpleValueView( reg: register, tv: value  )
                                }
                                else if value.rows == 1 {
                                    // Row matrix
                                    AuxRowMatrixView( tv: value )
                                }
                                else {
                                    // Matrix view
                                    AuxMatrixView( tv: value )
                                }
                            }
                            .id( x )
                            .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition( $position )
                .scrollPosition( id: $currentId )
                .onChange( of: currentId ) {
                    if let reg = currentId {
                        regName = CalcState.stackRegNames[2 - reg]
                    }
                }
            }
        }
    }
}
