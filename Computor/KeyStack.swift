//
//  ContentView.swift
//  Computor
//
//  Created by Barry Hall on 2024-10-06.
//

import SwiftUI


typealias KeyID = Int

typealias  KeyEvent0 = KeyCode

struct KeyEvent : Codable {
    var kc: KeyCode
    
    // Top level key like .fn4 when kc is an opcode from a sub popup menu like .rec
    var kcTop: KeyCode?
    
    // Key code from a sub menu like .A when kc is .Sto
    var kcSub: KeyCode?
}

enum KeyPressResult: Int {
    case null = 0,
         noOp,              // No operation, no error. Ignore
         dataEntry,         // Data enty keys like digits, EE
         cancelEntry,       // An undo/back that canceled data entry
         cancelRecording,   // Cancel a Fn key recording
         macroOp,           // A macro control op key like rec, stop, clear
         stateChange,       // The key has produced a successful state change
         stateUndo,         // An undo op, return to previous state
         stateError,        // An error display Error status
         modalFunction,     // Start modal function, no new state yet
         modalFnNewState,    // Start modal function with new state
         recordOnly,
         resendEvent        // Re-dispacth this event because the eventContext has changed
}

protocol KeyPressHandler {
    func keyPress(_ event: KeyEvent ) -> KeyPressResult
}

struct KeySpec {
    var width: Double     = 42
    var height: Double    = 25
    var keyColor: String  = KeySpec.defKeyColor
    var textColor: String = KeySpec.defTextColor
    var radius: Double    = KeySpec.defRadius
    
    static let defRadius    = 10.0
    static let defKeyColor  = "KeyColor"
    static let defTextColor = "KeyText"
}


struct Key: Identifiable {
    var kc: KeyCode
    var size: Int           // Either 1 or 2, single width keys or double width
    var text: String?
    var image: ImageResource?
    var caption: String?
    
    var id: Int { return self.kc.rawValue }
    
    static var keyList: [KeyCode : Key] = [:]

    init( _ kc: KeyCode, _ label: String? = nil, size: Int = 1, image: ImageResource? = nil, caption: String? = nil ) {
        self.kc = kc
        self.text = label
        self.size = size
        self.image = image
        self.caption = caption
        
        // Maintain dictionary of all defined keys
        Key.keyList[self.kc] = self
    }
}

struct SubPadSpec {
    var kc: KeyCode      = .noop
    var keySpec: KeySpec = KeySpec()
    var keys: [Key]      = []
    var caption: String? = nil
    
    func getCaption( keyIndex: Int ) -> String? {
        guard keyIndex >= 0 && keyIndex < keys.count else {
            return caption
        }
        
        return keys[keyIndex].caption ?? self.caption
    }
}


extension SubPadSpec {

    // Dictionary of subpad specs associated with keycodes
    static var specList: [KeyCode : SubPadSpec] = [:]
    
    // Disable the subpad popup if the keycode is in this set
    static var disableList: Set<KeyCode> = []

    static func getSpec( _ kc: KeyCode ) -> SubPadSpec? {
        if SubPadSpec.disableList.contains(kc) {
            // This subpad currently disabled
            return nil
        }
        return SubPadSpec.specList[kc]
    }
    
    static func define( _ kc: KeyCode, keySpec: KeySpec, keys: [Key], caption: String? = nil ) {
        // Add a subpad to the keycode kc
        SubPadSpec.specList[kc] =
            SubPadSpec( kc: kc, keySpec: keySpec, keys: keys, caption: caption)
    }
    
    static func copySpec( from: KeyCode, list: [KeyCode]) {
        if let spec = SubPadSpec.specList[from] {
            // Copy the subpad from one key to many, used for Fn keys
            for kc in list {
                SubPadSpec.specList[kc] = spec
            }
        }
    }
}


struct AltKeySet {
    var kc: KeyCode
    var keys: [Key]
}


struct PadSpec {
    var keySpec: KeySpec = KeySpec()
    var cols: Int        = 1
    var keys: [Key]      = []
    var fontSize: Double = 18.0
    var caption: String? = nil
}


extension PadSpec {
    
    // Dictionary of modal subpad specs associated with keycodes
    static var modalSpecList: [KeyCode : PadSpec] = [:]
    
    static func defineModal( _ kc: KeyCode, _ ps: PadSpec ) {
        // Add a modal subpad to the keycode kc
        PadSpec.modalSpecList[kc] = ps
    }
    
    static func getModalPadSpec( _ kc: KeyCode ) -> PadSpec? {
        PadSpec.modalSpecList[kc]
    }
    
