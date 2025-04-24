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


struct PlotView : View {
    
    @StateObject var model: CalculatorModel
    
    
    static var plotPatternTable: [PlotPattern] = [
        
        PlotPattern(.vector2D,
                    [ .X(vector2DTypes) ]),
        
        PlotPattern(.multiPoint,
                    [ .X([.real], .matrix), .Y([.real], .matrix)], where: { $0.Xtv.rows == 1 && $0.Xtv.cols == $0.Ytv.cols } ),
        
        PlotPattern(.pointArray,
                    [ .X(vector2DTypes, .matrix)], where: { $0.Xtv.cols > 1 } ),
        
    ]
    
    
    func matchPlotPattern() -> [PlotType] {
        
        var plotList = [PlotType]()
        
        for pat in PlotView.plotPatternTable {
            
            if model.state.patternMatch(pat.pattern) {
                plotList.append(pat.type)
            }
        }
        
        return plotList
    }

    
    var body: some View {
        
        let plotList = matchPlotPattern()
        
        let plotType = plotList.isEmpty ? PlotType.none : plotList[0]
        
        switch plotType {
            
        case .vector2D:
            PlotVectorView( model: model )
            
        case .pointArray:
            PlotPointsView( model: model )

        case .multiPoint:
            PlotMultiPointView( model: model )
            
        case .none:
            VStack {
                AuxHeaderView( theme: Theme.lightPurple ) {
                    RichText( "Plot", size: .small, weight: .bold )
                }
                
                Spacer()
                Text( "Plot Help Text" )
                Spacer()
            }
        }
        
    }
}
