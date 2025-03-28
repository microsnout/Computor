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
    
    func onModelSet() {
        // Override if needed
    }
    
    
    static var rollbackPoints: [Int : EventContext] = [:]
    
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
                if let fn = model.appState.fnList[kcFn] {
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
                
                // Start data entry mode, save current state and lift stack to make room for new data
                model.pushState()
                model.state.stackLift()
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.kc ==  .back {
                        
                        // Data entry was cancelled by back/undo key
                        model.popState()
                    }
                    else {
                        
                        // Successful data entry, copy to X reg
                        model.acceptTextEntry()
                    }
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
        model?.entry.startTextEntry( lastEvent.kc )
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        if !CalculatorModel.entryKeys.contains(event.kc) {
            
            // Return to invoking context, either Normal or Recording
            model.popContext( event )
            
            // Let the newly restored context handle this event
            return KeyPressResult.resendEvent
        }
        
        // Process data entry key event
        let keyRes = model.entry.entryModeKeypress(event.kc)
        
        if keyRes == .cancelEntry {
            // Exited entry mode
            // We backspace/undo out of entry mode
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
            
            // Push a new local variable store
            model.currentLVF = LocalVariableFrame( model.currentLVF )
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
            
            // Pop the local variable storage, restoring prev
            model.currentLVF = model.currentLVF?.prevLVF
            return KeyPressResult.cancelRecording
            
        case .showFn, .recFn, .openBrace, .closeBrace:
            return KeyPressResult.noOp
            
        case .stopFn:
            if !model.aux.list.opSeq.isEmpty {
                model.saveMacroFunction(kcFn, model.aux.list)
            }
            model.aux.stopRecFn(kcFn)
            model.popContext( event )
            
            // Pop the local variable storage, restoring prev
            model.currentLVF = model.currentLVF?.prevLVF
            return KeyPressResult.macroOp
            
        case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
            if model.appState.fnList[event.kc] == nil {
                // No op any undefined keys
                return KeyPressResult.noOp
            }
            model.aux.recordKeyFn( event )
            return model.execute( event )
            
        case .back:
            if model.aux.list.opSeq.isEmpty {
                
                // Cancel the recording
                model.aux.stopRecFn(kcFn)
                model.popContext( event )
                
                // Pop the local variable storage, restoring prev
                model.currentLVF = model.currentLVF?.prevLVF
                return KeyPressResult.cancelRecording
            }
            else {
                // First remove last key
                model.aux.recordKeyFn( event )
                
                if let ctx = model.getRollback(to: model.aux.list.opSeq.count) {
                    // Rollback, put modal function context and block record back
                    model.rollback(ctx)
                }
                
                // Execute the .back command to undo the state
                return model.execute( event )
            }
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                // Start data entry mode, save current state and lift stack to make room for new data
                model.pushState()
                model.state.stackLift()
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.kc ==  .back {
                        
                        // Data entry was cancelled by back/undo key
                        model.popState()
                    }
                    else {
                        // Successful data entry, copy to X reg
                        model.acceptTextEntry()
                        
                        // Record the value and key when returning to a recording context
                        model.aux.recordValueFn( model.state.Xtv )
                    }
                }
                return KeyPressResult.dataEntry
            }
            
            // Record key and execute it
            let result = model.execute( event )
            if result != .stateError {
                model.aux.recordKeyFn( event )
            }
            return result
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
        
        logM.debug( "Run Macro: \(String( describing: self.macroFn.getDebugText() ))")
        
        // Push a new local variable store
        model.currentLVF = LocalVariableFrame( model.currentLVF )

        for op in macroFn.opSeq {
            if op.execute( model ) == KeyPressResult.stateError {
                
                logM.debug( "Run Macro: ERROR")
                
                // Pop the local variable storage, restoring prev
                model.currentLVF = model.currentLVF?.prevLVF
                
                return KeyPressResult.stateError
            }
        }
        
        // Pop the local variable storage, restoring prev
        model.currentLVF = model.currentLVF?.prevLVF
        
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
                model.aux.recordKeyFn(event)
                
                // Save start index to recording for extracting block {..}
                let from = model.aux.markMacroIndex()

                model.pushContext( BlockRecord(), lastEvent: event ) { endEvent in
                    
                    if endEvent.kc == .back {
                        // We have backspaced the open brace, cancelling the block
                        // Stay in this context and wait for another function
                    }
                    else {
                        // Before recording closing brace, extract the macro
                        self.macroFn = MacroOpSeq( [any MacroOp](model.aux.list.opSeq[from...]) )
                        
                        // Now record the closing brace of the block
                        model.aux.recordKeyFn( endEvent )
                        
                        // Queue a .macro event to execute it
                        model.queueEvent( KeyEvent( kc: .macro ) )
                    }
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
            
        default:
            if event.kc != .macro && model.eventContext?.previousContext is RecordingContext {
                
                // Save rollback point in case the single key func is backspaced
                model.saveRollback( to: model.aux.list.opSeq.count )
                
                // Record the key
                model.aux.recordKeyFn( event )
                
                // Restore the Recording context before executing the function
                model.popContext( event )
            }
            
            // Restore either the Normal context before executing the function
            model.popContext( event )

            // Save the calc state in case modalExecute returns error
            model.pushState()
            
            model.pauseUndoStack()
            model.aux.pauseRecording()
            
            // ModalExecute runs with Undo stack paused
            let result =  modalExecute( event )
            
            if result == .stateError {
                model.popState()
            }
            
            model.aux.resumeRecording()
            model.resumeUndoStack()
            return result
        }
    }
    
    override func onModelSet() {
        // Display status string while in modal state
        model?.status.statusMid = statusString
    }
    
    override func onDeactivate( lastEvent: KeyEvent ) {
        // Remove status string
        model?.status.statusMid = nil
    }
}


