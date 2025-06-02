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
    
    // Code representing a symbol for a memory
    var mTag: MemoryTag?
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
         resendEvent,        // Re-dispacth this event because the eventContext has changed
         modalPopupContinue
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


extension Key {
    
    static var modalKeyList: [ KeyCode : ModalKey ] = [:]
    
    static func getModalKey( _ kc: KeyCode ) -> ModalKey? {
        return Key.modalKeyList[kc]
    }
    
    static func defineModalKey( _ kc: KeyCode, _ key: ModalKey ) {
        Key.modalKeyList[kc] = key
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


// ****************************************************

enum ModalKey: Int {
    case none = 0, selectMemory, newMemory, localMemory
}

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
    @Published var modalKey = ModalKey.none
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
        if keyData.keyDown || keyData.modalKey != .none  {
            // Transparent rectangle to block all key interactions below the popup - opacity 0 passes key presses through
            Rectangle()
                .opacity(0.0001)
                .onTapGesture {
                    // Close modal popup
                    keyData.pressedKey = nil
                    keyData.modalPad = PadSpec()
                    keyData.modalKey = .none
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


struct CustomModalPopup<Content: View>: View {
    
    let keyPressHandler: KeyPressHandler
    
    let myModalKey: ModalKey
    
    @EnvironmentObject var keyData: KeyData

    @ViewBuilder let content: Content
    
    var body: some View {
        if keyData.modalKey == myModalKey {
            
            content
                .background( Color("Background") )
                .overlay(
                    RoundedRectangle( cornerRadius: 6 )
                        .stroke( Color("Frame"), lineWidth: 4))
                .shadow( radius: 20 )
        }
        
    }
}


struct NewMemoryPopup: View, KeyPressHandler {
    
    @EnvironmentObject var model: CalculatorModel
    
    @AppStorage(.settingsKeyCaptions)
    private var greekKeys = false
    
    @EnvironmentObject var keyData: KeyData
    
    @State private var charSet = CharSet.upper
    @State private var symName = ""
    @State private var symN    = 0
    
    // Can be 0 2 or 3, only one can be non-zero
    @State private var superPt = 0
    @State private var subPt   = 0
    
    @State private var symArray: [KeyCode] = []
    
    enum CharSet: Int {
        case upper = 0, lower, greek, digit
        
        var nextSet: CharSet {
            switch self {
            case .upper:    return .lower
            case .lower:    return .greek
            case .greek:    return .digit
            case .digit:    return .upper
            }
        }
            
        var nextSetZero: CharSet {
            switch self {
            case .upper:    return .lower
            case .lower:    return .greek
            case .greek:    return .upper
            case .digit:    return .upper
            }
        }
    }
    
    let setList: [CharSet] = [.upper, .lower, .greek, .digit]
    
    let padList: [PadSpec] = [psAlpha, psAlphaLower, psGreek, psDigits]
    
    let setLabels = ["ABC", "abc", "\u{03b1}\u{03b2}\u{03b3}", "123"]
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        if symN < 3 {
            // Max three char in symbol
            let ch = event.kc.str
            symName.append(ch)
            symArray.append( event.kc )
        }
        return KeyPressResult.modalPopupContinue
    }
    
    func reset() {
        // Clear symbol name
        subPt = 0
        superPt = 0
        symN = 0
        symName = ""
        symArray = []
    }
    
    func getSymbolText() -> String {
        
        if symN == 0 {
            // Placeholder text
            return "ƒ{2.0}ç{GrayText}---"
        }
        
        if symN == 1 || (subPt == 0 && superPt == 0) {
            // No sub or superscripts
            return "ƒ{2.0}\(symName)"
        }
        
        let symA = Array(symName)
        
        if symN == 2 {
            assert( (subPt*superPt == 0) && (subPt+superPt == 2) )
            
            let op = subPt > 0 ? "_" : "^"
            
            return "ƒ{2.0}\(symA[0])\(op){\(symA[1])}"
        }
        
        if symN == 3 {
            assert( (subPt*superPt == 0) && (subPt+superPt >= 2) )

            // Sub or Super operator and starting point
            let op = subPt > 0 ? "_" : "^"
            let pt = subPt + superPt
            
            // Sub or superscript point starting at position 2 or 3
            return pt == 2 ? "ƒ{2.0}\(symA[0])\(op){\(symA[1])\(symA[2])}" : "ƒ{2.0}\(symA[0])\(symA[1])\(op){\(symA[2])}"
        }
        
        // Invalid
        assert(false)
        return ""
    }

    var body: some View {
        
        CustomModalPopup( keyPressHandler: self, myModalKey: .newMemory ) {
            
            if keyData.pressedKey?.kc == .rcl {
                SelectMemoryPopup()
            }
            else {
                VStack {
                    
                    VStack {
                        RichText( getSymbolText(), size: .normal, defaultColor: "BlackText").padding( [.top], 20 )
                        
                        KeypadView( padSpec: padList[charSet.rawValue], keyPressHandler: self )
                            .padding( [.leading, .trailing, .bottom] )
                        
                        HStack {
                            Button( "", systemImage: "arrowshape.left.arrowshape.right" ) {
                                // Don't include digits for the first letter
                                charSet = symN == 0 ? charSet.nextSetZero : charSet.nextSet
                            }
                            
                            HStack {
                                ForEach ( setList, id: \.self ) { cs in
                                    Text( setLabels[cs.rawValue] )
                                        .if ( cs == charSet ) { txt in
                                            // Add border around selected char set
                                            txt.overlay(
                                                RoundedRectangle( cornerRadius: 5).inset(by: -1).stroke(.blue, lineWidth: 1) )
                                        }
                                        .if ( symN == 0 && cs == CharSet.digit ) { txt in
                                            // Digits not allowed for first char
                                            txt.foregroundColor(.gray)
                                        }
                                }
                            }
                        }.padding( [.bottom], 12)
                        
                        HStack( spacing: 20 ) {
                            Button( action: {
                                reset()
                            })
                            {
                                Image( systemName: "clear" )
                                    .foregroundStyle( symN > 0 ? Color.accentColor : Color.gray )
                            }
                            Button( action: {
                                if symN >= 2 && subPt == 0 {
                                    
                                    if superPt != 0 {
                                        // Return to flat text
                                        superPt = 0
                                    }
                                    else {
                                        // Add subscript point
                                        subPt = symN
                                    }
                                }
                            })
                            {
                                Image( systemName: "arrowshape.down" )
                                    .foregroundStyle( symN >= 2 && subPt == 0 ? Color.accentColor : Color.gray )
                            }
                            Button( action: {
                                if symN >= 2 && superPt == 0 {
                                    
                                    if subPt != 0 {
                                        // Return to flat text
                                        subPt = 0
                                    }
                                    else {
                                        // Add superscript point
                                        superPt = symN
                                    }
                                }
                            })
                            {
                                Image( systemName: "arrowshape.up" )
                                    .foregroundStyle( symN >= 2 && superPt == 0 ? Color.accentColor : Color.gray )
                            }
                            Button( action: {
                                if symN > 0 {
                                    symN -= 1
                                    symName.removeLast()
                                    symArray.removeLast()
                                }
                            })
                            {
                                Image( systemName: "delete.left" )
                                    .foregroundStyle( symN > 0 ? Color.accentColor : Color.gray )
                            }
                            Button( action: {
                                if symN > 0 {
                                    let tag = MemoryTag( symArray, subPt: subPt, superPt: superPt )
                                    
                                    if let kcOp = keyData.pressedKey {
                                        // Send event for memory op
                                        _ = model.keyPress( KeyEvent( kc: kcOp.kc, mTag: tag ) )
                                    }
                                    
                                    reset()
                                    
                                    // Close modal popup
                                    keyData.pressedKey = nil
                                    keyData.modalKey = .none
                                }
                            })
                            {
                                Image( systemName: "checkmark.diamond.fill" )
                                    .foregroundStyle( symN > 0 ? Color.green : Color.gray )
                            }
                        }.padding( [.bottom], 20)
                    }
                }.onChange( of: symName, initial: true ) {
                    symN = symName.count
                    
                    if symN == 0 {
                        // Back to zero chars, first can't be a digit
                        charSet = CharSet.upper
                    }
                    
                    if symN < 2 {
                        // Reset subscript/superscript points if only one char
                        superPt = 0
                        subPt = 0
                    }
                }
            }
        }
    }
}

struct MemoryKeyView: View {
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    let mTag: MemoryTag
    let keySpec: KeySpec
    let keyPressHandler: KeyPressHandler
    
    @EnvironmentObject var model: CalculatorModel
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    
    var body: some View {
        
        let keyW = keySpec.width
        
        VStack {
            let text: String = mTag.getRichText()
            
            GeometryReader { geometry in
                let vframe = geometry.frame(in: CoordinateSpace.global)
                
                // This is the key itself
                Rectangle()
                    .foregroundColor( Color(keySpec.keyColor) )
                    .frame( width: keyW, height: keySpec.height )
                    .cornerRadius( keySpec.radius )
                    .shadow( radius: 2 )
                    .overlay(
                        RichText( text, size: .normal, weight: .bold, defaultColor: keySpec.textColor)
                    )
                    .onTapGesture {
                        // Keypress event occured, send event
                        hapticFeedback.impactOccurred()
                        
                        // Generate key press event
                        let _ = keyPressHandler.keyPress( KeyEvent( kc: .stoX, mTag: mTag))
                    }
            }
        }
        .frame( maxWidth: keyW, maxHeight: keySpec.height )
    }
}


struct SelectMemoryPopup: View, KeyPressHandler {
    
    let keySpec: KeySpec = ksSoftkey
    
    @EnvironmentObject var model: CalculatorModel
    @EnvironmentObject var keyData: KeyData
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        return KeyPressResult.modalPopupContinue
    }
    
    var body: some View {
        
        let tagRowList: [[MemoryTag]] = model.state.memory.map( { $0.tag } ).chunked(into: 4)
        
        VStack( spacing: 0) {
            Text( "Select Memory" ).padding( [.top, .bottom], 10 )
            
            ScrollView( [.vertical] ) {
                
                Grid {
                    
                    ForEach ( tagRowList.indices, id: \.self ) { r in
                        
                        let row = tagRowList[r]
                        
                        GridRow {
                            
                            ForEach ( row.indices, id: \.self ) { c in
                                
                                MemoryKeyView( mTag: row[c], keySpec: keySpec, keyPressHandler: self )
                            }
                        }
                        .padding( [.top, .bottom], 10 )
                    }
                }
            }
            .padding( [.top, .bottom], 5 )
            .padding( [.leading, .trailing], 10 )
            .background( Color("Display") )
            .border(Color("Frame"), width: 2)
            
            HStack( spacing: 20 ) {
                
                Button( "New..." )
                {
                }
            }
            .padding( [.top, .bottom], 10)
        }
        .frame( maxHeight: 340 )
        .padding( [.leading, .trailing], 20 )
    }
}


struct localMemoryPopup: View {
    
    @EnvironmentObject var model: CalculatorModel
    
    @AppStorage(.settingsKeyCaptions)
    private var greekKeys = false
    
    @EnvironmentObject var keyData: KeyData

    struct NewMemoryHandler: KeyPressHandler {
        
        var kcMem: KeyCode
        var model: CalculatorModel
        
        func keyPress(_ event: KeyEvent ) -> KeyPressResult {
            
            let evt = KeyEvent( kc: kcMem, mTag: MemoryTag(event.kc)  )
            
            return model.keyPress(evt)
        }
    }
    
    var body: some View {
        
        let keyHandler = NewMemoryHandler( kcMem: keyData.selSubkey?.kc ?? keyData.pressedKey?.kc ?? .noop , model: model)

        CustomModalPopup( keyPressHandler: keyHandler, myModalKey: .newMemory ) {

            VStack {
                Text( keyData.modalPad.caption ?? "Modal Pad" )
                    .padding( [.top] )
                
                VStack {
                    KeypadView( padSpec: greekKeys ? psGreek : psAlpha, keyPressHandler: keyHandler )
                        .padding( [.leading, .trailing, .bottom] )
                    
                    Toggle("\u{03b1}\u{03b2}\u{03b3}", isOn: $greekKeys ).frame( maxWidth: 100 ).padding( [.bottom], 20)
                }
            }
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
                    if let modalKey = Key.getModalKey(key.kc) {
                        
                        // Pop up modal key pad
                        keyData.pressedKey = key
                        keyData.modalKey = modalKey

                        // Do not generate a key event until the modal terminates
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
                            
                            if let modalKey = Key.getModalKey(key.kc) {
                                
                                // Pop up modal key pad
                                keyData.pressedKey = key
                                keyData.modalKey = modalKey
                                
                                // Do not generate a key event until the modal terminates
                            }
                            else {
                                // Generate key press event
                                let result = keyPressHandler.keyPress( KeyEvent( kc: key.kc))
                                
                                if keyData.modalKey != .none && result != .modalPopupContinue {
                                    
                                    // Cancel a modal popup if there is one and the key press result is not continue
                                    keyData.pressedKey = nil
                                    keyData.modalKey = .none
                                }
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
            NewMemoryPopup()
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
