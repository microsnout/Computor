//
//  AuxPlotPoints.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-06.
//
import SwiftUI


struct PlotPointsView: View {
    
    func getRange( _ tv: TaggedValue ) -> (Double, Double, Double, Double, Bool) {
        
        guard tv.isMatrix && tv.rows == 1 && tv.cols > 1 && vector2DTypes.contains(tv.vtp) else {
            return (0.0, 0.0, 0.0, 0.0, false)
        }
        
        let n = tv.cols
        
        var (xMin, yMin) = tv.getVector( r: 1, c: 1)
        var (xMax, yMax) = (xMin, yMin)
        
        for c in 2...n {
            let (x, y) = tv.getVector( c: c)
            xMin = min(x, xMin)
            yMin = min(y, yMin)
            xMax = max(x, xMax)
            yMax = max(y, yMax)
        }
        
        return (xMin, yMin, xMax, yMax, true)
    }
    
    
    func plotableValue( _ tv: TaggedValue ) -> Bool {
        
        // Require a row matrix of vector types or complex
        tv.isMatrix && tv.rows == 1 && tv.cols > 1 && vector2DTypes.contains(tv.vtp)
    }
    
    
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let tv = model.state.Xtv
        
        let (xMin, yMin, xMax, yMax, dataValid) = getRange(tv)
        
