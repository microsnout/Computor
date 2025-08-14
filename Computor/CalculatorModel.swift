//
//  CalculatorModel.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-18.
//
import SwiftUI
import Numerics
import OSLog

let logM = Logger(subsystem: "com.microsnout.calculator", category: "model")


struct UndoStack {
    private let maxItems = 12
    private var storage = [CalcState]()
    
    mutating func push(_ state: CalcState ) {
        storage.append(state)
        
        if storage.count > maxItems {
            storage.removeFirst()
        }
    }
    
    mutating func pop() -> CalcState? {
        return storage.popLast()
    }
}


struct StatusState {
    var statusLeft:  String? = nil
    var statusMid:   String? = nil
    var statusRight: String? = nil
    
    var error = false
    
    var leftText: String { statusLeft ?? "" }
    
    var midText: String {
        if error {
            return "ç{StatusRedText}Errorç{}"
        }
        
        return statusMid ?? ""
    }
    
    var rightText: String { statusRight ?? "" }
    
}


protocol StateOperator {
    func transition(_ s0: CalcState ) -> CalcState?
}

// *********** *********** *********** *********** *********** *********** *********** ***********

typealias ContextContinuationClosure = ( _ event: KeyEvent ) -> Void


///
///  Event Context
///
class EventContext {
    var previousContext: EventContext? = nil
    
    var ccc: ContextContinuationClosure? = nil
    
    weak var model: CalculatorModel? = nil {
        didSet {
            onModelSet()
        }
    }
    
    func onActivate( lastEvent: KeyEvent ) {
        // Override if needed
    }
    
    func onDeactivate( lastEvent: KeyEvent ) {
        // Override if needed
    }
    
    func event( _ keyEvent: KeyEvent ) -> KeyPressResult {
        // Override to define context logic
        return KeyPressResult.null
    }
    
    func enterValue( _ tv: TaggedValue ) {
        if let model = self.model {
            model.pushValue(tv)
        }
    }
    
    func onModelSet() {
        // Override if needed
    }
    
    
    static var rollbackPoints: [Int : EventContext] = [:]
    
}


class LocalVariableFrame {
    let prevLVF: LocalVariableFrame?
    
    var local: [SymbolTag : TaggedValue] = [:]
    
    init( _ prev: LocalVariableFrame? = nil ) {
        self.prevLVF = prev
    }
}


struct KeyState {
    
    var func2R: PadSpec = psFunctions2R
    
    // F1 .. F6 key mappings
    var keyMap: KeyMapRec = KeyMapRec()
}


// ***********************************************************
// ***********************************************************
// ***********************************************************

class CalculatorModel: ObservableObject, KeyPressHandler {
    
    // Current Calculator State
    @Published var state  = CalcState()
    @Published var entry  = EntryState()
    @Published var aux    = AuxState()
    @Published var status = StatusState()
    @Published var kstate = KeyState()
    
    // Current selected macro module file
    var macroMod = ModuleFile()
    
    // Pause recording when value greater than 0
    var pauseRecCount: Int = 0

    // Display window into register stack
    let displayRows = 3
    
    // Current event handling context - Normal, Recording, Entry, ModalFunction, Block
    var eventContext: EventContext?  = nil
    
    var previousContext: EventContext? { eventContext?.previousContext }
    
    // Storage of memories local to a block {..}
    var currentLVF: LocalVariableFrame? = nil
    
    private var undoStack = UndoStack()
    
    // If pause count is greater than 0, pause undo stack operations
    private var stackPauseCount: Int = 0
    
    // Queue for when events need to be pushed back by an event context for processing by another context
    private var eventQ = [KeyEvent]()
    
    func queueEvent( _ evt: KeyEvent ) {
        eventQ.append(evt)
    }

    init() {
        self.state  = CalcState()
        self.entry  = EntryState()
        self.aux    = AuxState()
        self.status = StatusState()
        
        self.undoStack   = UndoStack()
        
        pushContext( NormalContext() )
        
        installMatrix(self)
        installComplex(self)
        installVector(self)
        installFunctions(self)
    }
    
    
    // *** Event Context functions ***

    func pushContext( _ ctx: EventContext, lastEvent: KeyEvent = KeyEvent(.null), _ ccc: ContextContinuationClosure? = nil ) {
        
        // Make this context active, linking to previous ones
        ctx.model = self
        ctx.previousContext = self.eventContext
        
        eventContext?.ccc = ccc
        eventContext = ctx
        eventContext?.onActivate( lastEvent: lastEvent )
        
        logM.debug( "Push context: \(String( describing: ctx.self ))")
    }
    
