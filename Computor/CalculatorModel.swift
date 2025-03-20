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


///
///  Event Context
///
class EventContext {
    var previousContext: EventContext? = nil
    
    weak var model: CalculatorModel? = nil {
        didSet {
            onModelSet()
        }
    }
    
    func onActivate() {
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
            if let kcFn = event.kcAux {
                model.acceptTextEntry()
                model.aux.startRecFn(kcFn)
            }
            model.changeContext( RecordingContext() )
            return KeyPressResult.macroOp
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                // Start data entry mode
                model.startEntryState( event.kc )
                model.changeContext( EntryContext() )
                return KeyPressResult.dataEntry
            }
            
            return model.execute( event )
        }
    }
}


///
/// Entry event context
///
class EntryContext : EventContext {
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        if !CalculatorModel.entryKeys.contains(event.kc) {
            // Any key other than valid Entry mode keys cause en exit from the mode
            // with acceptance of the entered value,
            model.acceptTextEntry()
            
            // followed by regular processing of key
            model.restoreContext()
            return model.execute( event )
        }
        
        // Process data entry key event
        let keyRes = model.entry.entryModeKeypress(event.kc)
        
        if keyRes == .cancelEntry {
            // Exited entry mode
            // We backspace/undo out of entry mode - need to pop stack
            // to restore state before entry mode
            model.popState()
            model.restoreContext()
            return KeyPressResult.stateUndo
        }
        
        // Stay in entry mode
        return KeyPressResult.dataEntry
    }
}


///
/// Recording data entry context
///
class EntryRecordingContext : EventContext {
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        if !CalculatorModel.entryKeys.contains(event.kc) {
            
            // Any key other than valid Entry mode keys cause en exit from the mode
            // with acceptance of the entered value,
            model.acceptTextEntry()
            model.aux.recordValueFn( model.state.Xtv )
            model.aux.recordKeyFn( event.kc )
            
            // followed by regular processing of key
            model.restoreContext()
            return model.execute( event )
        }
        
        // Process data entry key event
        let keyRes = model.entry.entryModeKeypress(event.kc)
        
        if keyRes == .cancelEntry {
            // Exited entry mode
            // We backspace/undo out of entry mode - need to pop stack
            // to restore state before entry mode
            model.popState()
            model.restoreContext()
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
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .clrFn:
            if let kcFn = event.kcAux {
                model.clearMacroFunction(kcFn)
                model.aux.stopRecFn(kcFn)
            }
            model.restoreContext()
            return KeyPressResult.cancelEntry
            
        case .showFn, .recFn:
            return KeyPressResult.noOp
            
        case .stopFn:
            if let kcFn = event.kcAux {
                if !model.aux.list.opSeq.isEmpty {
                    model.saveMacroFunction(kcFn, model.aux.list)
                }
                model.aux.stopRecFn(kcFn)
            }
            model.restoreContext()
            return KeyPressResult.macroOp
            
        case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
            if model.state.fnList[event.kc] == nil {
                // No op any undefined keys
                return KeyPressResult.noOp
            }
            model.aux.recordKeyFn( event.kc )
            return model.execute( event )
            
        default:
            
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                // Start data entry with a digit or a dot
                model.startEntryState( event.kc )
                model.changeContext( EntryRecordingContext() )
                return KeyPressResult.dataEntry
            }
            
            // Record key and exexute it
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
    
    // String to display while modal function is active
    var statusString: String? { nil }
    
    var macroFn: MacroOpSeq = MacroOpSeq()
    
    // Key event handler for modal function
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
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
        
