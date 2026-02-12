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
    var keyCode: KeyCode
    
    // Top level key like .fn4 when kc is an opcode from a sub popup menu like .rec
    var kcTop: KeyCode?
    
    // Code representing a symbol for a memory or macro
    var mTag: SymbolTag?
    
    var kc: KeyCode { keyCode }
    
    init( _ kc: KeyCode ) {
        keyCode = kc
    }
    
    init( _ kc: KeyCode, mTag: SymbolTag ) {
        keyCode = kc
        self.mTag = mTag
    }
    
    init( _ kc: KeyCode, kcTop: KeyCode? ) {
        keyCode = kc
        self.kcTop = kcTop
    }
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
    var image: String?
    var caption: String?
    
    var id: Int { return self.kc.rawValue }
    
    static var keyList: [KeyCode : Key] = [:]

    init( _ kc: KeyCode, _ label: String? = nil, size: Int = 1, image: String? = nil, caption: String? = nil ) {
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
    
    static func disableKey( _ kc: KeyCode, _ disabled: Bool = true ) {
        
        if disabled {
            Key.disableList.insert(kc)
        }
        else {
            Key.disableList.remove(kc)
        }
    }
    
    static func isDisabled( _ kc: KeyCode ) -> Bool {
        Key.disableList.contains(kc)
    }
    
    // Disable the key if the keycode is in this set
    static var disableList: Set<KeyCode> = []

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
    
    static func disableAllFnSubmenu( except kc: KeyCode = .null ) {
        
        // Disable all Fn key submenus except the one recording
        for key in KeyCode.fnSet {
            if key != kc {
                SubPadSpec.disableList.insert(key)
            }
        }
    }
    
    static func enableAllFnSubmenu() {
        SubPadSpec.disableList.removeAll()
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
    case none = 0, selectMemory, newMemory, localMemory, globalMemory, selectMacro
}

@Observable
class KeyData {
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
    
    var disabledKeys: Set<KeyCode> = []

    /*Published*/ var dragPt   = CGPoint.zero
    /*Published*/ var keyDown  = false
    /*Published*/ var modalKey = ModalKey.none
}


let longPressTime = 0.5
let keyInset      = 4.0
let keyHspace     = 10.0
let keyVspace     = 8.0
let popCaptionH   = 13.0
let captionFont   = 12.0


struct ModalBlock: View {
    @Environment(KeyData.self) var keyData

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
                    keyData.disabledKeys = []
                }
        }
    }
}


struct SubPopMenu: View {
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsKeyCaptions)
    private var keyCaptions = true

    @Environment(KeyData.self) var keyData
    
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
            let disableList = keyData.disabledKeys
            
            Rectangle()
                .frame( width: w + keyInset, height: popH)
                .foregroundColor( Color("PopBack"))
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
                                    let color = disableList.contains(key.kc) ? "GrayText" : "PopText"
                                
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
                                                    defaultColor: color)
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
    
    @Environment(KeyData.self) var keyData

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


struct MemorySelectPopup: View, KeyPressHandler {
    
    /// Select an existing memory if there are any or go directly to new memory popup
    
    @Environment(CalculatorModel.self) var model
    @Environment(KeyData.self) var keyData
    