    func popContext( _ event: KeyEvent = KeyEvent(.null), runCCC: Bool = true ) {
        
        // Restore previous context
        if let oldContext = previousContext {
            
            eventContext?.onDeactivate( lastEvent: event )
            self.eventContext = oldContext
            
            // Run the continuation closure if there is one
            if runCCC {
                // Run the Context Continuation Closure, Be sure to nil it or it will be run again when
                // you least expect it
                eventContext?.ccc?( event )
                eventContext?.ccc = nil
            }
            
            logM.debug( "Restore context: \(String( describing: oldContext.self ))")
        }
    }
    
    func saveRollback( to macroIndex: Int ) {
        EventContext.rollbackPoints[macroIndex] = eventContext
        
        logM.debug( "Save rollback to index: \(macroIndex)")
    }
    
    func clearRollbacks() {
        EventContext.rollbackPoints = [:]
    }
    
    func rollback( _ ctx: EventContext ) {
        eventContext = ctx
        
        logM.debug( "Rollback context to: \(String( describing: ctx.self ))")
    }
    
    func getRollback( to macroIndex: Int ) -> EventContext? {
        if let ctx = EventContext.rollbackPoints[macroIndex] {
            EventContext.rollbackPoints[macroIndex] = nil
            return ctx
        }
        return nil
    }
    

    // *** Entry State control ***
    
    func acceptTextEntry() {
        if entry.entryMode {
            guard let tv = entry.makeTaggedValue() else  {
                assert(false)
                entry.clearEntry()
                return
            }
            
            // Store tagged value in X reg, Record data entry if recording and clear data entry state
            entry.clearEntry()
            
            // Keep new entered X value
            state.stack[regX] = tv
            state.lastX = tv
        }
    }

    
    func grabTextEntry() -> TaggedValue {
        
        guard let tv = entry.makeTaggedValue() else  {
            assert(false)
            entry.clearEntry()
            return untypedZero
        }
        
        // Return the value
        entry.clearEntry()
        return tv
    }

    
    func pushState() {
        if stackPauseCount == 0 {
            undoStack.push( state )
        }
    }
    
    func popState() {
        if stackPauseCount == 0 {
            if let popState = undoStack.pop() {
                state = popState
            }
        }
    }
    
    func pauseUndoStack() {
        stackPauseCount += 1
    }
    
    func resumeUndoStack() {
        stackPauseCount -= 1
        
        if stackPauseCount < 0 {
            stackPauseCount = 0
        }
    }
    
    
    // ******************************
    // **** Macro Recording Stuff ***
    
    func saveMacroFunction( _ sTag: SymbolTag, _ list: MacroOpSeq ) {
        let mr = MacroRec( tag: sTag, seq: list)
        macroMod.saveMacro(mr)
        saveConfiguration()
    }
    
    func clearMacroFunction( _ sTag: SymbolTag) {
        macroMod.deleteMacro(sTag)
        saveConfiguration()
    }
    
