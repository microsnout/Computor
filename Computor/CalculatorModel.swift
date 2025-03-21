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
    
    func event( _ keyEvent: KeyEvent ) -> KeyPressResult {
        // Override to define context logic
        return KeyPressResult.null
    }
    
    func onModelSet() {
        // Override if needed
    }
}


///
/// Normal event context
///     Not recording, Not playing back macros, Not in data entry mode
///
class NormalContext : EventContext {
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .clrFn:
            if let kcFn = event.kcAux {
                model.clearMacroFunction(kcFn)
                model.aux.stopRecFn(kcFn)
            }
            return KeyPressResult.macroOp
            
        case .showFn:
            if let kcFn = event.kcAux {
                if let fn = model.state.fnList[kcFn] {
                    model.aux.list = fn.macro
                    model.aux.macroKey = fn.fnKey
                    model.aux.activeView = .macroList
                }
            }
            return KeyPressResult.macroOp
            
        case .stopFn, .openBrace, .closeBrace:
            return KeyPressResult.noOp
            
        case .recFn:
            model.pushContext( RecordingContext(), lastEvent: event )
            return KeyPressResult.macroOp
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                // Start data entry mode
                model.pushContext( EntryContext(), lastEvent: event ) { _ in
                    
                    // On restore, lift stack and copy entered data to X reg
                    model.acceptTextEntry()
                }
                
                return KeyPressResult.dataEntry
            }
            
            // Dispatch and execute the entered key
            return model.execute( event )
        }
    }
}


///
/// Entry event context
///
class EntryContext : EventContext {
    
    override func onActivate( lastEvent: KeyEvent ) {
        // Start data entry with a digit or a dot determined by the key that got us here
        model?.startEntryState( lastEvent.kc )
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        if !CalculatorModel.entryKeys.contains(event.kc) {
            
            // followed by regular processing of key
            model.popContext( event )
            
            // Let the newly restored context handle this event
            return KeyPressResult.resendEvent
        }
        
        // Process data entry key event
        let keyRes = model.entry.entryModeKeypress(event.kc)
        
        if keyRes == .cancelEntry {
            // Exited entry mode
            // We backspace/undo out of entry mode - need to pop stack
            // to restore state before entry mode
            model.popState()
            model.popContext( event )
            return KeyPressResult.stateUndo
        }
        
        // Stay in entry mode
        return KeyPressResult.dataEntry
    }
}


///
/// Recording Context
///
class RecordingContext : EventContext {
    
    var kcFn = KeyCode.null
    
    override func onActivate(lastEvent: KeyEvent) {
        
        guard let model = self.model else { return }
        
        if let kcFn = lastEvent.kcAux {
            
            // Start recording the indicated Fn key
            self.kcFn = kcFn
            model.aux.startRecFn(kcFn)
        }
    }
    
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "RecordingContext event: \(event.kc)")

        switch event.kc {
            
        case .clrFn:
            model.clearMacroFunction(kcFn)
            model.aux.stopRecFn(kcFn)
            model.popContext( event )
            return KeyPressResult.cancelEntry
            
        case .showFn, .recFn:
            return KeyPressResult.noOp
            
        case .stopFn:
            if !model.aux.list.opSeq.isEmpty {
                model.saveMacroFunction(kcFn, model.aux.list)
            }
            model.aux.stopRecFn(kcFn)
            model.popContext( event )
            return KeyPressResult.macroOp
            
        case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
            if model.state.fnList[event.kc] == nil {
                // No op any undefined keys
                return KeyPressResult.noOp
            }
            model.aux.recordKeyFn( event.kc )
            return model.execute( event )
            
        case .back:
            if model.aux.list.opSeq.isEmpty {
                
                // Cancel the recording
                model.aux.stopRecFn(kcFn)
                model.popContext( event )
                return KeyPressResult.cancelEntry
            }
            else {
                // Record key and execute it
                model.aux.recordKeyFn( event.kc )
                return model.execute( event )
            }
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                model.pushContext( EntryContext(), lastEvent: event ) { _ in
                    // On restore context
                    // Record the value and key when returning to a recording context
                    model.acceptTextEntry()
                    model.aux.recordValueFn( model.state.Xtv )
                }
                return KeyPressResult.dataEntry
            }
            
            // Record key and execute it
            model.aux.recordKeyFn( event.kc )
            return model.execute( event )
        }
    }
}


