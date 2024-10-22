//
//  ContentView.swift
//  Softkey
//
//  Created by Barry Hall on 2024-10-06.
//

import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// **********************************************

typealias KeyID = Int

typealias  KeyEvent = KeyCode

protocol KeyPressHandler {
    func keyPress(_ event: KeyEvent )
}

struct KeySpec {
    var width: Double
    var height: Double
    var fontSize:Double = KeySpec.defFontSize
    var keyColor: Color = KeySpec.defKeyColor
    var textColor: Color = KeySpec.defTextColor
    var radius: Double = KeySpec.defRadius
    
    static let defFontSize  = 18.0
    static let defRadius    = 10.0
    static let defKeyColor  = Color(.brown)
    static let defTextColor = Color(.white)
}


struct Key: Identifiable {
    var kc: KeyCode
    var size: Int           // Either 1 or 2, single width keys or double width
    var text: String?
    var fontSize: Double?
    var image: ImageResource?
    
    var id: Int { return self.kc.rawValue }

    init( _ kc: KeyCode, _ label: String? = nil, size: Int = 1, fontSize: Double? = nil, image: ImageResource? = nil ) {
        self.kc = kc
        self.text = label
        self.size = size
        self.image = image
        self.fontSize = fontSize
    }
}

struct SubPadSpec {
    var kc: KeyCode
    var keySpec: KeySpec
    var keys: [Key]
    var fontSize: Double
    var caption: String?

    static var specList: [KeyCode : SubPadSpec] = [:]
    
    static func define( _ kc: KeyCode, keySpec: KeySpec, keys: [Key], fontSize: Double = 18.0, caption: String? = nil ) {
        SubPadSpec.specList[kc] =
            SubPadSpec( kc: kc, keySpec: keySpec, keys: keys, fontSize: fontSize, caption: caption)
    }
}

struct PadSpec {
    var keySpec: KeySpec
    var cols: Int
    var keys: [Key]
    var fontSize: Double = 18.0
    var caption: String?
}


// ****************************************************

class KeyData : ObservableObject {
    //    Origin of pressed key rect
    //    Rect of outer ZStack
    //    Point of dragged finger
    //    Key struct of pressed key
    //
    var zFrame: CGRect      = CGRect.zero
    var subPad: SubPadSpec? = nil
    var keyOrigin: CGPoint  = CGPoint.zero
    var popFrame: CGRect    = CGRect.zero
    var pressedKey: Key?    = nil
    var selSubkey: Key?     = nil
    var selSubIndex: Int    = -1

    @Published var dragPt   = CGPoint.zero
    @Published var keyDown  = false
    @Published var hello    = "Hello"
}


let longPressTime = 0.5
let keyInset      = 4.0
let keyHspace     = 10.0
let keyVspace     = 10.0
let popCaptionH   = 13.0
let captionFont   = 12.0


struct ModalBlock: View {
    @EnvironmentObject var keyData: KeyData

    var body: some View {
        if keyData.keyDown {
            // Transparent rectangle to block all key interactions below the popup - opacity 0 passes key presses through
            Rectangle()
                .opacity(0.0001)
        }
    }
}


struct SubPopMenu: View {
    @EnvironmentObject var keyData: KeyData
    