    func getMacroFunction( _ sTag: SymbolTag ) -> MacroOpSeq? {
        if let mr = macroMod.getMacro(sTag) {
            return mr.opSeq
        }
        return nil
    }
    
    
    func isRecordingKey( _ kc: KeyCode ) -> Bool {
        
        /// Return true if kc key is currently recording
        
        if let mr = aux.macroRec {
            
            if let kcFn = kstate.keyMap.keyAssignment( mr.symTag ) {
                
                // We are recording a sym that is assigned to key kcFn
                return kcFn == kc
            }

            // recording but no key assignment
            return false
        }
        
        // Not recording anything
        return false
    }
    
    
    func startRecordingFnKey( _ kcFn: KeyCode ) {
        
        if let sTag = kstate.keyMap.tagAssignment(kcFn) {
            
            // TODO: Should eventually find a mr from any module not just current
            if let mr = macroMod.getMacro(sTag) {
                
                aux.record(mr)
            }
            else {
                // A tag assigned to this key but no macro rec - should not happen
                assert(false)
            }
        }
        else {
            // No tag assigned - must be a blank Fn key - find matching tag
            if let sTag = SymbolTag.getFnSym(kcFn) {
                
                kstate.keyMap.assign( kcFn, tag: sTag )
                let mr = MacroRec( tag: sTag )
                macroMod.saveMacro(mr)
                aux.record(mr)
            }
            else {
                // Recording kc key with no possible tag
                assert(false)
            }
        }
    }
    
    
    // *** NOT USED ***
    func record( _ tag: SymbolTag = SymbolTag(.null) ) {
        
        if let mr = macroMod.getMacro(tag) {
            
            // Start recording symbol tag - which could be null
            aux.record(mr)
        }
        else if tag == SymbolTag(.null) {
            
            // Null tag was not found - create the null rec
            let mr = MacroRec()
            macroMod.saveMacro(mr)
            aux.record(mr)
        }
        else {
            // A non null tag with no record
            assert(false)
        }
    }
    
    
    func createNewMacro() {
        
        /// Called from MacroListView 'plus' button
        
        // A blank macro record
        let mr = MacroRec()
        
        // Bind to null symbol for now - replacing any currently bound
        macroMod.saveMacro(mr )
        
        // Load into recorder
        aux.loadMacro(mr)
    }
    
    
    func setMacroCaption( _ caption: String, for tag: SymbolTag ) {
        
        macroMod.setMacroCaption(tag, caption)
    }
    
    
    func changeMacroSymbol( old: SymbolTag, new: SymbolTag ) {
        
        if let kc = kstate.keyMap.keyAssignment(old) {
            
            // Update key assignment
            kstate.keyMap.assign(kc, tag: new)
        }
        
        macroMod.changeMacroTag(from: old, to: new)
    }
    
    
    func playMacroSeq( _ seq: MacroOpSeq ) -> KeyPressResult {
        
        acceptTextEntry()
        
        // Macro playback - save inital state just in case
        pushState()
        
        pushContext( PlaybackContext(), lastEvent: KeyEvent(.macroPlay) )
        
        // Push a new local variable store
        currentLVF = LocalVariableFrame( currentLVF )
        
        // Don't maintain undo stack during playback ops
        pauseUndoStack()
        
        for op in seq {
            
            if op.execute(self) == KeyPressResult.stateError {
                resumeUndoStack()
                currentLVF = currentLVF?.prevLVF
                popContext()
                popState()
                return KeyPressResult.stateError
            }
        }
        resumeUndoStack()
        
        // Pop the local variable storage, restoring prev
        currentLVF = currentLVF?.prevLVF
        
        popContext( KeyEvent(.macroPlay) )
        
        return KeyPressResult.stateChange
    }
    
    // *** *** ***
    
    func pauseRecording() {
        pauseRecCount += 1
    }
    
    func resumeRecording() {
        pauseRecCount -= 1
    }
    
    
    func markMacroIndex() -> Int {
        guard let mr = aux.macroRec else {
            assert(false)
            return 0
        }
        
        // The index of the next element to be added will be...
        return mr.opSeq.count
    }
    
    
    func recordKeyEvent( _ event: KeyEvent ) {
        if pauseRecCount > 0 {
            logAux.debug( "recordKeyFn: Paused" )
            return
        }
        
        if !aux.isRec
        {
            logAux.debug( "recordKeyFn: Not Recording" )
            return
        }
        
        guard let mr = aux.macroRec else {
            // No macro record despite isRec is true
            assert(false)
            return
        }
        
        switch event.kc {
            
        case .enter:
            if let last = mr.opSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // An enter is not needed in recording if preceeded by an untyped value
                    break
                }
            }
            // Otherwise record the key
            mr.opSeq.append( MacroKey( event ) )
            
        case .back:
            // Backspace, need to remove last op or possibly undo a unit tag
            if let last = mr.opSeq.last {
                
                if let value = last as? MacroValue
                {
                    // Last op is a value op
                    if value.tv.tag == tagUntyped {
                        
                        // No unit tag, just remove the value
                        mr.opSeq.removeLast()
                    }
                    else {
                        // A tagged value, remove the tag
                        mr.opSeq.removeLast()
                        var tv = value.tv
                        tv.tag = tagUntyped
                        mr.opSeq.append( MacroValue( tv: tv))
                    }
                }
                else {
                    // Last op id just a key op
                    mr.opSeq.removeLast()
                }
            }
            
        case let kc where kc.isUnit:
            if let last = mr.opSeq.last,
               let value = last as? MacroValue
            {
                if value.tv.tag == tagUntyped {
                    
                    // Last macro op is an untyped value
                    if let tag = TypeDef.tagFromKeyCode(kc) {
                        
                        var tv = value.tv
                        mr.opSeq.removeLast()
                        tv.tag = tag
                        mr.opSeq.append( MacroValue( tv: tv))
                        break
                    }
                }
            }
            fallthrough
            