        if !dataValid {
            // We have been accessed with invalid state
            VStack {}
        }
        else {
            VStack {
                AuxHeaderView( theme: Theme.lightPurple ) {
                    RichText( "Vector Plot", size: .small, weight: .bold, defaultColor: "AuxHeaderText" )
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
                                
                                let n = tv.cols
                                let (x1, y1) = tv.getVector( c: 1)
                                var points = [CGPoint( x: x1 * sxy, y: y1 * sxy )]
                                
                                for c in 2...n {
                                    let (x, y) = tv.getVector( c: c)
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
}


struct PlotMultiPointView: View {
    
    @StateObject var model: CalculatorModel
    
    let colorSeq = [Color.black, Color.blue, Color.red, Color.green, Color.orange]

    func getRange( _ tvX: TaggedValue, _ tvY: TaggedValue ) -> (Double, Double, Double, Double, Bool) {
        
        func colMinMax( _ col: Int ) -> (Double, Double) {
            
            var (minY, maxY) = ( tvY.getReal( r: 1, c: col), tvY.getReal( r: 1, c: col) )
            
            for r in 1 ... tvY.rows {
                minY = min(minY, tvY.getReal( r: r, c: col) )
                maxY = max(maxY, tvY.getReal( r: r, c: col) )
            }
            return (minY, maxY)
        }
        
#if DEBUG
        print( "XXX MultiPoint" )
#endif
        
        guard
            tvX.isMatrix && tvY.isMatrix &&
            tvX.rows == 1 && tvX.cols > 1 && tvX.vtp == .real &&
            tvY.cols == tvX.cols && tvY.vtp == .real
        else {
            // Should not happen because pattern is checked
            // Cannot put an assert here because it will hit for some reason
            return (0.0, 0.0, 0.0, 0.0, false)
        }
        
        let n = tvX.cols
        
        var xMin = tvX.getReal( c: 1 )
        var xMax = xMin
        
        var yMin = tvY.getReal( r: 1, c: 1)
        var yMax = yMin
        
        for c in 2...n {
            let x = tvX.getReal( c: c )
            xMin = min( xMin, x )
            xMax = max( xMax, x )

            let (minY, maxY) = colMinMax(c)
            yMin = min( yMin, minY )
            yMax = max( yMax, maxY )
        }
        return (xMin, yMin, xMax, yMax, true)
    }
    
    
    var body: some View {
        let _ = Self._printChanges()
        
        let tvX = model.state.Xtv
        let tvY = model.state.Ytv

        let (xMin, yMin, xMax, yMax, dataValid) = getRange( tvX, tvY )
        
        if !dataValid {
            // We have been accessed with invalid state
            VStack {}
        }
        else {
            VStack {
                AuxHeaderView( theme: Theme.lightPurple ) {
                    RichText( "Multi Plot", size: .small, defaultColor: "AuxHeaderText" )
                }
                
                Canvas { context, size in
                    
                    // Entire viewport of the Canvas
                    let viewRect = CGRect( origin: CGPoint.zero, size: size )
                    
                    // Confine our plot to this area
                    let plotRect = viewRect.insetTo( fraction: 0.95 )
                    
                    context.withWindowContext( plotRect, within: viewRect ) { ctx, winRect in
                        
                        // Width and Height of plot window
                        let (wW, hW) = (winRect.width, winRect.height)
                        
                        // Range of our data values
                        let (xRange, yRange) = (xMax - xMin, yMax - yMin)
                        
                        // Scale factor for y within plot
                        var sy = 0.75
                        sy *= hW/abs(yRange)
                        
                        // Scale factor for x within plot
                        let sx = wW/abs(xRange)
                        
                        // Compute origin point
                        let (xO, yO) = ( xRange/2 + xMin, yRange/2 + yMin )
                        
                        // Origin in window space
                        let (xWO, yWO) = ( wW/2 - xO*sx, hW/2 - yO*sy)
                        
                        // Find axis co-ordinates and origin point
                        let (xFrom, xTo) = ( CGPoint( x: 0, y: yWO), CGPoint( x: wW, y: yWO) )
                        let (yFrom, yTo) = ( CGPoint( x: xWO, y: 0), CGPoint( x: xWO, y: hW - 10) )
                        
                        // X Axis
                        ctx.arrow( from: xFrom, to: xTo )
                        
                        // Y Axis
                        ctx.arrow( from: yFrom, to: yTo )
                        
                        // Axis Labels
                        let font = Font.custom("Times New Roman", size: 16).italic().bold()
                        let ( xAxisStr, yAxisStr ) = ("X", "Y")
                        context.text( xAxisStr, font: font, color: .blue, at: CGPoint(x: xTo.x, y: xTo.y + 10), in: ctx )
                        context.text( yAxisStr, font: font, color: .blue, at: CGPoint(x: yTo.x, y: yTo.y + 10), in: ctx )
                        
                        // Shift context to origin
                        ctx.withTransform( dx: xWO, dy: yWO ) { ptx in
                            
                            let n = tvX.cols
                            
                            for row in 1 ... tvY.rows {
                                
                                let (x1, y1) = ( tvX.getReal( c: 1 ), tvY.getReal( r: row, c: 1 ) )
                                var points = [CGPoint( x: x1 * sx, y: y1 * sy )]
                                
                                for col in 2...n {
                                    let (x, y) = ( tvX.getReal( c: col ), tvY.getReal( r: row, c: col ) )
                                    points.append( CGPoint( x: x * sx, y: y * sy ) )
                                }
                                
                                // Plot lines
                                let ss = StrokeStyle( lineWidth: 2 )
                                let color = colorSeq[row]
                                ptx.multiline( points: points, with: .color(color), style: ss )
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
    }
}


//struct ValuePlotView_Previews: PreviewProvider {
//    
//    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
//        let newModel = model
//        
//        // FIX: MacroKey not working here, keys not defined yet?
//        newModel.state.Xtv = TaggedValue(.real, reg: 3.33)
//        return newModel
//    }
//    
//    static var previews: some View {
//        @StateObject  var model = MacroListView_Previews.addSampleMacro( CalculatorModel())
//        
//        ZStack {
//            Rectangle()
//                .fill(Color("Background"))
//                .edgesIgnoringSafeArea( .all )
//            
//            VStack {
//                VStack {
//                    PlotPointsView( model: model)
//                        .frame( maxWidth: .infinity, maxHeight: .infinity)
//                        .preferredColorScheme(.light)
//                }
//                .padding([.leading, .trailing, .top, .bottom], 0)
//                .background( Color("Display") )
//                .border(Color("Frame"), width: 3)
//            }
//            .padding(.horizontal, 30)
//            .padding(.vertical, 5)
//            .background( Color("Background"))
//        }
//    }
//}

