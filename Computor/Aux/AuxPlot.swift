//
//  AuxPlot.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-30.
//
import SwiftUI

enum PlotType {
    case none, vector2D, pointArray, multiPoint
}

struct PlotPattern {
    let type: PlotType
    let pattern: RegisterPattern
    
    init( _ type: PlotType, _ pattern: [RegisterSpec], where test: StateTest? = nil ) {
        self.type = type
        self.pattern = RegisterPattern( pattern, test )
    }
}


struct AuxPlotPatternView : View {
    
    @State var model: CalculatorModel
    
    static var plotPatternTable: [PlotPattern] = [
        
        PlotPattern(.vector2D,
                    [ .X(vector2DTypes) ]),
        
        PlotPattern(.multiPoint,
                    [ .X([.real], .matrix), .Y([.real], .matrix)], where: { $0.Xtv.rows == 1 && $0.Xtv.cols == $0.Ytv.cols && $0.Xtv.cols > 1 } ),
        
        PlotPattern(.pointArray,
                    [ .X(vector2DTypes, .matrix)], where: { $0.Xtv.cols > 1 } ),
        
    ]
    
    
    func matchPlotPattern() -> [PlotType] {
        
        var plotList = [PlotType]()
        
        for pat in AuxPlotPatternView.plotPatternTable {
            
            if model.state.patternMatch(pat.pattern) {
                plotList.append(pat.type)
            }
        }
        
        return plotList
    }
    
    
#if DEBUG
    func test( _ pt: PlotType ) {
        print( String( describing: pt))
    }
#endif

    
    var body: some View {
        
        // let _ = Self._printChanges()
        
        let plotList = matchPlotPattern()
        
        let plotType = plotList.isEmpty ? PlotType.none : plotList[0]

        // let _ = test(plotType)

        switch plotType {
            
        case .vector2D:
            PlotVectorView( model: model, tv: model.state.Xtv )
                .id( PlotType.vector2D )
            
        case .pointArray:
            PlotPointsView( model: model, tv: model.state.Xtv )
                .id( PlotType.pointArray )

        case .multiPoint:
            PlotMultiPointView( model: model )
                .id( PlotType.multiPoint )
            
        case .none:
            VStack {
                AuxHeaderView( theme: Theme.lightPurple ) {
                    RichText( "Plot", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                }
                
                Spacer()
                Text( "Plot Help Text" )
                Spacer()
            }
            .id( PlotType.none )
        }
        
    }
}

// *********************************************


struct AuxPlotView: View {
    @State var model: CalculatorModel
    