    var body: some View {
        if keyData.keyDown {
            let keySpec = keyData.subPad!.keySpec
            let n = keyData.subPad!.keys.count
            let keyW = keySpec.width
            let keyH = keySpec.height
            let nkeys = 0..<n
            let subkeys = nkeys.map { keyData.subPad!.keys[$0] }
            let w = keyData.popFrame.width
            let keyRect = CGRect( origin: CGPoint.zero, size: CGSize( width: keyW, height: keyH)).insetBy(dx: keyInset/2, dy: keyInset/2)
            let keySet  = nkeys.map { keyRect.offsetBy( dx: keySpec.width*Double($0), dy: 0.0) }
            let zOrigin = keyData.zFrame.origin
            let popH = keyData.subPad!.caption == nil ? keyH + keyInset : keyH + keyInset + popCaptionH
            
//            Canvas { gc, size in
//                gc.translateBy(x: size.width / 2, y: size.height / 2)
//                let rectangle = Rectangle().path(in: .zero.insetBy(dx: -5, dy: -5))
//                gc.fill(rectangle, with: .color(.green))
//            }
//
            Rectangle()
                .frame( width: w + keyInset, height: popH)
                .foregroundColor(keySpec.keyColor)
                .cornerRadius(keySpec.radius*2)
                .background {
                    RoundedRectangle(cornerRadius: keySpec.radius*2)
                        .shadow(radius: keySpec.radius*2)
                }
                .overlay {
                    GeometryReader { geo in
                        let hframe = geo.frame(in: CoordinateSpace.global)
                        
                        VStack(spacing: 0) {
                            if let caption = keyData.subPad!.caption {
                                HStack {
                                    Text(caption)
                                        .bold()
                                        .font(.system(size: captionFont))
                                        .foregroundColor(keySpec.textColor)
                                        .frame( maxWidth: .infinity, alignment: .leading)
                                        .offset( x: 10, y: 4 )
//                                    Spacer()
                                }
                            }
                            HStack( spacing: keyInset ) {
                                ForEach(nkeys, id: \.self) { kn in
                                    let r = keySet[kn].offsetBy(dx: hframe.origin.x, dy: hframe.origin.y)
                                    let key = subkeys[kn]
                                    
                                    Rectangle()
                                        .frame( width: r.width, height: r.height )
                                        .cornerRadius(keySpec.radius)
                                        .foregroundColor( kn == keyData.selSubIndex  ?  Color.blue : keySpec.keyColor)
                                        .if( key.text != nil ) { view in
                                            view.overlay(
                                                Text( key.text! )
                                                    .font(.system(size: key.fontSize != nil ? key.fontSize! : keyData.subPad!.fontSize))
                                                    .bold()
                                                    .foregroundColor(keySpec.textColor))
                                        }
                                        .if ( key.image != nil ) { view in
                                            view.overlay(
                                                Image(key.image!).renderingMode(.template).foregroundColor(keySpec.textColor), alignment: .center)
                                        }
                                }
                            }
                            .padding(.leading, keyInset)
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                    }
                }
                .position(x: keyData.popFrame.minX - zOrigin.x + w/2, y: keyData.keyOrigin.y - zOrigin.y - keyData.popFrame.height/2 - keySpec.radius )
        }
    }
}


// ****************************************************

struct KeyView: View {
    let padSpec: PadSpec
    let key: Key
    let keyPressHandler: KeyPressHandler

    @EnvironmentObject var keyData: KeyData
    
    // For long press gesture - finger is down
    @GestureState private var isPressing = false
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    private func hitRect( _ r:CGRect ) -> CGRect {
        // Expand a rect to allow hits below the rect so finger does not block key
        r.insetBy(dx: 0.0, dy: -padSpec.keySpec.height*2)
    }
    
    private func computeSubpadGeometry() {
        let n = keyData.subPad!.keys.count
        let keyW = padSpec.keySpec.width
        let keyH = padSpec.keySpec.height
        let nkeys = 0..<n
        let popW = keyW * Double(n)
        let zOrigin = keyData.zFrame.origin
        
        // Keys leading edge x value relative to zFrame
        let xKey = keyData.keyOrigin.x - zOrigin.x
        
        // Set of all possible x position values for popup
        let xSet = nkeys.map( { xKey - Double($0)*keyW } )
        
        // Filter out values where the popup won't fit in the Z frame
        let xSet2 = xSet.filter( { x in x >= 0 && (x + popW) <= keyData.zFrame.maxX })
        
        // Sort by distance from mid popup to mid key
        let xSet3 = xSet2.sorted() { x1, x2 in
            let offset = popW/2 - xKey - keyW/2
            return abs(x1+offset) < abs(x2+offset)
        }
        
        // Choose the value that optimally centers the popup over the key
        let xPop = xSet3[0]
        
        // Popup height is augmented if the pop spec includes a caption
        let popH = padSpec.caption == nil ? keyH : keyH*2 + popCaptionH
        
        // Write popup location and size to state object
        keyData.popFrame = CGRect( x: xPop + zOrigin.x, y: keyData.keyOrigin.y - keyH - padSpec.keySpec.radius,
                                   width: popW, height: popH)
    }
    
    private func trackDragPt() {
        if let subPad = keyData.subPad {
            if hitRect(keyData.popFrame).contains(keyData.dragPt) {
                let x = Int( (keyData.dragPt.x - keyData.popFrame.minX) / padSpec.keySpec.width )
                
                let newKey = subPad.keys.indices.contains(x) ? subPad.keys[x] : nil
                
                if let new = newKey {
                    if keyData.selSubkey == nil || keyData.selSubkey!.kc != new.kc {
                        hapticFeedback.impactOccurred()
                    }
                }
                keyData.selSubkey = newKey
                keyData.selSubIndex = x
            }
            else {
                keyData.selSubkey = nil
                keyData.selSubIndex = -1
            }
        }
    }
    
    var drag: some Gesture {
        DragGesture( minimumDistance: 0, coordinateSpace: .global)
            .onChanged { info in
                // Track finger movements
                keyData.dragPt = info.location
                trackDragPt()
            }
            .onEnded { _ in
                if let key = keyData.selSubkey
                {
                    if let txt = key.text {
                        keyData.hello.append("\nKeypress: \(txt)")
                    }
                    else {
                        keyData.hello.append("\nKeypress: ??")
                    }
                    
                     keyPressHandler.keyPress(key.kc)
                }
                
                keyData.dragPt = CGPoint.zero
                keyData.selSubkey = nil
                keyData.pressedKey = nil
            }
    }
    
    
    var yellowCircle: some View {
        Circle()
            .foregroundStyle(.yellow)
            .frame(width: 5, height: 5)
    }
    
    
    
