//
//  CalculatorModel.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-18.
//
import SwiftUI
import Numerics
import OSLog

extension Logger {
    
    init( category: String) {
        
        if Const.Log.model {
            self.init(subsystem: "com.microsnout.computor", category: category)
        }
        else {
            self.init(.disabled)
            
        }
    }
}

let logM = Logger( category: "model" )


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
    
    // Override string labels for X,Y and Z registers
    var regLabels: [String]? = nil
    
    var error = false
    
    var leftText: String { statusLeft ?? "" }
    
    var midText: String {
        if error {
            return "ç{StatusRedText}Errorç{}"
        }
        
        return "ç{StatusText}\(statusMid ?? "")ç{}"
    }
    
    var rightText: String { statusRight ?? "" }
    
    mutating func setRegisterLabels( _ labels: [String] ) {
        
        assert( labels.count > 0 && labels.count <= 3 )
        
        let n = labels.count
        
        // Longest label sets the field width
        var width = 0
        for str in labels {
            width = max(width, str.count)
        }
        
        // All right aligned lablel strings
        let range = 0...2
        
        self.regLabels = range.map( { x in
            
            let str = x < n ? labels[x] : CalcState.stackRegNames[x]
            
            var padded = ""
            
            str.withCString { cstr in
                
                padded = String( format: "%*s", width, cstr )
            }
            return padded
        } )
    }
    
    
    mutating func clearRegisterLabels() {
        self.regLabels = nil
    }
    
    
    func getRegisterLabel( _ index: Int ) -> String {
        assert( index <= 2 )
        
        if let setLabels = self.regLabels  {
            // Return temporary register label
            return setLabels[index]
        }
        
        // Use default register label
        return CalcState.stackRegNames[index]
    }
}


protocol StateOperator {
    func transition(_ s0: CalcState ) -> CalcState?
}


protocol StateOperatorEx {
    
    /// Extended version of StateOperator that returns a key press result as well as a possible new state
    
    func transition( _ model: CalculatorModel, _ s0: CalcState ) -> (KeyPressResult, CalcState?)
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
            model.pushState()
            model.pushValue(tv)
        }
    }
    
    func onModelSet() {
        // Override if needed
    }
    
    func getDisableSet( topKey: KeyCode ) -> Set<KeyCode> {
        // Default action - none are disabled
        return []
    }
    
    static var rollbackPoints: [Int : EventContext] = [:]
    
}


class LocalVariableFrame {
    var prevLVF: LocalVariableFrame?
    
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


enum SoftkeyUnits: Int, Equatable, Hashable, Codable {
    case mixed = 0, metric, imperial, physics, electrical, navigation
}


struct KeyState {
    
    var func2R: PadSpec = psFunctions2R
    
    // F1 .. F6 key mappings
    var keyMap: KeyMapRec = KeyMapRec()
    
    // Default Unit set
    var settings: ModuleSettingRec = ModuleSettingRec()
    
    init() {
        // Need to cycle all 3 possible values here to
        // overcome lazy evaluation of global let constants
        // and ensure that all keys are registered on time
        self.func2R = psFunctions2Ro
        self.func2R = psFunctions2Rc
        self.func2R = psFunctions2R

        self.keyMap = KeyMapRec()
        self.settings = ModuleSettingRec()
    }
}


// ***********************************************************
// ***********************************************************
// ***********************************************************

@Observable
class CalculatorModel: KeyPressHandler {
    
    // Current Calculator State
    var state  = CalcState()
    var entry  = EntryState()
    var aux    = AuxState()
    var status = StatusState()
    var kstate = KeyState()
    var db     = Database()
    
    // Currently active calculator document
    var activeModName: String = ""
    var activeModule: ModuleRec = ModuleRec( name: "" )

    // Pause for confirmation of some functions
    var modalConfirmation = true
    
    // Pause recording when value greater than 0
    var pauseRecCount: Int = 0

    // Display window into register stack
    let displayRows = 3
    
    // Current event handling context - Normal, Recording, Entry, ModalFunction, Block
    var eventContext: EventContext?  = nil
    