///
/// Block Recording context
///     For recording without execution of { block }
///
class BlockRecord : EventContext {
    
    var openCount   = 0
    var macroIndex  = 0
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
        
        // Save the starting macro index
        macroIndex = model.aux.markMacroIndex()
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        print( "BlockRecord event: \(event.kc)")
        
        switch event.kc {
            
        case .clrFn, .stopFn, .recFn, .showFn:
            return KeyPressResult.noOp
            
        case .openBrace:
            openCount += 1
            model.aux.recordKeyFn(event)
            return KeyPressResult.recordOnly

        case .closeBrace:
            
            if openCount == 0 {
                // Restore the modal context and pass the .macro event
                model.saveRollback( to: model.aux.list.opSeq.count )
                
                // Pop back to the modal function state
                model.popContext( event )
                return KeyPressResult.recordOnly
            }
            
            openCount -= 1

            // Record the close brace and continue
            model.aux.recordKeyFn(event)
            return KeyPressResult.recordOnly
            
        case .back:
            if model.aux.list.opSeq.isEmpty {
                
                // Cancel both BlockRecord context and the ModalContext that spawned it
                model.aux.stopRecFn(.openBrace)
                model.popContext( event, runCCC: false )
                model.popContext( event, runCCC: false )
                return KeyPressResult.stateUndo
            }
            else {
                if macroIndex == model.aux.markMacroIndex() {
                    
                    // Remove last key event from recording
                    model.aux.recordKeyFn( event )
                    
                    // We have deleted the opening brace, return to modal function context
                    model.popContext( event )
                    
                    return KeyPressResult.stateUndo
                }
                else {
                    // Remove last key event from recording
                    model.aux.recordKeyFn( event )
                    
                    return KeyPressResult.stateUndo
                }
            }
            
        default:
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                model.pushContext( EntryContext(), lastEvent: event ) { exitEvent in
                    
                    if exitEvent.kc != .back {
                        
                        // Grab the entered data value and record it
                        let tv = model.grabTextEntry()
                        model.aux.recordValueFn( tv )
                    }
                }
                return KeyPressResult.dataEntry
            }
            
            // Record the key event
            model.aux.recordKeyFn(event)
            return KeyPressResult.recordOnly
        }
    }
}


class LocalVariableFrame {
    let prevLVF: LocalVariableFrame?
    
    var local: [KeyCode : TaggedValue] = [:]
    
    init( _ prev: LocalVariableFrame? = nil ) {
        self.prevLVF = prev
    }
}


struct ApplicationState : Codable {
    // Persistant state of all calculator customization for specific applications

    // Definitions of Fn programmable keys
    var fnList: [KeyCode : FnRec] = [:]
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
    
    // Persistant state of all calculator customization for specific applications
    // State of macro keys Fn1 to Fn6
    var appState = ApplicationState()

    // Display window into register stack
    @AppStorage(.settingsDisplayRows)
    var displayRows = 3
    
    // Current event handling context - Normal, Recording, Entry, ModalFunction, Block
    var eventContext: EventContext?  = nil
    
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
        