        default:
            // Just record the key
            mr.opSeq.append( MacroKey( event ) )
        }
        
        // Log debug output
        let auxTxt = aux.getDebugText()
        logAux.debug( "recordKeyFn: \(auxTxt)" )
    }
    
    
    func recordValueEvent( _ tv: TaggedValue ) {
        if aux.isRec
        {
            guard let mr = aux.macroRec else {
                // No macro record despite isRec is true
                assert(false)
                return
            }
            
            mr.opSeq.append( MacroValue( tv: tv) )
            
            // Log debug output
            let auxTxt = aux.getDebugText()
            logAux.debug( "recordValueFn: \(auxTxt)" )
        }
    }
    

    // ******************************
    // ******************************

    
    private func bufferIndex(_ stackIndex: Int ) -> Int {
        // Convert a bottom up index into the stack array to a top down index into the displayed registers
        return displayRows - stackIndex - 1
    }
    
    
    static let stackRegNames = ["X", "Y", "Z", "T"]
    
    func renderRow( index: Int ) -> String {
        let stkIndex = bufferIndex(index)
        
        guard stkIndex <= regT else {
            assert(false)
            return ""
        }
        
        if entry.entryMode && stkIndex == regX {
            
            // We are in data entry mode and looking for the X reg
            var text = "ƒ{0.8}ç{RegLetterText}={X  }ç{}ƒ{}"
            
            text.append( "={\(entry.entryText)}" )
            
            if !entry.exponentEntry {
                text.append( "ç{CursorText}={_}ç{}" )
            }
            
            if entry.exponentEntry {
                text.append( "^{\(entry.exponentText)}ç{CursorText}^{_}ç{}" )
            }
            
            return text
        }
        
        let tv = state.stack[stkIndex]
        var text = "ƒ{0.8}ç{RegLetterText}={\(CalculatorModel.stackRegNames[stkIndex])  }ç{}ƒ{}"
        let (valueStr, _) = tv.renderRichText()
        text += valueStr
        return text
    }
    
    func memoryOp( key: KeyCode, tag: SymbolTag ) {
        pushState()
        acceptTextEntry()
        
        // Leading edge swipe operations
        switch key {
            
        case .rclMem:
            if let mr = state.memoryAt( tag: tag ) {
                state.stackLift()
                state.Xtv = mr.tv
            }
            
        case .stoMem:
            state.memorySetValue( at: tag, state.Xtv )
            
        case .mPlus:
            if let index = state.memoryIndex( at: tag ) {
                if state.Xt == state.memory[index].tv.tag {
                    state.memory[index].tv.reg += state.X
                }
            }
            
        case .mMinus:
            if let index = state.memoryIndex( at: tag ) {
                if state.Xt == state.memory[index].tv.tag {
                    state.memory[index].tv.reg -= state.X
                }
            }
            
        default:
            break
        }
    }
    
    func delMemoryItems( set: IndexSet) {
        pushState()
        entry.clearEntry()
        state.memory.remove( atOffsets: set )
    }
    
    func renameMemoryItem( index: Int, newName: String ) {
        pushState()
        entry.clearEntry()
        state.memory[index].caption = newName
    }
    
    static var patternTable: [KeyCode : [OpPattern]] = [:]
    
    static func defineOpPatterns( _ kc: KeyCode, _ patterns: [OpPattern]) {
        if var pList = CalculatorModel.patternTable[kc] {
            pList.append( contentsOf: patterns )
            CalculatorModel.patternTable[kc] = pList
        }
        else {
            CalculatorModel.patternTable[kc] = patterns
        }
    }
    
    static var conversionTable: [ConversionPattern] = []
    
    static func defineUnitConversions( _ patterns: [ConversionPattern]) {
        CalculatorModel.conversionTable.append( contentsOf: patterns )
    }
    
    static func defineOpCodes( _ newOpSet: [KeyCode : StateOperator] ) {
        // Add new operators to opTable, replacing duplicates with new value
        CalculatorModel.opTable.merge(newOpSet) { (_, newOp) in newOp }
    }
    
    
    // Set of keys that cause data entry mode to begin, digits and dot
    static let entryStartKeys = KeyCode.digitSet.union( Set<KeyCode>([.dot]) )
    
    // Set of keys valid in data entry mode, all of above plus sign, back and enter exp
    static let entryKeys =  entryStartKeys.union( Set<KeyCode>([.sign, .back, .eex]) )
    
    
    func storeRegister( _ event: KeyEvent, _ tv: TaggedValue ) {
        
        if let mTag = event.mTag {
            
            if let lvf = currentLVF {
                
                // Local block {..} memory
                lvf.local[mTag] = tv
            }
            else {
                // Global memory
                pushState()
                
                if let index = state.memory.firstIndex( where: { $0.tag == mTag }) {
                    
                    // Existing global memory
                    state.memory[index].tv = tv
                }
                else {
                    // New global memory
                    let mr   = MemoryRec( tag: mTag, tv: tv )
                    state.memory.append( mr )
                }
                
                // Scroll aux display to memory list
                aux.activeView = .memoryList
            }
        }
        else {
            assert(false)
        }
    }
    
    
    // **********************************************************************
    // **********************************************************************
    // **********************************************************************
    
    func execute( _ event: KeyEvent ) -> KeyPressResult {
        
        let keyCode = event.kc
        
        switch keyCode {
        case .back:
            // Undo last operation by restoring previous state
            popState()
            return KeyPressResult.stateUndo
            
        case .enter:
            // Push stack up, x becomes entry value
            pushState()
            state.stackLift()
            state.noLift = true
            
        case .fixL:
            var fmt: FormatRec = state.Xtv.fmt
            fmt.digits = max(1, fmt.digits-1)
            state.Xfmt = fmt
            
        case .fixR:
            var fmt: FormatRec = state.Xtv.fmt
            fmt.digits = min(15, fmt.digits+1)
            state.Xfmt = fmt
            
        case .fix:
            pushState()
            state.Xfmt.style = .decimal
            
        case .sci:
            pushState()
            state.Xfmt.style = .scientific
            
        case .clX:
            // Clear X register
            pushState()
            state.Xtv = untypedZero
            state.noLift = true
            
        case .popX:
            storeRegister( KeyEvent( .popX, mTag: SymbolTag(.X) ), state.Xtv)
            state.stackDrop()

        case .popXY:
            pushState()
            pauseUndoStack()
            storeRegister( KeyEvent( .popXY, mTag: SymbolTag(.X) ), state.Xtv)
            storeRegister( KeyEvent( .popXY, mTag: SymbolTag(.Y) ), state.Ytv)
            resumeUndoStack()
            state.stackDrop()
            state.stackDrop()
            
        case .popXYZ:
            pushState()
            pauseUndoStack()
            storeRegister( KeyEvent( .popXYZ, mTag: SymbolTag(.X) ), state.Xtv)
            storeRegister( KeyEvent( .popXYZ, mTag: SymbolTag(.Y) ), state.Ytv)
            storeRegister( KeyEvent( .popXYZ, mTag: SymbolTag(.Z) ), state.Ztv)
            resumeUndoStack()
            state.stackDrop()
            state.stackDrop()
            state.stackDrop()

        case .stoX:
            storeRegister( event, state.Xtv )
            
        case .stoY:
            storeRegister( event, state.Ytv )
            
        case .stoZ:
            storeRegister( event, state.Ztv )

        case .rcl:
            if let mTag = event.mTag {
                
                var tv: TaggedValue
                
                if let lvf = currentLVF,
                   let val = lvf.local[mTag]
                {
                    // Local block memory found
                    tv = val
                }
                else if let index = state.memory.firstIndex(where: { $0.tag == mTag }) {
                    
                    // Global memory found
                    tv = state.memory[index].tv
                }
                else {
                    return KeyPressResult.stateError
                }
                
                pushState()
                state.stackLift()
                state.Xtv = tv
            }
            
        case .F1, .F2, .F3, .F4, .F5, .F6:
            if let macro = getMacroFunction( SymbolTag(keyCode) ) {
                // Macro playback - save inital state just in case
                pushState()
                
                pushContext( PlaybackContext(), lastEvent: event )
                
                // Push a new local variable store
               currentLVF = LocalVariableFrame( currentLVF )

                // Don't maintain undo stack during playback ops
                pauseUndoStack()
                for op in macro {
                    if op.execute(self) == KeyPressResult.stateError {
                        resumeUndoStack()
                        currentLVF = currentLVF?.prevLVF
                        popContext()
                        popState()
                        
                        logM.debug( "Execute \(String( describing: keyCode)): ERROR \(String( describing: op.getRichText(self) ))")
                        return KeyPressResult.stateError
                    }
                }
                resumeUndoStack()

                // Pop the local variable storage, restoring prev
                currentLVF = currentLVF?.prevLVF
                
                popContext( KeyEvent(keyCode) )
            }
            
        default:
            
            if let op = CalculatorModel.opTable[keyCode] {
                // Transition to new calculator state based on operation
                pushState()
                
                if let newState = op.transition( state ) {
                    // Operation has produced a new state
                    state = newState
                    state.noLift = false
                    
                    // Autoswitch between scientific and decimal
                    if state.Xfmt.style == .decimal {
                        if abs(state.X) >= 10000000000000.0 {
                            state.Xfmt.style = .scientific
                        }
                    }
                    else if state.Xfmt.style == .scientific {
                        if abs(state.X) < 1000.0 {
                            state.Xfmt.style = .decimal
                        }
                    }
                    
                    // Successful state change
                    return KeyPressResult.stateChange
                }
                else {
                    // Failed to produce a new state
                    popState()
                }
            }
            
            if let patternList = CalculatorModel.patternTable[keyCode] {
                for pattern in patternList {
                    if state.patternMatch(pattern.regPattern) {
                        // Transition to new calculator state based on operation
                        pushState()
                        
                        if let newState = pattern.transition(state) {
                            state = newState
                            state.noLift = false
                            
                            // Successful state change
                            return KeyPressResult.stateChange
                        }
                        else {
                            // Failed to produce a new state
                            popState()
                        }

                        // Fall through to error indication
                    }
                }
            }
            
            if keyCode.isUnit {
                // Attempt conversion of X reg to unit type keyCode
                if let tag = TypeDef.tagFromKeyCode(keyCode)
                {
                    pushState()
                    
                    for pattern in CalculatorModel.conversionTable {
                        if state.patternMatch(pattern.regPattern) {
                            pushState()
                            
                            if let newState = pattern.convert(state, to: tag) {
                                state = newState
                                state.noLift = false
                                
                                // Successful state change
                                return KeyPressResult.stateChange
                            }
                        }
                    }
                    
                    if state.convertX( toTag: tag) {
                        // Conversion succeded
                        state.noLift = false
                        
                        // Successful state change
                        return KeyPressResult.stateChange
                    }
                    else {
                        // else no-op as there was no new state
                        popState()
                    }
                }
            }
            
            // Display 'error' indicator in primary display
            self.status.error = true
            
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
                // Clear 'error' indication
                self.status.error = false
            }
            
            return KeyPressResult.stateError
        }
        
        // Successful state change
        return KeyPressResult.stateChange
    }
    
    // **********************************************************************
    // **********************************************************************
    // **********************************************************************

    
    func keyPress(_ keyEvent: KeyEvent) -> KeyPressResult {
        
        // Add this to the back of the Q just in case there is already some queued events that must go first
        eventQ.append( keyEvent )
        
        var result = KeyPressResult.null
        
        while !eventQ.isEmpty {
            let evt = eventQ.removeFirst()
            
            result = eventContext?.event( evt ) ?? KeyPressResult.null
            
            if result == .resendEvent {
                // Put this event back at beginning of queue
                eventQ.insert( evt, at: 0 )
            }
        }
        
        return result
    }
    
    
    func getKeyText( _ kc: KeyCode ) -> String? {
        
        if kc == .noop {
            return nil
        }
        
        guard let key = Key.keyList[kc] else {
            // All keys must be in keyList
            assert(false)
            return nil
        }
        
        if let text = key.text {
            // A key with custom text assigned
            return text
        }

        if KeyCode.fnSet.contains(kc) {
            // F1 to F6
            
            if let fTag = kstate.keyMap.fnRow[kc] {
                // A SymbolTag is assigned to this key
                return fTag.getRichText()
            }
            
            if let _ = self.macroMod.getMacro( SymbolTag(kc) ) {
                // Macro assigned to key but no symbol
                return "F\(kc.rawValue % 10)"
            }
            
            // Disabled key, no macro
            return "ç{GrayText}F\(kc.rawValue % 10)"
        }
    
        return nil
    }
    
    
    func enterValue(_ tv: TaggedValue) {
        if let ctx = eventContext {
            // Allow the current context to enter this value
            ctx.enterValue(tv)
        }
        else {
            // There should always be an event context
            assert(false)
            pushValue(tv)
        }
    }

    
    func pushValue(_ tv: TaggedValue) {
        // For macros, bypass data entry mode and enter a value directly
        state.stackLift()
        state.Xtv = tv
        state.noLift = false
    }
}

