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
        ctx.concatenate( CGAffineTransform( a: s, b: 0, c: 0, d: -s,
                                            tx: winR.minX - canvasR.minX,
                                            ty: canvasR.height - (winR.minY - canvasR.minY) ) )
        
        block( ctx, CGRect( origin: CGPoint.zero, size: winR.size ) )
    }

    func withTransform( dx: Double, dy: Double, scaleBy s: Double = 1.0, flip: Bool = false, block: (GraphicsContext) -> Void ) {
        // Temporary copy of context
        var ctx = self
        
        // Establish window as defined with +ve Y axis
        ctx.concatenate( CGAffineTransform( a: s, b: 0, c: 0, d: flip ? -s : s, tx: dx, ty: dy ) )
        
        block( ctx )
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

    
    func line( from: CGPoint, to: CGPoint, with shading: GraphicsContext.Shading = .color(.black), style: StrokeStyle = StrokeStyle() ) {
        
        stroke(
            Path { path in
                path.addLines( [from, to] )
            },
            with: shading,
            style: style
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
    
    
    private func computeAxis( _ win: CGRect, _ quad: Quadrant, tail t: Double ) -> ( CGPoint, CGPoint, CGPoint, CGPoint, CGPoint ) {
        
        func pt( _ x: Double, _ y: Double ) -> CGPoint {
            CGPoint( x: x, y: y )
        }
        
        let (w, h) = (win.width, win.height)
        
        switch quad {
            case .UR: return ( pt(0,t), pt(w,t), pt(t,0), pt(t,h), pt(t,t) )
            
            case .LR: return ( pt(0,h-t), pt(w,h-t), pt(t,0), pt(t,h), pt(t,h-t) )

            case .LL: return ( pt(0,h-t), pt(w,h-t), pt(w-t,0), pt(w-t,h), pt(w-t,h-t) )
            
            case .UL: return ( pt(0,t), pt(w,t), pt(w-t,0), pt(w-t,h), pt(w-t,t) )
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
            let tail = 25.0

            context.withWindowContext( plotRect, within: viewRect ) { ctx, winRect in
                
                // Extent of axis not including tail
                let (extX, extY) = ( winRect.width - tail, winRect.height - tail )

                // Sample x,y values
//                let (x, y) = (3.0, 5.0)
                
                // Width and Height of plot window
                let (wW, hW) = (winRect.width, winRect.height)

                // Scale factor for x and y within plot
                var sxy = 0.6

                if hW/wW > abs(y)/abs(x) {
                    // Plot will terminate at X extent
                    sxy *= wW/abs(x)
                }
                else {
                    // Plot will terminate at Y extent
                    sxy *= hW/abs(y)
                }
                
                // Find axis co-ordinates and origin point
                let (xFrom, xTo, yFrom, yTo, origin) = computeAxis(winRect, Quadrant.fromXY(x,y), tail: tail)
                
                // X Axis
                ctx.arrow( from: xFrom, to: xTo )
                
                // Y Axis
                ctx.arrow( from: yFrom, to: yTo )
                
                let font = Font.custom("Times New Roman", size: 24)
                
                let textRe = context.resolve( Text("Re").font(font).italic().foregroundColor(.blue) )
                let textIm = context.resolve( Text("Im").font(font).italic().foregroundColor(.blue) )

                let ptRe = CGPoint(x: xTo.x, y: 0)
                let ptIm = CGPoint(x: 0, y: yTo.y)

                let ptReCanvas = ptRe.applying( ctx.transform)
                let ptImCanvas = ptIm.applying( ctx.transform)

                context.draw( textRe, at: ptReCanvas)
                context.draw( textIm, at: ptImCanvas)

                // Shift context to origin
                ctx.withTransform( dx: origin.x, dy: origin.y ) { ptx in
                    
                    // Scaled vector end point
                    let pt = CGPoint( x: x * sxy, y: y * sxy)
                    
                    // Vector Line
                    ptx.arrow( from: .zero, to: pt, with: .color(.blue) )
                    
                    // Dashed lines to Axis from Pt
                    let ss = StrokeStyle(lineWidth: 2, dash: [5] )
                    ptx.line( from: CGPoint( x: 0, y: pt.y), to: pt, with: .color(.gray), style: ss )
                    ptx.line( from: CGPoint( x: pt.x, y: 0), to: pt, with: .color(.gray), style: ss )
                    
                    // Red dot
                    ptx.fill(
                        Path(
                            ellipseIn: CGRect(
                                origin: pt,
                                size: CGSize( width: 8, height: 8 ) ).offsetBy( dx: -4, dy: -4 ) ),
                        with: .color(.red))
                }
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

