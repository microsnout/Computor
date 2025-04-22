//
//  AuxPlotPoints.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-06.
//
import SwiftUI


struct PlotPointsView: View {
    
    func getRange( _ tv: TaggedValue ) -> (Double, Double, Double, Double) {
        
        guard tv.isMatrix && tv.cols == 1 && tv.rows > 1 && vector2DTypes.contains(tv.vtp) else {
            return (0.0, 0.0, 0.0, 0.0)
        }
        
        let n = tv.rows
        
        var (xMin, yMin) = tv.getVector( r: 1, c: 1)
        var (xMax, yMax) = (xMin, yMin)
        
        for r in 2...n {
            let (x, y) = tv.getVector( r: r)
            xMin = min(x, xMin)
            yMin = min(y, yMin)
            xMax = max(x, xMax)
            yMax = max(y, yMax)
        }
        
        return (xMin, yMin, xMax, yMax)
    }
    
    
    func plotableValue( _ tv: TaggedValue ) -> Bool {
        
        // Require a matrix of rows of vector types or complex
        tv.isMatrix && tv.cols == 1 && tv.rows > 1 && vector2DTypes.contains(tv.vtp)
    }
    
    
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let tv = model.state.Xtv
        
        let (xMin, yMin, xMax, yMax) = getRange(tv)
        
        VStack {
            AuxHeaderView( theme: Theme.lightPurple ) {
                RichText( "Vector Plot", size: .small, weight: .bold )
            }
            
            if !plotableValue( model.state.Xtv ) {
                
                Spacer()
                Text( "Require a matrix" )
                Spacer()
            }
            else {
                Canvas { context, size in
                    
                    // Entire viewport of the Canvas
                    let viewRect = CGRect( origin: CGPoint.zero, size: size )
                    
                    // Confine our plot to this area
                    let plotRect = viewRect.insetTo( fraction: 0.95 )
                    
                    context.withWindowContext( plotRect, within: viewRect ) { ctx, winRect in
                        
                        // Width and Height of plot window
                        let (wW, hW) = (winRect.width, winRect.height)
                        
                        let (xRange, yRange) = (xMax - xMin, yMax - yMin)
                        
                        // Scale factor for x and y within plot
                        var sxy = 0.75
                        
                        if hW/wW > abs(yRange)/abs(xRange) {
                            // Plot will terminate at X extent
                            sxy *= wW/abs(xRange)
                        }
                        else {
                            // Plot will terminate at Y extent
                            sxy *= hW/abs(yRange)
                        }
                        
                        // Compute origin point
                        let (xO, yO) = ( xRange/2 + xMin, yRange/2 + yMin )
                        
                        // Origin in window space
                        let (xWO, yWO) = ( wW/2 - xO*sxy, hW/2 - yO*sxy)
                        
                        // Find axis co-ordinates and origin point
                        let (xFrom, xTo) = ( CGPoint( x: 0, y: yWO), CGPoint( x: wW - 10, y: yWO) )
                        let (yFrom, yTo) = ( CGPoint( x: xWO, y: 0), CGPoint( x: xWO, y: hW - 10) )
                        
                        // X Axis
                        ctx.arrow( from: xFrom, to: xTo )
                        
                        // Y Axis
                        ctx.arrow( from: yFrom, to: yTo )
                        
                        // Axis Labels
                        let font = Font.custom("Times New Roman", size: 16).italic().bold()
                        let ( xAxisStr, yAxisStr ) = tv.vtp == .complex ? ("Re", "Im") : ("X", "Y")
                        context.text( xAxisStr, font: font, color: .blue, at: CGPoint(x: xTo.x + 10, y: xTo.y), in: ctx )
                        context.text( yAxisStr, font: font, color: .blue, at: CGPoint(x: yTo.x, y: yTo.y + 10), in: ctx )
                        
                        // Shift context to origin
                        ctx.withTransform( dx: xWO, dy: yWO ) { ptx in
                            
                            let n = tv.rows
                            let (x1, y1) = tv.getVector( r: 1)
                            var points = [CGPoint( x: x1 * sxy, y: y1 * sxy )]
                            
                            for r in 2...n {
                                let (x, y) = tv.getVector( r: r)
                                points.append( CGPoint( x: x * sxy, y: y * sxy ) )
                            }
                            
                            // Plot lines
                            let ss = StrokeStyle( lineWidth: 2 )
                            ptx.multiline( points: points, with: .color(.blue), style: ss )
                        }
                    }
                }
                .padding(10)
            }
        }
    }
}