    static func copySpec( from: KeyCode, list: [KeyCode]) {
        if let spec = PadSpec.modalSpecList[from] {
            // Copy the subpad from one key to many, used for Fn keys
            for kc in list {
                PadSpec.modalSpecList[kc] = spec
            }
        }
    }
}


// ****************************************************

class KeyData : ObservableObject {
    //    Origin of pressed key rect
    //    Rect of outer ZStack
    //    Point of dragged finger
    //    Key struct of pressed key
    //
    var zFrame: CGRect      = CGRect.zero
    var subPad: SubPadSpec  = SubPadSpec()
    var keyOrigin: CGPoint  = CGPoint.zero
    var popFrame: CGRect    = CGRect.zero
    var pressedKey: Key?    = nil
    var selSubkey: Key?     = nil
    var selSubIndex: Int    = -1
    var modalPad: PadSpec   = PadSpec()

    @Published var dragPt   = CGPoint.zero
    @Published var keyDown  = false
    @Published var modalUp  = false
}


let longPressTime = 0.5
let keyInset      = 4.0
let keyHspace     = 10.0
let keyVspace     = 8.0
let popCaptionH   = 13.0
let captionFont   = 12.0


struct ModalBlock: View {
    @EnvironmentObject var keyData: KeyData

    var body: some View {
        if keyData.keyDown || keyData.modalUp {
            // Transparent rectangle to block all key interactions below the popup - opacity 0 passes key presses through
            Rectangle()
                .opacity(0.0001)
                .onTapGesture {
                    // Close modal popup
                    keyData.pressedKey = nil
                    keyData.modalPad = PadSpec()
                    keyData.modalUp = false
                }
        }
    }
}