    var previousContext: EventContext? { eventContext?.previousContext }
    
    // Storage of memories local to a block {..}
    var currentLVF: LocalVariableFrame? = nil
    
    func pushLocalVariableFrame( _ lvf: LocalVariableFrame? = nil ) {
        
        if let lvfGiven = lvf {
            lvfGiven.prevLVF = currentLVF
            currentLVF = lvfGiven
        }
        else {
            // Allocate a new frame
            currentLVF = LocalVariableFrame( currentLVF )
        }
    }
    
    func popLocalVariableFrame() {
        currentLVF = currentLVF?.prevLVF
    }
    
    var currentMEC: ModuleExecutionContext? = nil
    
    var inLocalContext: Bool { currentLVF != nil }
    
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
    
    // *** Clock Timer ***
    
    private var lastKeyTick: Int
    
    func getTimeTick() -> Int {
        
        // Return time in seconds since 1970
        let currentDate = Date()
        let secondsSince1970 = currentDate.timeIntervalSince1970
        return Int(secondsSince1970)
    }
    
    // *** Change Counter ***
    
    var changeCount: Int = 0
    
    var isChanged: Bool { self.changeCount > 0 }
    
    func changed() { self.changeCount += 1 }
    
    func resetChanges() { self.changeCount = 0 }
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    // ***

    init() {
        self.state  = CalcState()
        self.entry  = EntryState()
        self.aux    = AuxState()
        self.status = StatusState()
        
        self.undoStack   = UndoStack()
        
        let currentDate = Date()
        let secondsSince1970 = currentDate.timeIntervalSince1970
        self.lastKeyTick = Int(secondsSince1970)
        
        self.changeCount = 0
        
        pushContext( NormalContext() )
    }
    
    
    func getLocalMacro( _ tag: SymbolTag ) -> MacroRec? {
        activeModule.getLocalMacro(tag)
    }
    
    
    // *** Local Memory Access ***
    
    func setLocalMemory( tag: SymbolTag, value: TaggedValue ) {
        
        assert( tag.isLocalMemoryTag )
            
        if let lvf = currentLVF {
            
            // Local block {..} memory
            lvf.local[tag] = value
        }
    }
    
    
    func rclLocalMemory( _ mTag: SymbolTag ) -> TaggedValue? {
        
        if mTag.isLocalMemoryTag {
            
            // Local memory tag recall
            var lvfOptional = currentLVF
            
            while let lvf = lvfOptional {
                
                if let val = lvf.local[mTag] {
                    
                    // Local block memory found
                    return val
                }
                
                lvfOptional = lvf.prevLVF
            }
            
            return nil
        }
        
        assert(false)
        return untypedZero
    }

    // ***
    
    
    func memoryStore( _ mTag: SymbolTag, _ tv: TaggedValue ) {
        
        if mTag.isLocalMemoryTag {
            
            setLocalMemory( tag: mTag, value: tv )
        }
        else {
            // Global memory
            
            if currentLVF == nil {
                // Only push the state if not running or recording a macro
                // Running or recording will push the state before the operation
                pushState()
            }
            
            setMemoryValue(at: mTag, to: tv)
            
            if currentLVF == nil {
                // Scroll aux display to memory list
                // Don't change the view unless top level key press
                aux.activeView = .memoryView
            }
        }
    }
    
    
    func memoryRecall( _ mTag: SymbolTag ) -> TaggedValue? {
        
        if mTag.isLocalMemoryTag {
            
            // Local Memory
            return rclLocalMemory(mTag)
        }
        else {
            
            // Global memory
            return getMemoryValue( at: mTag)
        }
    }

    // ***
    

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
    