    @State private var memorySheet: Bool = false
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        return KeyPressResult.modalPopupContinue
    }
    
    
    func getGlobalMemoryRcl() -> [TaggedItem] {
        
        if model.aux.macroTag != SymbolTag.Null &&  model.aux.isRec {
            
            // We are recording a macro so we cannot allow Rcl of a computede memory that directly or indirectly references us

            let recTag = model.aux.macroTag
            
            var itemList: [TaggedItem] = []

            for memRec in model.state.memory {
                
                if memRec.symTag.isComputedMemoryTag {
                    
                    let refMemSet = model.getAllMemoryTagsReferenced( by: memRec.symTag)
                    
                    let recTagC = SymbolTag( recTag, mod: SymbolTag.computedMemMod)
                    
                    if refMemSet.contains( recTagC ) == false && recTagC != memRec.symTag  {
                        
                        // We add only memories that are not computed and referencing us
                        itemList.append(memRec)
                    }
                    
                    
                }
                else {
                    // All regular memories are allowed - as .sto parm
                    itemList.append(memRec)
                    
                }
            }
            
            return itemList
        }
        else {
            // All memories allowed to be recalled if not recording a macro
            return model.state.memory
        }
    }
    
    
    func getGlobalMemorySto() -> [TaggedItem] {
        
        // We can store any memnory except computed memories
        return model.state.memory.filter( { $0.symTag.isComputedMemoryTag == false } )
    }
    
    
    func getTagGroups() -> [SymbolTagGroup] {
        
        // You can recall any memory but you can't store computed memories
        let globalItems = keyData.pressedKey?.kc == .rcl ? getGlobalMemoryRcl() : getGlobalMemorySto()
        
        let globalGroup = SymbolTagGroup( label: "Global Memories", itemList: globalItems )
        
        if let lvf = model.currentLVF {
            
            var localTags: [SymbolTag]
            
            if keyData.pressedKey?.kc == .rcl {
                
                // Recall only existing tags
                localTags = Array( lvf.local.keys )
            }
            else {
                
                let kcLower: [KeyCode] =
                [.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z]
                
                let tagLower: [SymbolTag] = kcLower.map { SymbolTag($0) }
                
                localTags = tagLower.map { SymbolTag( $0, mod: SymbolTag.localMemMod ) }
            }
            
            // Local variable frame list
            return [ SymbolTagGroup( label: "Local Memories", tagList: localTags), globalGroup ]
        }
        else {
            // Global context
            return [globalGroup ]
        }
    }
    
    
    func sendKeyEvent( _ tag: SymbolTag ) {
        
        if let kcOp = keyData.pressedKey {
            // Send event for memory op
            _ = model.keyPress( KeyEvent( kcOp.kc, mTag: tag ) )
            
        }
        
        // Close modal popup
        keyData.pressedKey = nil
        keyData.modalKey = .none
    }
    
    
    var body: some View {
        
        CustomModalPopup( keyPressHandler: self, myModalKey: .globalMemory ) {
            
            let tags = getTagGroups()
            
            SelectSymbolPopup( tagGroupList: tags, title: "Select Memory", sscc: sendKeyEvent ) {
                
                // Footer content that goes below the tag list box
                if keyData.pressedKey?.kc != .rcl  {
                    
                    HStack( spacing: 20 ) {
                        
                        // New Memory Button
                        Button( "New..." )
                        {
                            memorySheet = true
                        }
                    }
                    .padding( [.top, .bottom], 10)
                }
                else {
                    // Recall op has no New memory button
                    Spacer().frame( height: 20 ).padding([.top, .bottom], 0)
                }
            }
        }
        
        // Edit Memory
        .sheet( isPresented: $memorySheet) {
            
            MemoryEditSheet() {  newTag, newtxt in
                
                if newTag != SymbolTag.Null {
                    let _ = model.newGlobalMemory( newTag, caption: newtxt.isEmpty ? nil : newtxt )
                    model.changed()
                    model.saveDocument()
                }
            }
            .presentationDetents([.fraction(0.9)])
        }
    }
}


enum LibrarySource: Int {
    case user = 0, system
}


struct MacroLibraryPopup: View, KeyPressHandler {
    
    /// Select an existing memory if there are any or go directly to new memory popup
    
    @Environment(CalculatorModel.self) var model
    @Environment(KeyData.self) var keyData
    
    @State private var libSource: LibrarySource = .user
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        return KeyPressResult.modalPopupContinue
    }
    
    let popupTitle: [LibrarySource : String] = [.user : "User Library", .system : "Standard Library"]

    
    func getMacroTags( _ libSrc: LibrarySource ) -> [SymbolTagGroup] {
        
        switch libSrc {
        case .user:
            return
                model.db.modList.map { remMod in
                    SymbolTagGroup(
                        label: remMod.name,
                        model: model,
                        mod: remMod
                    )
                }
            
        case .system:
            return
                SystemLibrary.groups.map { group in
                    SymbolTagGroup(
                        label: group.name,
                        itemList:
                            group.functions.map { $0 }
                    )
                }
        }
    }
    
    
    func sendKeyEvent( _ tag: SymbolTag ) {
        
        if let kcOp = keyData.pressedKey {
            // Send event for memory op
            _ = model.keyPress( KeyEvent( kcOp.kc, mTag: tag ) )
            
        }
        
        // Close modal popup
        keyData.pressedKey = nil
        keyData.modalKey = .none
    }

    
    var body: some View {
        
        CustomModalPopup( keyPressHandler: self, myModalKey: .selectMacro ) {
            
            let tagGroupList = getMacroTags(libSource)
            
            SelectSymbolPopup( tagGroupList: tagGroupList, title: popupTitle[libSource] ?? "", sscc: sendKeyEvent ) {
                
                // Bottom Content
                
                // User Lib or System Lib picker
                Picker("", selection: $libSource) {
                    RichText( "User", size: .small, weight: .regular, design: .default, defaultColor: "BlackText" )
                        .tag(LibrarySource.user)
                    RichText( "Standard", size: .small, weight: .regular, design: .default, defaultColor: "BlackText" )
                        .tag(LibrarySource.system)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .padding( [.top, .bottom], 15 )
            }
        }
    }
}


struct localMemoryPopup: View, KeyPressHandler {
    
    @Environment(CalculatorModel.self) var model
    