struct SubPopMenu: View {
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsKeyCaptions)
    private var keyCaptions = true

    @EnvironmentObject var keyData: KeyData
    
    var body: some View {
        if keyData.keyDown {
            let keySpec = keyData.subPad.keySpec
            let n = keyData.subPad.keys.count
            let keyW = keySpec.width
            let keyH = keySpec.height
            let nkeys = 0..<n
            let subkeys = nkeys.map { keyData.subPad.keys[$0] }
            let w = keyData.popFrame.width
            let keyRect = CGRect( origin: CGPoint.zero, size: CGSize( width: keyW, height: keyH)).insetBy(dx: keyInset/2, dy: keyInset/2)
            let keySet  = nkeys.map { keyRect.offsetBy( dx: keySpec.width*Double($0), dy: 0.0) }
            let zOrigin = keyData.zFrame.origin
            let popCaptionH = keyCaptions ? 13.0 : 0.0
            let popH = keyData.subPad.caption == nil ? keyH + keyInset : keyH + keyInset + popCaptionH
            
            Rectangle()
                .frame( width: w + keyInset, height: popH)
                .foregroundColor( Color(keySpec.keyColor))
                .cornerRadius(keySpec.radius*2)
                .background {
                    RoundedRectangle(cornerRadius: keySpec.radius*2)
                        .shadow(radius: keySpec.radius*2)
                }
                .shadow( radius: 20 )
                .overlay {
                    GeometryReader { geo in
                        let hframe = geo.frame(in: CoordinateSpace.global)
                        
                        VStack(spacing: 0) {
                            if keyCaptions {
                                if let caption = keyData.subPad.getCaption( keyIndex: keyData.selSubIndex ) {
                                    HStack {
                                        Spacer()
                                        RichText(
                                            caption,
                                            size: .small,
                                            weight: .bold,
                                            design: serifFont ? .serif : .default,
                                            defaultColor: keySpec.textColor ).offset( x: 0, y: 4 )
                                        Spacer()
                                    }
                                }
                            }
                            HStack( spacing: keyInset ) {
                                ForEach(nkeys, id: \.self) { kn in
                                    let r = keySet[kn].offsetBy(dx: hframe.origin.x, dy: hframe.origin.y)
                                    let key = subkeys[kn]
                                
                                    Rectangle()
                                        .frame( width: r.width, height: r.height )
                                        .cornerRadius(keySpec.radius)
                                        .foregroundColor( kn == keyData.selSubIndex  ?  Color("PopSelect") : Color(keySpec.keyColor))
                                        .if( key.text != nil ) { view in
                                            view.overlay(
                                                RichText(
                                                    key.text!,
                                                    size: .small,
                                                    weight: .bold,
                                                    design: serifFont ? .serif : .default,
                                                    defaultColor: "PopText")
                                            )
                                        }
                                        .if ( key.image != nil ) { view in
                                            view.overlay(
                                                Image(key.image!).renderingMode(.template).foregroundColor( Color(keySpec.textColor)), alignment: .center)
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


struct SubPopModal: View {
    let keyPressHandler: KeyPressHandler

    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsKeyCaptions)
    private var keyCaptions = true
    
    @AppStorage(.settingsKeyCaptions)
    private var greekKeys = false

    @EnvironmentObject var keyData: KeyData
    
    @State private var modalPad = psAlpha
    
    var body: some View {
        if keyData.modalUp {
            
            VStack {
                Text( keyData.modalPad.caption ?? "Modal Pad" )
                    .padding( [.top] )
                
                VStack {
                    KeypadView( padSpec: greekKeys ? psGreek : psAlpha, keyPressHandler: keyPressHandler )
                        .padding( [.leading, .trailing, .bottom] )
                    
                    Toggle("\u{03b1}\u{03b2}\u{03b3}", isOn: $greekKeys ).frame( maxWidth: 100 ).padding( [.bottom], 20)
                }
            }
            .background( Color("Background") )
            .overlay(
                RoundedRectangle( cornerRadius: 6 )
                    .stroke( Color("Frame"), lineWidth: 4))
            .shadow( radius: 20 )
        }
    }
}


// ****************************************************

struct KeyView: View {
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false

    let padSpec: PadSpec
    let key: Key
    let keyPressHandler: KeyPressHandler

    @EnvironmentObject var keyData: KeyData
    @EnvironmentObject var model: CalculatorModel

    @AppStorage(.settingsKeyCaptions)
    private var keyCaptions = true

    // For long press gesture - finger is down
    @GestureState private var isPressing = false
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    private func hitRect( _ r:CGRect ) -> CGRect {
        // Expand a rect to allow hits below the rect so finger does not block key
        r.insetBy(dx: 0.0, dy: -padSpec.keySpec.height*2)
    }
    
    private func computeSubpadGeometry() {
        let subPad = keyData.subPad
        let n = subPad.keys.count
        let keyW = subPad.keySpec.width
        let keyH = subPad.keySpec.height
        let nkeys = 0..<n
        let popW = keyW * Double(n)
        let zOrigin = keyData.zFrame.origin
        
        // Keys leading edge x value relative to zFrame
        let xKey = keyData.keyOrigin.x - zOrigin.x
        
        // Compute all possible x position values for popup
        let xSet = nkeys.map( { xKey - Double($0)*keyW } )
        
        // Filter out values where the popup won't fit in the Z frame
        let xSet2 = xSet.filter( { x in x >= 0 && (x + popW) <= keyData.zFrame.maxX - zOrigin.x })
        
        // Sort by distance from mid popup to mid key
        let xSet3 = xSet2.sorted() { x1, x2 in
            let offset = popW/2 - xKey - keyW/2
            return abs(x1+offset) < abs(x2+offset)
        }
        
        // Choose the value that optimally centers the popup over the key
        let xPop = xSet3[0]
        
        // Popup height is augmented if the pop spec includes a caption
        let popH = padSpec.caption == nil || !keyCaptions ? keyH : keyH*2 + popCaptionH
        
        // Write popup location and size to state object
        keyData.popFrame = CGRect( x: xPop + zOrigin.x,
                                   y: keyData.keyOrigin.y - keyH - padSpec.keySpec.radius,
                                   width: popW, height: popH)
    }
    
    private func trackDragPt() {
        // Tracking finger movements with sub menu popup open
        if keyData.subPad.kc != .noop {
            
            let subPad = keyData.subPad
            
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
                    if let modalPad = PadSpec.getModalPadSpec( key.kc ) {
                        
                        // Pop up modal key pad
                        keyData.pressedKey = key
                        keyData.modalPad = modalPad
                        keyData.modalUp = true
                        
                        // Do not generate a key event until a selection is made on the modal pad
                    }
                    else {
                        
                        // Subpop menu key event
                        _ = keyPressHandler.keyPress( KeyEvent( kc: key.kc, kcTop: keyData.pressedKey?.kc))
                        
                        // Cannot clear this value in the modal subpad case above so do it here
                        keyData.pressedKey = nil
                    }
                }
                
                keyData.dragPt = CGPoint.zero
                keyData.selSubkey = nil
                keyData.keyDown = false
                keyData.subPad = SubPadSpec()
            }
    }
    
    
    var yellowCircle: some View {
        Circle()
            .foregroundStyle(.yellow)
            .frame(width: 5, height: 5)
    }
    
    var redCircle: some View {
        Circle()
            .foregroundStyle(.red)
            .frame(width: 10, height: 10)
    }

    
    
    var body: some View {

        let keyW = padSpec.keySpec.width * Double(key.size) + Double(key.size - 1) * keyHspace
        
        let hasSubpad = SubPadSpec.getSpec(key.kc) != nil
        
        VStack {
            let text: String? = key.text == nil ? model.getKeyText(key.kc) : key.text
            
            GeometryReader { geometry in
                let vframe = geometry.frame(in: CoordinateSpace.global)
                
                let longPress =
                LongPressGesture( minimumDuration: longPressTime)
                    .sequenced( before: drag )
                    .updating($isPressing) { value, state, transaction in
                        switch value {
                            
                        case .second(true, nil):
                            if let subpad = SubPadSpec.getSpec(key.kc) {
                                // Start finger tracking
                                keyData.subPad = subpad
                                keyData.keyOrigin = vframe.origin
                                keyData.pressedKey = key
                                
                                computeSubpadGeometry()
                                                                
                                // This will pre-select the subkey directly above the pressed key
                                keyData.dragPt = CGPoint( x: vframe.midX, y: vframe.minY)
                                trackDragPt()

                                // Initiate popup menu
                                state = true
                            }
                            
                        default:
                            break
                        }
                    }
                
                // This is the key itself
                Rectangle()
                    .foregroundColor( Color(padSpec.keySpec.keyColor) )
                    .frame( width: keyW, height: padSpec.keySpec.height )
                    .cornerRadius( padSpec.keySpec.radius )
                    .simultaneousGesture( longPress )
                    .onChange( of: isPressing) { _, newState in keyData.keyDown = newState }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            // Keypress event occured, send event
                            hapticFeedback.impactOccurred()
                            
                            if keyData.modalUp {
                                let modalKey = keyData.pressedKey?.kc
                                
                                let event = KeyEvent( kc: modalKey ?? .noop, kcSub: key.kc )
                                
                                // Close modal popup
                                keyData.pressedKey = nil
                                keyData.modalPad = PadSpec()
                                keyData.modalUp = false

                                // Generate key press event
                                // Blank key on subpad will be .noop
                                if key.kc != .noop {
                                    _ = keyPressHandler.keyPress( event )
                                }
                            }
                            else if let modalPad = PadSpec.getModalPadSpec( key.kc ) {
                                
                                // Pop up modal key pad
                                keyData.pressedKey = key
                                keyData.modalPad = modalPad
                                keyData.modalUp = true
                                
                                // Do not generate a key event until a selection is made on the modal pad
                            }
                            else {
                                // Generate key press event
                                _ = keyPressHandler.keyPress( KeyEvent( kc: key.kc))
                            }
                        })
                    .if( text != nil && !model.aux.isRecordingKey(key.kc) ) { view in
                        // Add rich text label to key
                        view.overlay(
                            RichText( text!, size: .normal, weight: .bold,
                                      defaultColor: padSpec.keySpec.textColor)
                        )
                    }
                    .if ( key.image != nil ) { view in
                        // Add image to key - currently not used
                        view.overlay(
                            Image(key.image!)
                                .renderingMode(.template)
                                .foregroundColor( Color(padSpec.keySpec.textColor)), alignment: .center)
                            
                    }
                    .if( hasSubpad ) { view in
                        // Add subpad indicator dot to key
                        view.overlay(alignment: .topTrailing) {
                            yellowCircle
                                .alignmentGuide(.top) { $0[.top] - 3}
                                .alignmentGuide(.trailing) { $0[.trailing] + 3 }
                        }
                    }
                    .if( model.aux.isRecordingKey(key.kc) ) { view in
                        // Add red recording dot to macro key
                        view.overlay {
                            redCircle
                        }
                    }
            }
            
        }
        .frame( maxWidth: keyW, maxHeight: padSpec.keySpec.height )
        
        // Debug border rectangle
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
        // let _ = Self._printChanges()
        
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
                
                // Debug border rectangle
                // .border(.red)
            }
        }
        .padding(0)

        // Debug border
        // .border(.green)
    }
}


struct KeyStack<Content: View>: View {
    
    let keyPressHandler: KeyPressHandler
    
    @StateObject var keyData = KeyData()
    
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            content
            
            ModalBlock()
            
            SubPopMenu()
            
            SubPopModal( keyPressHandler: keyPressHandler )
        }
        .onGeometryChange( for: CGRect.self, of: {proxy in proxy.frame(in: .global)} ) { newValue in
            keyData.zFrame = newValue
        }
//        .border(.brown)
        .padding()
        .alignmentGuide(HorizontalAlignment.leading) { _ in  0 }
        .environmentObject(keyData)
    }
}
