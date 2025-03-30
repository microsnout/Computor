//
//  AuxPlot.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-30.
//
import SwiftUI


struct PlotView : View {
    
    @StateObject var model: CalculatorModel
    
    enum PlotPattern {
        case none, vector2D, pointArray
    }
    
    let vectorTypes: Set<ValueType> = [.complex, .vector, .polar]
    
    
    func matchPlotPattern() -> PlotPattern {
        
        let tvX = model.state.Xtv
        
        if tvX.isSimple && vectorTypes.contains(tvX.vtp) {
            return .vector2D
        }
        
        if tvX.isMatrix && tvX.cols == 1 && tvX.rows > 1 && vectorTypes.contains(tvX.vtp) {
            return .pointArray
        }

        return PlotPattern.none
    }

    
    var body: some View {
        
        switch matchPlotPattern() {
            
        case .vector2D:
            PlotVectorView( model: model )
            
        case .pointArray:
            PlotPointsView( model: model )
            
        case .none:
            VStack {
                Spacer()
                Text( "Plot Help Text" )
                Spacer()
            }
        }
        
    }
}
