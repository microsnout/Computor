//
//  AuxPlotVector.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-07.
//
import SwiftUI


enum Quadrant {
    case UR, UL, LL, LR
    
    static func fromXY( _ x: Double, _ y: Double ) -> Quadrant {
         return (x < 0) ? ( (y < 0) ? Quadrant.LL : Quadrant.UL ) : ( (y < 0) ? Quadrant.LR : Quadrant.UR )
    }
}


extension CGRect {
    
    func insetTo( fraction f: Double ) -> CGRect {
        // Return a rectangle inset to f*100 % of original size
        let insetScale = (1.0 - f)/2.0
        return self.insetBy( dx: width*insetScale, dy: height*insetScale )
    }
}

private func arrowPath() -> Path {
    Path { path in
        path.move(to: CGPoint( x: 2, y: 0.0 ) )
        path.addLine(to: .init(x: -10.0, y: 5.0))
        path.addLine(to: .init(x: -10.0, y: -5.0))
        path.closeSubpath()
    }
}

private func arrowTransform( lastPoint: CGPoint, previousPoint: CGPoint ) -> CGAffineTransform {
    let translation = CGAffineTransform( translationX: lastPoint.x, y: lastPoint.y)
    let angle = atan2( lastPoint.y-previousPoint.y, lastPoint.x-previousPoint.x )
    let rotation = CGAffineTransform( rotationAngle: angle)
    return rotation.concatenating(translation)
}


extension GraphicsContext {
    
    func withWindowContext( _ winR: CGRect, within canvasR: CGRect, scaleBy s: Double = 1.0, block: (GraphicsContext, CGRect) -> Void ) {
        // Temporary copy of context
        var ctx = self
        
        // Establish window as defined with +ve Y axis
        ctx.transform = CGAffineTransform( a: s, b: 0, c: 0, d: -s,
                                           tx: winR.minX - canvasR.minX,
                                           ty: canvasR.height - (winR.minY - canvasR.minY) )
        
        block( ctx, CGRect( origin: CGPoint.zero, size: winR.size ) )
    }
    
    
    func arrow( from: CGPoint, to: CGPoint, with shading: GraphicsContext.Shading = .color(.black) ) {
        
        stroke(
            Path { path in
                path.addLines( [from, to] )
            },
            with: shading,
            lineWidth: 3)
        
        fill(
            arrowPath().applying( arrowTransform( lastPoint: to, previousPoint: from ) ),
            with: shading
        )
    }
}


struct PlotVectorView : View {
    
    @StateObject var model: CalculatorModel
    
    
    private func getSpecs( _ tv: TaggedValue ) -> (Double, Double, Double, Double) {
        
        guard tv.isSimple else { return (0, 0, 0, 0) }
        
        switch tv.vtp {
        case .complex:
            let z = tv.getComplex()
            return (z.real, z.imaginary, z.length, z.phase)
            
        case .vector, .polar:
            let (x, y) = tv.getVector2D()
            let (r, a) = rect2polar(x, y)
            return (x, y, r, a)
            
        case .real:
            let x = tv.getReal()
            let (r, a) = rect2polar(x, 0)
            return (x, 0, r, a)
            
        default:
            return (0, 0, 0, 0)
        }
    }


    var body: some View {
        
        var nv = model.state.stack[regX]
        
        let (x, y, length, angle) = getSpecs( nv.value )
        
        let quad = Quadrant.fromXY(x,y)
        
        
        Canvas(
            opaque: false,
            colorMode: .linear,
            rendersAsynchronously: false
            
        ) { context, size in
            
            // Entire viewport of the Canvas
            let viewRect = CGRect( origin: CGPoint.zero, size: size )
            
            // Confine our plot to this area
            let plotRect = viewRect.insetTo( fraction: 0.8 )

            // Tail of axis - extending into unused quadrant
            let tail = 20.0

            // Origin of plot within window
            let (xO, yO) = ( tail, tail )
            
            context.withWindowContext( plotRect, within: viewRect ) { ctx, winRect in
                
                // Extent of axis not including tail
                let (extX, extY) = ( winRect.width - tail, winRect.height - tail )

                // Scale factor for x and y within plot
                var sxy = 0.6

                // Sample x,y values
//                let (x, y) = (3.0, 5.0)
                
                // Width and Height of plot window
                let (wW, hW) = (winRect.width, winRect.height)
                
                if hW/wW > abs(y)/abs(x) {
                    // Plot will terminate at X extent
                    sxy *= wW/x
                }
                else {
                    // Plot will terminate at Y extent
                    sxy *= hW/y
                }
                
                // X Axis
                ctx.arrow( from: CGPoint( x: 0, y: tail ), to: CGPoint( x: winRect.maxX, y: tail) )
                
                // Y Axis
                ctx.arrow( from: CGPoint( x: tail, y: 0 ), to: CGPoint( x: tail, y: winRect.maxY ) )
                
                // Vector Line
                ctx.arrow( from: CGPoint(x: xO, y: yO), to: CGPoint( x: xO + x*sxy, y: xO + y*sxy), with: .color(.blue) )
                
                // Red dot
                ctx.fill(
                    Path(
                        ellipseIn: CGRect(
                            origin: CGPoint( x: xO + x*sxy, y: xO + y*sxy),
                            size: CGSize( width: 8, height: 8 ) ).offsetBy( dx: -4, dy: -4 ) ),
                    with: .color(.red))
            }
        }
        .padding(10)
    }
}


struct PlotVectorView_Previews: PreviewProvider {
    
    static func addSampleMacro( _ model: CalculatorModel ) -> CalculatorModel {
        var newModel = model
        
        // FIX: MacroKey not working here, keys not defined yet?
        newModel.state.setComplexValue( Comp(4.0, 3.0) )
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
                    PlotVectorView( model: model)
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