//struct PlotMultiPointView: View {
//    
//    @StateObject var model: CalculatorModel
//
//    func getRange( _ tvX: TaggedValue, _ tvY: TaggedValue ) -> (Double, Double, Double, Double) {
//        
//        func rowMinMax( _ row: Int ) -> (Double, Double) {
//            
//            var (minY, maxY) = ( tvY.getReal(row,1), tvY.getReal(row,1) )
//            
//            for c in 1 ... tvY.cols {
//                minY = min(minY, tvY.getReal(row,c) )
//                maxY = max(maxY, tvY.getReal(row,c) )
//            }
//            return (minY, maxY)
//        }
//        
//        guard
//            tvX.isMatrix && tvY.isMatrix &&
//            tvX.cols == 1 && tvX.rows > 1 && tvX.vtp == .real &&
//            tvY.rows == tvX.rows && tvY.vtp == .real
//        else {
//            // Should not happen because pattern is checked
//            assert(false)
//            return (0.0, 0.0, 0.0, 0.0)
//        }
//        
//        let n = tvX.rows
//        
//        var xMin = tvX.getReal(1)
//        var xMax = xMin
//        
//        var yMin = tvY.getReal(1,1)
//        var yMax = yMin
//        
//        for r in 2...n {
//            let x = tvX.getReal(r)
//            xMin = min( xMin, x )
//            xMax = min( xMax, x )
//
//            let (minY, maxY) = rowMinMax(r)
//            yMin = min( yMin, minY )
//            yMax = max( yMax, maxY )
//        }
//        return (xMin, yMin, xMax, yMax)
//    }
//    
//    
//    var body: some View {
//        let tvX = model.state.Xtv
//        let tvY = model.state.Ytv
//
//        let (xMin, yMin, xMax, yMax) = getRange( tvX, tvY )
//        
//        VStack {
//            AuxHeaderView( theme: Theme.lightPurple ) {
//                RichText( "Vector Plot", size: .small )
//            }
//            
//            Canvas { context, size in
//                
//                // Entire viewport of the Canvas
//                let viewRect = CGRect( origin: CGPoint.zero, size: size )
//                
//                // Confine our plot to this area
//                let plotRect = viewRect.insetTo( fraction: 0.95 )
//                
//                context.withWindowContext( plotRect, within: viewRect ) { ctx, winRect in
//                    
//                    // Width and Height of plot window
//                    let (wW, hW) = (winRect.width, winRect.height)
//                    
//                    // Range of our data values
//                    let (xRange, yRange) = (xMax - xMin, yMax - yMin)
//                    
//                    // Scale factor for y within plot
//                    var sy = 0.75
//                    sy *= hW/abs(yRange)
//                    
//                    let sx = wW/abs(xRange)
//                    
//                    // Compute origin point
//                    let (xO, yO) = ( xRange/2 + xMin, yRange/2 + yMin )
//                    
//                    // Origin in window space
//                    let (xWO, yWO) = ( wW/2 - xO*sxy, hW/2 - yO*sxy)
//                    
//                    // Find axis co-ordinates and origin point
//                    let (xFrom, xTo) = ( CGPoint( x: 0, y: yWO), CGPoint( x: wW - 10, y: yWO) )
//                    let (yFrom, yTo) = ( CGPoint( x: xWO, y: 0), CGPoint( x: xWO, y: hW - 10) )
//                    
//                    // X Axis
//                    ctx.arrow( from: xFrom, to: xTo )
//                    
//                    // Y Axis
//                    ctx.arrow( from: yFrom, to: yTo )
//                    
//                    // Axis Labels
//                    let font = Font.custom("Times New Roman", size: 16).italic().bold()
//                    let ( xAxisStr, yAxisStr ) = tv.vtp == .complex ? ("Re", "Im") : ("X", "Y")
//                    context.text( xAxisStr, font: font, color: .blue, at: CGPoint(x: xTo.x + 10, y: xTo.y), in: ctx )
//                    context.text( yAxisStr, font: font, color: .blue, at: CGPoint(x: yTo.x, y: yTo.y + 10), in: ctx )
//                    
//                    // Shift context to origin
//                    ctx.withTransform( dx: xWO, dy: yWO ) { ptx in
//                        
//                        let n = tv.rows
//                        let (x1, y1) = tv.getVector(1)
//                        var points = [CGPoint( x: x1 * sxy, y: y1 * sxy )]
//                        
//                        for r in 2...n {
//                            let (x, y) = tv.getVector(r)
//                            points.append( CGPoint( x: x * sxy, y: y * sxy ) )
//                        }
//                        
//                        // Plot lines
//                        let ss = StrokeStyle( lineWidth: 2 )
//                        ptx.multiline( points: points, with: .color(.blue), style: ss )
//                    }
//                }
//            }
//            .padding(10)
//        }
//    }
//}


struct ValuePlotView_Previews: PreviewProvider {
    
    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
        let newModel = model
        
        // FIX: MacroKey not working here, keys not defined yet?
        newModel.state.Xtv = TaggedValue(.real, reg: 3.33)
        return newModel
    }
    
    static var previews: some View {
        @StateObject  var model = MacroListView_Previews.addSampleMacro( CalculatorModel())
        
        ZStack {
            Rectangle()
                .fill(Color("Background"))
                .edgesIgnoringSafeArea( .all )
            
            VStack {
                VStack {
                    PlotPointsView( model: model)
                        .frame( maxWidth: .infinity, maxHeight: .infinity)
                        .preferredColorScheme(.light)
                }
                .padding([.leading, .trailing, .top, .bottom], 0)
                .background( Color("Display") )
                .border(Color("Frame"), width: 3)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
            .background( Color("Background"))
        }
    }
}