        switch event.kc {
            
        case .macro:
            return runMacro(model: model)
            
        default:
            return model.keyPress(event)
        }
    }
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        switch event.kc {
            
        case .openBrace:
            // Start recording, don't record the open brace at top level
            model.aux.startRecFn(event.kc)
            model.changeContext( BlockRecord() )
            return KeyPressResult.recordOnly
            
        default:
            // Modal terminates, restore previous context, clear status display
            if event.kc == .macro {
                // Copy macro from aux
                macroFn = model.aux.list
            }
            model.restoreContext()
            model.pushState()
            let result =  keyPress( event )
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
    
    override func event( _ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
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
                model.aux.stopRecFn(.openBrace)
                model.restoreContext()
                return model.keyPress( KeyEvent( kc: .macro ))
            }
            model.aux.recordKeyFn(event.kc)
            return KeyPressResult.recordOnly
            
        case .back:
            if model.aux.list.opSeq.isEmpty {
                
                // Cancel both BlockRecord context and the ModalContext that spawned it
                model.aux.stopRecFn(.openBrace)
                model.restoreContext()
                model.restoreContext()
                return KeyPressResult.stateUndo
            }
            else {
                // Remove last key event from recording
                model.aux.recordKeyFn(event.kc)
                return KeyPressResult.recordOnly
            }
            
        default:
            if CalculatorModel.entryStartKeys.contains(event.kc) {
                
                // Start data entry with a digit or a dot
                model.startEntryState( event.kc )
                model.changeContext( EntryRecordingContext() )
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
    
    var eventContext: EventContext?
    
    func changeContext( _ ctx: EventContext ) {
        
        // Make this context active, linking to previous ones
        ctx.model = self
        ctx.previousContext = self.eventContext
        eventContext = ctx
        eventContext?.onActivate()
        
        print( "change to: " + String(  describing: ctx.self ) + "\n")
    }
    
    func restoreContext() {
        
        // Restore previous context
        if let oldContext = eventContext?.previousContext {
            eventContext = oldContext
            
            print( "restore: " + String(  describing: oldContext.self ) + "\n")
        }
    }
    
    func startEntryState( _ kc: KeyCode ) {
        // Start data entry with a digit or a dot
        pushState()
        state.stackLift()
        entry.startTextEntry( kc )
    }
    
    // *** Store ***
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
    // *** Store End ***
    
    private var undoStack = UndoStack()
    private var stackPauseCount: Int = 0
    
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
    
    private var execPauseCount: Int = 0
    
    func pauseExecution() {
        execPauseCount += 1
        
        // Show status of open macro - could add one brace per level
        status.statusLeft = "ç{Units}={ {..}"
    }
    
    func resumeExecution() -> Int {
        execPauseCount -= 1
        
        if execPauseCount == 0 {
            // All openBrace nested macros are closed
            status.statusLeft = nil
        }
        return execPauseCount
    }
    
    // Display window into register stack
    @AppStorage(.settingsDisplayRows)
    private var displayRows = 3
    
    var rowCount: Int { return displayRows}
    
    init() {
        self.state  = CalcState()
        self.entry  = EntryState()
        self.aux    = AuxState()
        self.status = StatusState()
        self.undoStack   = UndoStack()
        self.displayRows = 3
        
        changeContext( NormalContext() )

        installMatrix(self)
        installComplex(self)
        installVector(self)
        installFunctions(self)
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
    
    
    func acceptTextEntry() {
        if let tv = entry.makeTaggedValue() {
            // Store tagged value in X reg
            // Record data entry if recording
            // and clear data entry state
            entry.clearEntry()
            
            if execPauseCount > 0 {
                // Restore the stack by removing X
                state.stackDrop()
            }
            else {
                // Keep new entered X value
                state.stack[regX].value = tv
            }
        }
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
                
                changeContext( PlaybackContext() )
                
                // Don't maintain undo stack during playback ops
                pauseUndoStack()
                for op in macro.opSeq {
                    if op.execute(self) == KeyPressResult.stateError {
                        resumeUndoStack()
                        restoreContext()
                        popState()
                        return KeyPressResult.stateError
                    }
                }
                resumeUndoStack()
                restoreContext()
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
        
        return eventContext?.event( keyEvent ) ?? KeyPressResult.null
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