    var body: some View {

        let keyW = padSpec.keySpec.width * Double(key.size) + Double(key.size - 1) * keyHspace
        
        let hasSubpad = SubPadSpec.specList[key.kc] != nil
        
        VStack {
            let txt = key.text ?? "??"
            
            GeometryReader { geometry in
                let vframe = geometry.frame(in: CoordinateSpace.global)
                
                let longPress =
                LongPressGesture( minimumDuration: longPressTime)
                    .sequenced( before: drag )
                    .updating($isPressing) { value, state, transaction in
                        switch value {
                            
                        case .second(true, nil):
                            if let subpad = SubPadSpec.specList[key.kc] {
                                // Start finger tracking
                                keyData.subPad = subpad
                                keyData.keyOrigin = vframe.origin
                                keyData.pressedKey = key
                                
                                computeSubpadGeometry()
                                                                
                                // This will pre-select the subkey option above the pressed key
                                keyData.dragPt = CGPoint( x: vframe.midX, y: vframe.minY)
                                trackDragPt()

                                // Initiate popup menu
                                state = true
                            }
                            
                        default:
                            break
                        }
                    }
                
                Rectangle()
                    .foregroundColor( Color.brown )
                    .frame( width: keyW, height: padSpec.keySpec.height )
                    .cornerRadius( padSpec.keySpec.radius )
                    .simultaneousGesture( longPress )
                    .onChange( of: isPressing) { _, newState in keyData.keyDown = newState }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            keyData.hello.append("\nRegular tap: \(txt)")
                            hapticFeedback.impactOccurred()
                            keyPressHandler.keyPress(key.kc)
                        })
                    .if( key.text != nil ) { view in
                        view.overlay(
                            Text( key.text! )
                                .font(.system(size: key.fontSize != nil ? key.fontSize! : padSpec.fontSize ))
                                .bold()
                                .foregroundColor(Color.white) )
                    }
                    .if ( key.image != nil ) { view in
                        view.overlay(
                            Image(key.image!).renderingMode(.template).foregroundColor(padSpec.keySpec.textColor), alignment: .center)
                    }
                    .if( hasSubpad ) { view in
                        view.overlay(alignment: .topTrailing) {
                            yellowCircle
                                .alignmentGuide(.top) { $0[.top] - 3}
                                .alignmentGuide(.trailing) { $0[.trailing] + 3 }
                        }
                    }
            }
            
        }
        .frame( maxWidth: keyW, maxHeight: padSpec.keySpec.height )
        // .border(.blue)
    }
}


struct KeypadView: View {
    let padSpec: PadSpec
       
    let keyPressHandler: KeyPressHandler
 
    @EnvironmentObject var keyData: KeyData

    private func partitionKeylist( keys: [Key], rowMax: Int ) -> [[Key]] {
        /// Breakup list of keys into list of rows
        /// Count double or triple width keys as 2 or 3 keys
        /// Do not exceed rowMax keys per row
        var res: [[Key]] = []
        var keylist = keys
        var part: [Key] = []
        var rowCount = 0
        
        while !keylist.isEmpty {
            let key1 = keylist.removeFirst()
            
            if rowCount + key1.size <= rowMax {
                part.append(key1)
                rowCount += key1.size
            }
            else {
                res.append(part)
                part = [key1]
                rowCount = key1.size
            }
        }
        if !part.isEmpty {
            res.append(part)
        }
        
        return res
    }

    var body: some View {
        let keyMatrix = partitionKeylist(keys: padSpec.keys, rowMax: padSpec.cols)
        
        VStack( spacing: keyVspace ) {
            ForEach( 0..<keyMatrix.count, id: \.self) { cx in
                
                HStack( spacing: keyHspace ) {
                    let keys = keyMatrix[cx]
                    
                    ForEach( 0..<keys.count, id: \.self) { kx in
                        let key = keys[kx]
                        
                        KeyView( padSpec: padSpec, key: key, keyPressHandler: keyPressHandler )
                    }
                }
                // Padding and border around key hstack
                .padding(0)
//                .border(.red)
            }
        }
        .border(.green)
        .padding(0)
    }
}


struct KeyStack<Content: View>: View {
    @StateObject var keyData = KeyData()
    
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            content
            
            ModalBlock()
            
            SubPopMenu()
        }
        .onGeometryChange( for: CGRect.self, of: {proxy in proxy.frame(in: .global)} ) { newValue in
            keyData.zFrame = newValue
        }
        .border(.brown)
        .padding()
        .alignmentGuide(HorizontalAlignment.leading) { _ in  0 }
        .environmentObject(keyData)
    }
}


//#Preview {
//    KeyStack() {
//        
//    }
//}