    @AppStorage(.settingsKeyCaptions)
    private var greekKeys = false
    
    @Environment(KeyData.self) var keyData
    
    @State private var memoryOp: KeyCode = .noop

    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        
        let evt = KeyEvent( memoryOp, mTag: SymbolTag(event.keyCode) )
        
        return model.keyPress(evt)
    }
    
    
    var body: some View {
        
        CustomModalPopup( keyPressHandler: self, myModalKey: .newMemory ) {

            VStack {
                Text( keyData.modalPad.caption ?? "Modal Pad" )
                    .padding( [.top] )
                
                VStack {
                    KeypadView( padSpec: greekKeys ? psGreek : psAlpha, keyPressHandler: self )
                        .padding( [.leading, .trailing, .bottom] )
                    
                    Toggle("\u{03b1}\u{03b2}\u{03b3}", isOn: $greekKeys ).frame( maxWidth: 100 ).padding( [.bottom], 20)
                }
            }
        }
        .onAppear() {
            
            // There are memory Ops under the Sto key as well as the Sto key itself
            memoryOp = keyData.selSubkey?.kc ?? keyData.pressedKey?.kc ?? .noop
        }
    }
}


// ****************************************************

struct KeyView: View {
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false

    @AppStorage(.settingsYellowDots)
    private var yellowDots = true

    let padSpec: PadSpec
    let key: Key
    let keyPressHandler: KeyPressHandler

    @Environment(CalculatorModel.self) var model
    @Environment(KeyData.self) var keyData

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
                        if Key.isDisabled(key.kc) == false {
                            _ = keyPressHandler.keyPress( KeyEvent( key.kc, kcTop: keyData.pressedKey?.kc))
                        }
                        
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
        
        let keycode = model.getMappedKeycode(key.kc)
        
        let hasSubpad = SubPadSpec.getSpec(keycode) != nil
        
        VStack {
            let (keyText, textCode) = model.getKeyText(keycode)
            
            GeometryReader { geometry in
                let vframe = geometry.frame(in: CoordinateSpace.global)
                
                let longPress =
                LongPressGesture( minimumDuration: longPressTime)
                    .sequenced( before: drag )
                    .updating($isPressing) { value, state, transaction in
                        switch value {
                            
                        case .second(true, nil):
                            if let subpad = SubPadSpec.getSpec(keycode) {
                                // Start finger tracking
                                keyData.subPad = subpad
                                keyData.keyOrigin = vframe.origin
                                keyData.pressedKey = key
                                keyData.disabledKeys = model.eventContext?.getDisableSet( topKey: keycode ) ?? []
                                
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
                            
                            if let modalKey = Key.getModalKey(keycode) {
                                
                                // Pop up modal key pad
                                keyData.pressedKey = key
                                keyData.modalKey = modalKey
                                
                                // Do not generate a key event until the modal terminates
                            }
                            else {
                                // Generate key press event
                                let result = keyPressHandler.keyPress( KeyEvent(keycode))
                                
                                if keyData.modalKey != .none && result != .modalPopupContinue {
                                    
                                    // Cancel a modal popup if there is one and the key press result is not continue
                                    keyData.pressedKey = nil
                                    keyData.modalKey = .none
                                }
                            }
                        })
                    .if( keyText != nil && !model.isRecordingKey(keycode) ) { view in
                        // Add rich text label to key
                        view.overlay(
                            RichText( keyText!, size: .normal, weight: .bold,
                                      defaultColor: padSpec.keySpec.textColor)
                        )
                    }
                    .if ( key.image != nil ) { view in
                        // Add image to key - currently not used
                        view.overlay(
                            Image( systemName: key.image!)
                                .renderingMode(.template)
                                .foregroundColor( Color(padSpec.keySpec.textColor)), alignment: .center)
                            
                    }
                    .if( yellowDots && hasSubpad && textCode != .symbol ) { view in
                        // Add subpad indicator dot to key - but not for keys with assigned symbols
                        view.overlay(alignment: .topTrailing) {
                            yellowCircle
                                .alignmentGuide(.top) { $0[.top] - 3}
                                .alignmentGuide(.trailing) { $0[.trailing] + 3 }
                        }
                    }
                    .if( model.isRecordingKey(keycode) ) { view in
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
 
    @Environment(KeyData.self) var keyData

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
    
    @State var keyData = KeyData()
    
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            content
            
            ModalBlock()
            
            SubPopMenu()
            MemorySelectPopup()
            MacroLibraryPopup()
        }
        .onGeometryChange( for: CGRect.self, of: {proxy in proxy.frame(in: .global)} ) { newValue in
            keyData.zFrame = newValue
        }
        .padding()
        .alignmentGuide(HorizontalAlignment.leading) { _ in  0 }
        .environment(keyData)
    }
}
