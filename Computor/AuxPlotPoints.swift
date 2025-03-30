//
//  AuxPlotPoints.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-06.
//
import SwiftUI


struct PlotPointsView: View {
    
    let pointTypes: Set<ValueType> = [.complex, .vector, .polar]
    
    func getRange( _ tv: TaggedValue ) -> (Double, Double, Double, Double) {
        
        guard tv.isMatrix && tv.cols == 1 && tv.rows > 1 && pointTypes.contains(tv.vtp) else {
            return (0.0, 0.0, 0.0, 0.0)
        }
        
        let n = tv.rows
        
        var (xMin, yMin) = tv.getVector(1,1)
        var (xMax, yMax) = (xMin, yMin)
        
        for r in 2...n {
            let (x, y) = tv.getVector(r)
            xMin = min(x, xMin)
            yMin = min(y, yMin)
            xMax = max(x, xMax)
            yMax = max(y, yMax)
        }
        
        return (xMin, yMin, xMax, yMax)
    }
    
    
    func plotableValue( _ tv: TaggedValue ) -> Bool {
        
        // Require a matrix of rows of vector types or complex
        tv.isMatrix && tv.cols == 1 && tv.rows > 1 && pointTypes.contains(tv.vtp)
    }
    
    
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        let tv = model.state.Xtv
        
        let (xMin, yMin, xMax, yMax) = getRange(tv)
        
        VStack {
            AuxHeaderView( theme: Theme.lightPurple ) {
                RichText( "Vector Plot", size: .small )
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
                            let (x1, y1) = tv.getVector(1)
                            var points = [CGPoint( x: x1 * sxy, y: y1 * sxy )]
                        
                            for r in 2...n {
                                let (x, y) = tv.getVector(r)
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