    // ***

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
    
    
    func renderRow( index: Int ) -> String {
        
        /// ** Render Row **
        /// Produce a string rendering of the specified line of the primary display
        
        let stkIndex = bufferIndex(index)
        
        guard stkIndex <= regT else {
            assert(false)
            return ""
        }
        
        if entry.entryMode && stkIndex == regX {
            
            // We are in data entry mode and looking for the X reg
            var text = "ƒ{0.8}ç{RegLetterText}={X  }ç{}ƒ{}"
            
            var nx = 0
            var ne: NumericEntry
            
            repeat {
                ne = entry.entrySet[nx]
                
                // This is the last value if it is the 3rd or if the next is empty
                let last = nx == 2 || entry.entrySet[nx+1].entryText.isEmpty
                
                if nx > 0 {
                    text.append("ç{ModText}={,}ç{}")
                }
                
                text.append( "={\(ne.entryText)}" )
                
                if last && nx == entry.nx && !ne.exponentEntry {
                    text.append( "ç{CursorText}={_}ç{}" )
                }
                
                if last && nx == entry.nx && ne.exponentEntry {
                    text.append( "^{\(ne.exponentText)}ç{CursorText}^{_}ç{}" )
                }
                
                if last && nx < entry.nx {
                    // This is the last value but a comma has been entered so another is expected
                    text.append("ç{ModText}={,}ç{}ç{CursorText}={_}ç{}")
                }

                nx += 1

            } while nx < 3 && !entry.entrySet[nx].entryText.isEmpty
            
            return text
        }
        
        let tv = state.stack[stkIndex]
        var text = "ƒ{0.8}ç{RegLetterText}={\(status.getRegisterLabel(stkIndex))  }ç{}ƒ{}"
        let (valueStr, _) = tv.renderRichText()
        text += valueStr
        return text
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
    
    // ****************
    // Paired Functions
    
    func loadDocument( _ name: String ) {
        
        /// ** Load Document **
        
        if name != self.activeModName {
            
            // Save any changes before loading new doc
            saveDocument()
            
            if let modRec = db.getModuleFileRec( sym: name) {
                
                modRec.readModule() { obj in
                    
                    self.state = obj.state
                    self.kstate.keyMap = obj.keyMap
                    self.kstate.settings = obj.settings
                    
                    navigationPolar = obj.settings.navPolar
                    
                    UserUnitData.uud = obj.unitData
                    UnitDef.reIndexUserUnits()
                    TypeDef.reIndexUserTypes()
                    
                    self.activeModName = name
                    self.activeModule  = modRec
                    
                    // Setup AuxState
                    
                    // Macro list page to current mod
                    self.aux.macroMod = modRec

                    // Reset aux display to memory page
                    self.aux.activeView = obj.auxSettings.auxDisplay
                    
                    if let memRec = getMemory(obj.auxSettings.auxMemTag) {
                        self.aux.memRec = memRec
                    }
                    else {
                        self.aux.memRec = nil
                    }
                    
                    self.aux.macroTag = obj.auxSettings.auxMacroTag
                    
                    resetChanges()
                }
            }
        }
    }
    
    
    func saveDocument() {
        
        /// ** Save Document **
        
        if isChanged {
            print( "Autosave" )
            
            if let docRec = db.getModuleFileRec( sym: self.activeModName) {
                
                var auxSettings = AuxSettingRec()
                
                auxSettings.auxDisplay  = aux.activeView
                auxSettings.auxMemTag   = aux.memRec?.symTag ?? SymbolTag.Null
                auxSettings.auxMacroTag = aux.macroTag
                
                docRec.writeModule() { obj in
                    obj.state = self.state
                    obj.keyMap = self.kstate.keyMap
                    obj.unitData = UserUnitData.uud
                    obj.settings = self.kstate.settings
                    obj.auxSettings = auxSettings
                }
            }
            
            resetChanges()
        }
    }

    // ****************
    
    
    // Default Unit Sets
    let unitSetMixed: [KeyCode : KeyCode] = [
        .U2 : .mL, .U3 : .kg, .U4 : .hr, .U5 : .mi, .U6 : .km
    ]
    
    let unitSetMetric: [KeyCode : KeyCode] = [
        .U3 : .mL, .U4 : .hr, .U5 : .kg, .U6 : .km
    ]
    
    let unitSetNavigation: [KeyCode : KeyCode] = [
        .U1 : .NM, .U2 : .mL, .U3 : .kg, .U4 : .hr, .U5 : .mi, .U6 : .km
    ]

    func getDefaultUnitKeycode( _ kcUn: KeyCode ) -> KeyCode? {
        
        if KeyCode.UnSet.contains(kcUn) {
            
            switch kstate.settings.unitSet {
                
            case .mixed:
                return unitSetMixed[kcUn]
                
            case .metric:
                return unitSetMetric[kcUn]
                
            case .navigation:
                return unitSetNavigation[kcUn]
                
            default:
                return nil
            }
        }
        return nil
    }
    
    
    func getMappedKeycode( _ kc: KeyCode ) -> KeyCode {
        
        if KeyCode.UnSet.contains(kc) {
            
            // U1..U6
            if let tag = kstate.keyMap.tagAssignment(kc) {
                
                // Un has assigned tag
                if let kcUn = tag.getKeycode() {
                    
                    // It is a KeyCode mapping
                    return kcUn
                }
            }
            else if let kcUn = getDefaultUnitKeycode(kc) {
                
                // An unassigned Un key with default unit code
                return kcUn
            }
        }
        
        // No change
        return kc
    }
    
    
    // **********************************************************************
    
    func execute( _ event: KeyEvent ) -> KeyPressResult {
        
        // Consider state changed if this func is called
        changed()
        
        let keyCode = event.kc
        
        switch keyCode {
            
        case .noop, .noopBrace:
            return KeyPressResult.noOp
            
        case .backUndo:
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
            
        case .clearX:
            // Clear X register
            pushState()
            state.Xtv = untypedZero
            state.noLift = true
            
        case .popX:
            memoryStore( SymbolTag(.X), state.Xtv)
            state.stackDrop()

        case .stoX:
            if let mTag = event.mTag {
                memoryStore( mTag, state.Xtv )
            }
            
        case .stoY:
            if let mTag = event.mTag {
                memoryStore( mTag, state.Ytv )
            }
            
        case .stoZ:
            if let mTag = event.mTag {
                
                // Store Memory
                memoryStore( mTag, state.Ztv )
            }

        case .rcl:
            if let mTag = event.mTag {
                
                // Recall Memory
                if let tv = memoryRecall(mTag) {
                    pushState()
                    state.pushValue(tv)
                }
            }
            
        // Function keys and Unit keys
        case .F1, .F2, .F3, .F4, .F5, .F6, .U1, .U2, .U3, .U4, .U5, .U6:
            
            // Key F1..F6, U1..U6 pressed
            
            if let tag = kstate.keyMap.tagAssignment(keyCode),
               let (mr, mfr) = getMacroFunction(tag) {
                
                // Macro function execution
                var result = KeyPressResult.noOp

                // Macro tag assigned to Fn key
                (result, _) = playMacroSeq(mr.opSeq, in: mfr)
                
                if result == KeyPressResult.stateError {
                    return KeyPressResult.stateError
                }
            }
            else {
                // Default Fn, Un functions
                
                if KeyCode.fnSet.contains(keyCode) {
                    // Unassigned Fn keys are no op
                    return KeyPressResult.noOp
                }
                
                if KeyCode.UnSet.contains(keyCode) {
                    // Unassigned Un key is a Unit key
                    if let kc = getDefaultUnitKeycode(keyCode) {
                        let evt = KeyEvent(kc)
                        queueEvent(evt)
                    }
                    return KeyPressResult.noOp
                }
                
                assert(false)
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
                        (result, _) = playMacroSeq(mr.opSeq, in: mfr)
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
                        
                        let (opRes, opState) = lf.libFunc(self)
                        
                        if opRes == KeyPressResult.stateError
                        {
                            displayErrorIndicator()
                            return opRes
                        }
                        
                        if let newState = opState {
                            // Operation returned a new state, push in case of Undo
                            pushState()
                            state = newState
                            autoswitchFixSci()
                            state.noLift = false
                        }
                        return opRes
                    }
                }
            }
            
            if result == KeyPressResult.stateError {
                displayErrorIndicator()
                return KeyPressResult.stateError
            }
            
        default:
            
            // Search for operations matching this key code in the Op Table
            // The origingal dispatch method for simple functions of Real values
            // Functions return either a new state or nil for error conditions
            
            if let op = CalculatorModel.opTable[keyCode] {
                // Transition to new calculator state based on operation
                
                if let newState = op.transition( state ) {
                    // Operation has produced a new state
                    pushState()
                    state = newState
                    state.noLift = false
                    
                    
                    // Successful state change
                    autoswitchFixSci()
                    return KeyPressResult.stateChange
                }
            }
            
            // Search for operations in the Pattern Table
            // which provides pattern matching of parameters and types
            // Operators return both a key press result and a new state if there is one
            // Modal operators like mapX, do not return a new state but this does not
            // indicate an Error
            
            if let patternList = CalculatorModel.patternTable[keyCode] {
                
                for pattern in patternList {
                    
                    if state.patternMatch(pattern.regPattern) {
                        
                        // Transition to new calculator state based on operation
                        
                        let (opResult, opState): (_: KeyPressResult, _: CalcState?) = pattern.transition(self, state)
                        
                        if let newState = opState {
                            
                            assert( opResult == KeyPressResult.stateChange )
                            
                            pushState()
                            state = newState
                            state.noLift = false
                            
                            // Successful state change
                            autoswitchFixSci()
                            return KeyPressResult.stateChange
                        }
                        
                        if opResult != KeyPressResult.stateError {
                            return opResult
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
                                autoswitchFixSci()
                                return KeyPressResult.stateChange
                            }
                        }
                    }
                    
                    if state.convertX( toTag: tag) {
                        // Conversion succeded
                        state.noLift = false
                        
                        // Successful state change
                        autoswitchFixSci()
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
        autoswitchFixSci()
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
    
    
    func autoswitchFixSci() {
        
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
    }
    
    // **********************************************************************
    // **********************************************************************
    // **********************************************************************

    
    func keyPress(_ keyEvent: KeyEvent) -> KeyPressResult {
        
        if keyEvent.kc == .clockTick {
            
            let now = getTimeTick()
            
            if (now - lastKeyTick) > Const.Model.autosaveInterval {
                
                saveDocument()
                lastKeyTick = now
            }
            
            return KeyPressResult.noOp
        }
        
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
        
        // Timestamp this event
        lastKeyTick = getTimeTick()
        
        // State has likely changed
        changed()
        return result
    }
    
    
    enum KeyTextCode: Int {
        case none = 0, custom, funcKey, unitKey, symbol
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

        if KeyCode.fnSet.contains(kc) || KeyCode.UnSet.contains(kc) {
            // F1 to F6
            // U1 to U6
            
            if let fTag = kstate.keyMap.tagAssignment(kc) {
                
                // A SymbolTag is assigned to this key
                let tagText: String = fTag.getRichText()
                let text = fTag.isShortSym ? tagText : "ƒ{0.6}\(tagText)"
                return (text, .symbol)
            }
            
            // Disabled key, no macro
            
            if KeyCode.UnSet.contains(kc) {
                
                // Unassigned Un key
                if let kcUn = getDefaultUnitKeycode(kc) {
                    
                    guard let unKey = Key.keyList[kcUn] else {
                        assert(false)
                        return (kcUn.str, .unitKey)
                    }
                    
                    if let text = unKey.text {
                        return (text, .symbol)
                    }
                    return (kcUn.str , .unitKey)
                }
                return ("ç{GrayText}U\(kc.rawValue % 10)", .funcKey)
            }
            
            // Unassigned Fn key
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
        changed()
    }
    
    
    func enterRealValue( _ r: Double ) {
        let tv = TaggedValue( reg: r )
        enterValue(tv)
        changed()
    }

    
    func pushValue(_ tv: TaggedValue) {
        // For macros, bypass data entry mode and enter a value directly
        state.stackLift()
        state.Xtv = tv
        state.noLift = false
        changed()
    }
}