    var body: some View {
        
        Group {
            if let pRec = model.aux.plotRec {
                
                Group {
                    if let xTag = pRec.vsTag {
                        
                        let yTag = pRec.symTag
                        
                        // Two tags provided, plot yTag vs xTag
                        
                    }
                    else {
                        let xyTag = pRec.symTag
                        
                        // Only one tag provided, xyTag contains points
                        if let xyMem = model.getMemory(xyTag) {
                            
                            if xyMem.tv.isSimple {
                                
                                // Memory contains a single point or complex value
                                PlotVectorView( model: model, tv: xyMem.tv )
                            }
                            else {
                                // Memory contains an array of points
                                PlotPointsView( model: model, tv: xyMem.tv )
                            }
                            
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
            else {
                // No plot selected, display list
                // List of all available plots
                AuxPlotListView(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
        .onChange( of: model.aux.plotTag ) { oldValue, newValue in
            // Force saving of document to persist this value
            model.changed()
        }
    }
}


struct AuxPlotListView : View {
    @State var model: CalculatorModel

    @State private var deleteDialog = false
    
    @State private var plotEditSheet: Bool = false
    
    @State private var dialogRec: PlotRec? = nil

    
    var body: some View {
        
        VStack {
            AuxHeaderView( theme: Theme.lightPurple ) {
                
                HStack {
                    Spacer()
                    RichText( "Plot", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                    
                    // BUTTON - New memory creation button
                    Image( systemName: Const.Icon.plus)
                        .foregroundColor( Color("AuxHeaderText") )
                        .padding( [.trailing], 5 )
                        .onTapGesture {
                            withAnimation {
                                plotEditSheet = true
                            }
                        }
                }
            }
            
            if model.activeModule.plotList.isEmpty {
                
                VStack {
                    Spacer()
                    RichText( "Plot Definitions", size: .large, weight: .bold, defaultColor: "AuxHeaderText" )
                    Spacer()
                }
            }
            else {
                ScrollView {
                    
                    LazyVStack {
                        
                        ForEach ( model.aux.macroMod.plotList ) { pr in
                            
                            let sym = pr.symTag.getRichText()
                            let caption = pr.getCaption()
                            let vsSym = pr.vsTag?.getRichText() ?? ""
                            
                            VStack {
                                HStack {
                                    
                                    VStack( alignment: .leading, spacing: 0 ) {
                                        
                                        HStack {
                                            // Tag Symbol
                                            RichText(sym, size: .small, weight: .bold, design: .serif, defaultColor: "BlackText" )
                                            
                                            // Caption text
                                            RichText( caption, size: .small, weight: .regular, design: .serif, defaultColor: "UnitText" )
                                        }
                                        
                                        // Second line of row
                                        RichText( "ƒ{0.9}\u{1d4e7}-Axis: ç{BlackText}\(vsSym)", size: .small, weight: .heavy, design: .serif, defaultColor: "GrayText" ).padding([.leading], 10)
                                    }
                                    .padding( [.leading ], 20)
                                    .frame( height: 30 )
                                    
                                    Spacer()
                                    
                                    // Button controls at right of rows
                                    HStack( spacing: 20 ) {
                                        
                                        // CHART
                                        Button( action: {
                                            withAnimation {
                                                // Switch to selected plot
                                                model.aux.plotRec = pr
                                            }
                                        } ) {
                                            Image( systemName: Const.Icon.chart )
                                        }
                                        
                                        // DELETE
                                        Button( action: {
                                            deleteDialog = true
                                            dialogRec = pr
                                            model.hapticFeedback.impactOccurred()
                                        } ) {
                                            Image( systemName: "trash" )
                                        }
                                        .confirmationDialog("Confirm Deletion", isPresented: $deleteDialog, presenting: dialogRec) { pr in
                                            
                                            Button("Delete \(pr.symTag.getRichText())", role: .destructive) {
                                                dialogRec = nil
                                                model.activeModule.deletePlot( pr.symTag )
                                            }
                                            
                                            Button("Cancel", role: .cancel) {
                                                // User cancelled, do nothing
                                                dialogRec = nil
                                            }
                                        }
                                        
                                    }.padding( [.trailing], 20 )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        // Switch to selected plot
                                        model.aux.plotRec = pr
                                    }
                                }
                            }
                            
                            Divider()
                        }
                    }
                    .padding( .horizontal, 0)
                    .padding( [.top], 0 )
                }
            }

            
        }
        // BUTTON - New memory creation button
        .sheet( isPresented: $plotEditSheet) {
            
            // Edit Plot 
            PlotEditSheet( model: model ) {  yTag, xTag, caption in
                
                if yTag != SymbolTag.Null {
                    
                    let pr = PlotRec( symTag: yTag, vsTag: xTag, caption: caption )
                    model.activeModule.addPlot(pr)
                    
                    model.changed()
                    model.saveDocument()
                    
                    print( "Create Plot: \(yTag.getRichText())" )
                }
            }
            .presentationDetents([.fraction(0.9)])
        }
    }
}


typealias PlotSheetContinuationClosure = ( _ tag: SymbolTag, _ xTag: SymbolTag?, _ str: String ) -> Void


struct PlotEditSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var mTag: SymbolTag = SymbolTag.Null
    @State var xTag: SymbolTag? = nil
    
    @State var caption: String = ""
    
    @State var model: CalculatorModel
    
    var pcc: PlotSheetContinuationClosure
    
    @State var dropCode: Int = 0

    var body: some View {
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                Button( action: { pcc(mTag, xTag, caption); dismiss() } ) {
                    RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                }
            }
            .padding( [.top], 5 )
            
            // Memory tag selector
            SheetCollapsibleView( code: 1, label: "={Y-Axis: }\(mTag.getRichText())", drop: $dropCode ) {
                
                let tagGroupList: [SymbolTagGroup] = [ SymbolTagGroup( label: "Memories:", itemList: model.state.memory) ]
                
                SelectSymbolPopup( tagGroupList: tagGroupList, title: "Select Macro", sscc: { tag in mTag = tag } ) { }
            }
            
            // Memory tag selector
            SheetCollapsibleView( code: 2, label: "={X-Axis: }\(xTag?.getRichText() ?? "")", drop: $dropCode ) {
                
                let tagGroupList: [SymbolTagGroup] = [ SymbolTagGroup( label: "Memories:", itemList: model.state.memory) ]
                
                SelectSymbolPopup( tagGroupList: tagGroupList, title: "Select Macro", sscc: { tag in xTag = tag } ) { }
            }
            .disabled(mTag == SymbolTag.Null)

            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: Const.Placeholder.xcaption, text: $caption )
                .disabled( mTag.isComputedMemoryTag )

            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.9), .large] )
    }
}