        logM.debug( "Push context: \(String( describing: ctx.self ))")
    }
    
    func popContext( _ event: KeyEvent = KeyEvent( kc: .null ), runCCC: Bool = true ) {
        
        // Restore previous context
        if let oldContext = eventContext?.previousContext {
            
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

    
    // *** Data Store ***
    
    struct DataStore : Codable {
        var state: CalcState
        var appState: ApplicationState
        
        init( _ state: CalcState = CalcState(), _ appS: ApplicationState = ApplicationState() ) {
            self.state = state
            self.appState = appS
        }
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.state")
    }
    
    func loadState() async throws {
        let task = Task<DataStore, Error> {
            let fileURL = try Self.fileURL()
            
            guard let data = try? Data( contentsOf: fileURL) else {
                return DataStore()
            }
            
            let state = try JSONDecoder().decode(DataStore.self, from: data)
            return state
        }
        
        let store = try await task.value
        
        Task { @MainActor in
            // Update the @Published property here
            self.state = store.state
            self.appState = store.appState
        }
    }
    
    func saveState() async throws {
        let task = Task {
            let store = DataStore( state, appState )
            let data = try JSONEncoder().encode(store)
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
        appState.fnList[kc] = FnRec( fnKey: kc, macro: list)
    }
    
    func clearMacroFunction( _ kc: KeyCode) {
        appState.fnList[kc] = nil
    }
    
    func getMacroFunction( _ kc: KeyCode ) -> MacroOpSeq? {
        appState.fnList[kc]?.macro
    }
    
    // *******
    
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
            let tv = state.Xtv
            
            var text = "ƒ{0.8}ç{Frame}={X  }ç{}ƒ{}"
            
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
        var text = "ƒ{0.8}ç{Frame}={\(CalculatorModel.stackRegNames[stkIndex])  }ç{}ƒ{}"
        let (valueStr, valueCount) = tv.renderRichText()
        let count = valueCount + 3
        text += valueStr
        return text
    }
    
    func memoryOp( key: KeyCode, index: Int ) {
        pushState()
        acceptTextEntry()
        
        // Leading edge swipe operations
        switch key {
        case .rclMem:
            state.stackLift()
            state.Xtv = state.memory[index].tv
            break
            
        case .stoMem:
            state.memory[index].tv = state.Xtv
            break
            
        case .mPlus:
            if state.Xt == state.memory[index].tv.tag {
                state.memory[index].tv.reg += state.X
            }
            break
            
        case .mMinus:
            if state.Xt == state.memory[index].tv.tag {
                state.memory[index].tv.reg -= state.X
            }
            break
            
        default:
            break
        }
    }
    
    func addMemoryItem() {
        pushState()
        acceptTextEntry()
        state.memory.append( MemoryRec( tv: state.Xtv) )
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
    
    
    func storeRegister( _ event: KeyEvent, _ tv: TaggedValue ) {
        
        if let kcMem = event.kcAux {
            
            if let lvf = currentLVF {
                
                // Local block {..} memory
                lvf.local[kcMem] = tv
            }
            else {
                // Global memory
                pushState()
                let name = String( describing: kcMem ).uppercased()
                let mr   = MemoryRec( tv: tv, kc: kcMem, name: name )
                
                if let index = state.memory.firstIndex( where: { $0.kc == kcMem }) {
                    
                    // Existing global memory
                    state.memory[index] = mr
                }
                else {
                    // New global memory
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
            
            
            // TODO: Adding .sto and .rcl here
            
        case .popX:
            storeRegister( KeyEvent( kc: .popX, kcAux: .x ), state.Xtv)
            state.stackDrop()

        case .popXY:
            pushState()
            pauseUndoStack()
            storeRegister( KeyEvent( kc: .popXY, kcAux: .x ), state.Xtv)
            storeRegister( KeyEvent( kc: .popXY, kcAux: .y ), state.Ytv)
            resumeUndoStack()
            state.stackDrop()
            state.stackDrop()
            
        case .popXYZ:
            pushState()
            pauseUndoStack()
            storeRegister( KeyEvent( kc: .popXYZ, kcAux: .x ), state.Xtv)
            storeRegister( KeyEvent( kc: .popXYZ, kcAux: .y ), state.Ytv)
            storeRegister( KeyEvent( kc: .popXYZ, kcAux: .z ), state.Ytv)
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
            if let kcMem = event.kcAux {
                
                let name = String( describing: kcMem ).uppercased()
                
                var tv: TaggedValue
                
                if let lvf = currentLVF,
                   let val = lvf.local[kcMem]
                {
                    // Local block memory found
                    tv = val
                }
                else if let index = state.memory.firstIndex(where: { $0.kc == kcMem }) {
                    
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
            
        case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
            if let macro = getMacroFunction(keyCode) {
                // Macro playback - save inital state just in case
                pushState()
                
                pushContext( PlaybackContext(), lastEvent: event )
                
                // Push a new local variable store
               currentLVF = LocalVariableFrame( currentLVF )

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

                // Pop the local variable storage, restoring prev
                currentLVF = currentLVF?.prevLVF
                
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
            
            if let fn = appState.fnList[kc] {
                
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