///
/// Playback Context
///
class PlaybackContext : EventContext {
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .showFn:
            return KeyPressResult.noOp
            
        default:
            return model.execute( event )
        }
    }
}


///
/// Modal Context
///     For modal functions like map and reduce, to wait for a function parameter, either single key or { }
///
class ModalContext : EventContext {
    
    var withinRecContext = false
    
    // String to display while modal function is active
    var statusString: String? { nil }
    
    var macroFn: MacroOpSeq = MacroOpSeq()
    
    override func onActivate( lastEvent: KeyEvent) {
        if let model = self.model {
            // We could be used within a recording context or a normal context
            withinRecContext = model.eventContext?.previousContext is RecordingContext
        }
    }
    
    // Key event handler for modal function
    func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        return KeyPressResult.null
    }
    
    func runMacro( model: CalculatorModel ) -> KeyPressResult {
        for op in macroFn.opSeq {
            if op.execute( model ) == KeyPressResult.stateError {
                return KeyPressResult.stateError
            }
        }
        return KeyPressResult.stateChange
    }
    
    func executeFn( _ event: KeyEvent ) -> KeyPressResult {
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "ModalContext executeFn: \(event.kc)")
        
        switch event.kc {
            
        case .macro:
            return runMacro(model: model)
            
        default:
            return model.keyPress(event)
        }
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "ModalContext event: \(event.kc)")

        switch event.kc {
            
        case .openBrace:
            // Start recording, don't record the open brace at top level
            if withinRecContext {
                
                // Record the open brace of the block
                model.aux.recordKeyFn(event.kc)
                
                model.pushContext( BlockRecord(), lastEvent: event ) { _ in
                    
                    // Now record the closing brace of the block
                    model.aux.recordKeyFn(event.kc)
                }
                return KeyPressResult.recordOnly
            } else {
                
                model.pushContext( BlockRecord(), lastEvent: event ) { _ in
                    
                    // Stop recording the Block {}
                    model.aux.stopRecFn(.openBrace)
                    
                    // Capture the block macro
                    self.macroFn = model.aux.list
                    
                    // Queue a .macro event to execute it
                    model.queueEvent( KeyEvent( kc: .macro ) )
                }
                return KeyPressResult.stateChange
            }
            
        case .macro:
            model.popContext( event )
            
            model.pushState()
            
            let result =  modalExecute( event )
            if result == .stateError {
                model.popState()
            }
            return result

        default:
            model.popContext( event )
            
            if model.eventContext is RecordingContext {
                model.aux.recordKeyFn( event.kc )
            }
            
            model.pushState()
            let result =  modalExecute( event )
            if result == .stateError {
                model.popState()
            }
            return result
        }
    }
    
    override func onModelSet() {
        // Display status string while in modal state
        model?.status.statusMid = statusString
    }
    
    deinit {
        // Remove status string
        model?.status.statusMid = nil
    }
}


///
/// Block Recording context
///     For recording without execution of { block }
///
class BlockRecord : EventContext {
    
    var openCount = 1
    var fnRecording = false
    
    override func onActivate(lastEvent: KeyEvent) {
        guard let model = self.model else {
            assert(false)
            return
        }
        
        if model.aux.isRecording {
            // Already recording an Fn key
            // Remember that we were recording on enty - record the open brace
            fnRecording = true
        }
        else {
            // Start recording but remember we were not on entry
            fnRecording = false
            model.aux.startRecFn( lastEvent.kc )
        }
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "BlockRecord event: \(event.kc)")
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .showFn:
            return KeyPressResult.noOp
            
        case .openBrace:
            openCount += 1
            model.aux.recordKeyFn(event.kc)
            return KeyPressResult.recordOnly

        case .closeBrace:
            openCount -= 1
            
            if openCount == 0 {
                // Stop recording, restore the modal context and pass the .macro event
                // Don't stop recording if we were recording on entry
                model.popContext( event )
                return KeyPressResult.recordOnly
                
//                if fnRecording {
//                    // Record the close brace and continue
//                    model.aux.recordKeyFn(event.kc)
//                    model.popContext( event )
//                    return model.keyPress( event )
//                }
//                else {
//                    // We were not recording on entry - stop recording now, restore ctx to modal fn and pass .macro
//                    model.aux.stopRecFn(.openBrace)
//                    model.popContext( event )
//                    return model.keyPress( KeyEvent( kc: .macro ))
//                }
            }
            
