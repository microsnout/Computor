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


class ModuleExecutionContext {
    let prevMEC: ModuleExecutionContext?
    
    var module: ModuleRec
    
    init( _ prev: ModuleExecutionContext? = nil, module mfr: ModuleRec ) {
        self.prevMEC = prev
        self.module = mfr
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
    @Published var db     = Database()
    
    // Currently active calculator document
    var activeDocName: String = ""
    
    // Pause recording when value greater than 0
    var pauseRecCount: Int = 0

    // Display window into register stack
    let displayRows = 3
    
    // Current event handling context - Normal, Recording, Entry, ModalFunction, Block
    var eventContext: EventContext?  = nil
    
    var previousContext: EventContext? { eventContext?.previousContext }
    
    // Storage of memories local to a block {..}
    var currentLVF: LocalVariableFrame? = nil
    
    var currentMEC: ModuleExecutionContext? = nil
    
    func pushMEC( _ mfr: ModuleRec ) {
        currentMEC = ModuleExecutionContext( currentMEC, module: mfr)
    }
    
    func popMEC()
    {
        if let mec = currentMEC {
            currentMEC = mec.prevMEC
        }
    }
    
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
    
    func deleteMemoryRecords( set: SymbolSet ) {
        pushState()
        entry.clearEntry()
        state.deleteMemoryRecords( tags: set )
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
    static let entryKeys =  entryStartKeys.union( Set<KeyCode>([.sign, .back, .eex, .d000]) )
    
    
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
                aux.activeView = .memoryView
            }
        }
        else {
            assert(false)
        }
    }

    
    func saveDocument() {
        
        if let docRec = db.getDocumentFileRec(name: self.activeDocName) {
            
            docRec.writeDocument() { obj in
                obj.state = self.state
                obj.keyMap = self.kstate.keyMap
                obj.unitData = UserUnitData.uud
            }
        }
    }
    
    
    func loadDocument( _ name: String ) {
        
        if name != self.activeDocName {
            
            // Save any changes before loading new doc
            saveDocument()
            
            if let docRec = db.getDocumentFileRec(name: name) {
                
                docRec.readDocument() { obj in
                    
                    self.state = obj.state
                    self.kstate.keyMap = obj.keyMap
                    
                    UserUnitData.uud = obj.unitData
                    UnitDef.reIndexUserUnits()
                    TypeDef.reIndexUserTypes()
                    
                    self.activeDocName = name
                }
            }
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
            // Macro function execution
            var result = KeyPressResult.noOp
            
            // Key F1..F6 pressed
            
            if let tag = kstate.keyMap.tagAssignment(keyCode),
               let (mr, mfr) = getMacroFunction(tag) {
                
                // Macro tag assigned to Fn key
                result = playMacroSeq(mr.opSeq, in: mfr)
            }
            
            if result == KeyPressResult.stateError {
                return KeyPressResult.stateError
            }

        case .lib:
            // Macro function execution
            var result = KeyPressResult.noOp
            
            // .lib, Sym code invoked by 'Lib' key or macro
            
            if let tag = event.mTag {
                
                if tag.isUserMod {
                    
                    if let (mr, mfr) = getMacroFunction(tag) {
                        
                        
                        
                        // Macro tag selected from popup
                        result = playMacroSeq(mr.opSeq, in: mfr)
                    }
                }
                else {
                    
                    // System Library Mod code
                    if let lf = SystemLibrary.getLibFunction( for: tag ) {
                        
                        if !state.patternMatch( lf.regPattern ) {
                            
                            // Stack state not compatible with function
                            displayErrorIndicator()
                            return KeyPressResult.stateError
                        }
                        
                        pushState()

                        result = lf.libFunc(self)
                        
                        if result == KeyPressResult.stateError
                        {
                            popState()
                            displayErrorIndicator()
                            return result
                        }
                        
                        state.noLift = false
                        return result
                    }
                }
            }
            
            if result == KeyPressResult.stateError {
                displayErrorIndicator()
                return KeyPressResult.stateError
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
            
            displayErrorIndicator()
            return KeyPressResult.stateError
        }
        
        // Successful state change
        return KeyPressResult.stateChange
    }
    
    
    func displayErrorIndicator() {
        
        // Display 'error' indicator in primary display
        self.status.error = true
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            // Clear 'error' indication
            self.status.error = false
        }
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
    
    
    enum KeyTextCode: Int {
        case none = 0, custom, funcKey, UnitKey, symbol
    }
    
    func getKeyText( _ kc: KeyCode ) -> (String?, KeyTextCode) {
        
        /// ** Get Key Text **
        
        if kc == .noop {
            return (nil, .none)
        }
        
        guard let key = Key.keyList[kc] else {
            // All keys must be in keyList
            assert(false)
            return (nil, .none)
        }
        
        if let text = key.text {
            // A key with custom text assigned
            return (text, .custom)
        }

        if KeyCode.fnSet.contains(kc) {
            // F1 to F6
            
            if let fTag = kstate.keyMap.tagAssignment(kc) {
                
                // A SymbolTag is assigned to this key
                return (fTag.getRichText(), .symbol)
            }
            
            // Disabled key, no macro
            return ("ç{GrayText}F\(kc.rawValue % 10)", .funcKey)
        }
    
        return (nil, .none)
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
    
    
    func enterRealValue( _ r: Double ) {
        let tv = TaggedValue( reg: r )
        enterValue(tv)
    }

    
    func pushValue(_ tv: TaggedValue) {
        // For macros, bypass data entry mode and enter a value directly
        state.stackLift()
        state.Xtv = tv
        state.noLift = false
    }
}