            // Record the close brace and continue
            model.aux.recordKeyFn(event.kc)
            return KeyPressResult.recordOnly
            
        case .back:
            if model.aux.list.opSeq.isEmpty {
                
                // Cancel both BlockRecord context and the ModalContext that spawned it
                model.aux.stopRecFn(.openBrace)
                model.popContext( event )
                model.popContext( event )
                return KeyPressResult.stateUndo
            }
            else {
                // Remove last key event from recording
                model.aux.recordKeyFn(event.kc)
                return KeyPressResult.recordOnly
            }
            
        default:
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                model.pushContext( EntryContext(), lastEvent: event ) { _ in
                    
                    // Grab the entered data value and record it
                    let tv = model.grabTextEntry()
                    model.aux.recordValueFn( tv )
                }
                return KeyPressResult.dataEntry
            }
            
            // Record the key event
            model.aux.recordKeyFn(event.kc)
            return KeyPressResult.recordOnly
        }
    }
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

    // Display window into register stack
    @AppStorage(.settingsDisplayRows)
    private var displayRows = 3
    
    var rowCount: Int { return displayRows}

    var eventContext: EventContext?  = nil
    
    private var undoStack = UndoStack()
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
        self.displayRows = 3
        
        pushContext( NormalContext() )
        
        installMatrix(self)
        installComplex(self)
        installVector(self)
        installFunctions(self)
    }
    
    
    // *** Event Context functions ***

    func pushContext( _ ctx: EventContext, lastEvent: KeyEvent = KeyEvent( kc: .null ), _ ccc: ContextContinuationClosure? = nil ) {
        
        // Make this context active, linking to previous ones
        ctx.model = self
        ctx.previousContext = self.eventContext
        
        eventContext?.ccc = ccc
        eventContext = ctx
        eventContext?.onActivate( lastEvent: lastEvent )
        
        print( "change to: " + String(  describing: ctx.self ) + "\n")
    }
    
    func popContext( _ event: KeyEvent = KeyEvent( kc: .null ) ) {
        
        // Restore previous context
        if let oldContext = eventContext?.previousContext {
            eventContext = oldContext
            
            // Run the continuation closure if there is one
            eventContext?.ccc?( event )
            
            print( "restore: " + String(  describing: oldContext.self ) + "\n")
        }
    }
    

    // *** Entry State control ***
    
    func startEntryState( _ kc: KeyCode ) {
        // Start data entry with a digit or a dot
        
        if let prevCtx = eventContext?.previousContext {
            if prevCtx is BlockRecord {
                // Just start text entry, leave the stack alone
                entry.startTextEntry( kc )
                return
            }
        }
        
        // Normal entry, we prepare the stack for the new data
        pushState()
        state.stackLift()
        entry.startTextEntry( kc )
    }
    
    
    func acceptTextEntry() {
        if let tv = entry.makeTaggedValue() {
            // Store tagged value in X reg
            // Record data entry if recording
            // and clear data entry state
            entry.clearEntry()
            
            if let prevCtx = eventContext?.previousContext {
                if prevCtx is BlockRecord {
                    // Don't enter value to X
                    return
                }
            }
            
            // Keep new entered X value
            state.stack[regX].value = tv
        }
    }

    
    func grabTextEntry() -> TaggedValue {
        
        if let tv = entry.makeTaggedValue() {
            // Return the value
            entry.clearEntry()
            return tv
        }
        
        assert(false)
        return untypedZero
    }

    
    // *** Data Store ***
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.state")
    }
    
    func loadState() async throws {
        let task = Task<CalcState, Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return CalcState()
            }
            
            let state = try JSONDecoder().decode(CalcState.self, from: data)
            return state
        }
        
        let state = try await task.value
        
        Task { @MainActor in
            // Update the @Published property here
            self.state = state
        }
    }
    
    func saveState() async throws {
        let task = Task {
            let data = try JSONEncoder().encode(self.state)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
    
    // *** Data Store End ***
    
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
    
    // **** Macro Recording Stuff ***
    
    func saveMacroFunction( _ kc: KeyCode, _ list: MacroOpSeq ) {
        state.fnList[kc] = FnRec( fnKey: kc, macro: list)
    }
    
    func clearMacroFunction( _ kc: KeyCode) {
        state.fnList[kc] = nil
    }
    
    func getMacroFunction( _ kc: KeyCode ) -> MacroOpSeq? {
        state.fnList[kc]?.macro
    }
    
    // *******
    
    private func bufferIndex(_ stackIndex: Int ) -> Int {
        // Convert a bottom up index into the stack array to a top down index into the displayed registers
        return displayRows - stackIndex - 1
    }
    
    func renderRow( index: Int ) -> String {
        let stkIndex = bufferIndex(index)
        
        // Are we are in data entry mode and looking for the X reg
        if entry.entryMode && stkIndex == regX {
            let nv = state.stack[stkIndex]
            
            var text = String()
            
            if let prefix = nv.name {
                text.append("ƒ{0.8}ç{Frame}={\(prefix)  }ç{}ƒ{}")
            }
            
            text.append( "={\(entry.entryText)}" )
            
            if !entry.exponentEntry {
                text.append( "ç{CursorText}={_}ç{}" )
            }
            
            if entry.exponentEntry {
                text.append( "^{\(entry.exponentText)}ç{CursorText}^{_}ç{}" )
            }
            
            return text
        }
        let (str, _) = state.stack[stkIndex].renderRichText()
        return str
    }
    
    func memoryOp( key: KeyCode, index: Int ) {
        pushState()
        acceptTextEntry()
        
        // Leading edge swipe operations
        switch key {
        case .rcl:
            state.stackLift()
            state.Xtv = state.memory[index].value
            break
            
        case .sto:
            state.memory[index].value = state.Xtv
            break
            
        case .mPlus:
            if state.Xt == state.memory[index].value.tag {
                state.memory[index].value.reg += state.X
            }
            break
            
        case .mMinus:
            if state.Xt == state.memory[index].value.tag {
                state.memory[index].value.reg -= state.X
            }
            break
            
        default:
            break
        }
    }
    
    func addMemoryItem() {
        pushState()
        acceptTextEntry()
        state.memory.append( NamedValue( value: state.Xtv) )
        aux.activeView = .memoryList
    }
    
    func delMemoryItems( set: IndexSet) {
        pushState()
        entry.clearEntry()
        state.memory.remove( atOffsets: set )
    }
    
    func renameMemoryItem( index: Int, newName: String ) {
        pushState()
        entry.clearEntry()
        state.memory[index].name = newName
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
            
        case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
            if let macro = getMacroFunction(keyCode) {
                // Macro playback - save inital state just in case
                pushState()
                
                pushContext( PlaybackContext(), lastEvent: event )
                
                // Don't maintain undo stack during playback ops
                pauseUndoStack()
                for op in macro.opSeq {
                    if op.execute(self) == KeyPressResult.stateError {
                        resumeUndoStack()
                        popContext()
                        popState()
                        return KeyPressResult.stateError
                    }
                }
                resumeUndoStack()
                popContext( KeyEvent( kc: keyCode ) )
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
                        
                        // Fall through to error indication
                    }
                }
            }
            
            if keyCode.isUnit {
                // Attempt conversion of X reg to unit type keyCode
                if let tag = TypeDef.kcDict[keyCode]
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
    
    // **********************************************************************
    // **********************************************************************
    // **********************************************************************
    
    func getKeyText( _ kc: KeyCode ) -> String? {
        
        if KeyCode.fnSet.contains(kc) {
            
            if let fn = state.fnList[kc] {
                
                if let text = fn.caption {
                    // Fn key has provided caption text
                    return text
                }
                
                // Fn key has no caption text - make caption from key code
                return "Fn\(kc.rawValue % 10)"
            }
            
        }
        
        // Not a Fn key
        return nil
    }
    
    
    func isKeyRecording( _ kc: KeyCode = .null ) -> Bool {
        if kc == .null {
            return aux.kcRecording != nil
        }
        return aux.kcRecording == kc
    }
    
    
    func enterValue(_ tv: TaggedValue) {
        // For macros, bypass data entry mode and enter a value directly
        state.stackLift()
        state.Xtv = tv
        state.noLift = false
    }
}

