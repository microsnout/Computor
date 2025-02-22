//
//  CalculatorModel.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2021-10-28.
//

import SwiftUI
import Numerics
import OSLog

let logM = Logger(subsystem: "com.microsnout.calculator", category: "model")


enum KeyCode: Int {
    case key0 = 0, key1, key2, key3, key4, key5, key6, key7, key8, key9
    
    case plus = 10, minus, times, divide
    
    case dot = 20, enter, clX, clY, clZ, clReg, back, sign, eex
    
    case fixL = 30, fixR, roll, xy, xz, yz, lastx, percent
    
    case y2x = 40, inv, x2, sqrt, abs
    
    case sin = 50, cos, tan, asin, acos, atan, csc, sec, cot, acsc, asec, acot, sinh, cosh, tanh, asinh, acosh, atanh
    
    case log = 80, ln, log2, logY
    
    case tenExp = 90, eExp, e, pi
    
    // Complex operations
    case zRe = 100, zIm, zArg, zConj, zNorm
    
    // Format
    case fix = 120, sci, eng
    
    case null = 150, noop, rcl, sto, mPlus, mMinus, mRename
    
    // Softkeys
    case fn0 = 160, fn1, fn2, fn3, fn4, fn5, fn6
    
    // Macro Op
    case macroOp = 170, clrFn, recFn, stopFn, showFn, openBrace, closeBrace, macro
    
    // Multi valued types
    case multiValue = 180, rationalV, vector2D, polarV, complexV
    
    // Matrix operations
    case matrix = 190, range, seq, map, reduce
    
    case unitStart = 200
    
    // Length
    case km = 201, mm, cm, m, inch, ft, yd, mi
    
    // Time
    case second = 210, min, hr, day, yr, ms, us
    
    // Angles
    case deg = 220, rad, dms
    
    // Mass
    case kg = 230, mg, gram, tonne, lb, oz, ton, stone
    
    // Capacity
    case mL = 240, liter, floz, cup, pint, quart, us_gal, gal
    
    // Temperature
    case degC = 250, degF
    
    case unitEnd = 299
    
    var isUnit: Bool { return self.rawValue > KeyCode.unitStart.rawValue && self.rawValue < KeyCode.unitEnd.rawValue }
}

let digitSet:Set<KeyCode> = [.key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9]

let fnSet:Set<KeyCode> = [.fn1, .fn2, .fn3, .fn4, .fn5, .fn6, .openBrace]

let macroOpSet:Set<KeyCode> = [.macroOp, .clrFn, .recFn, .stopFn, .showFn, .openBrace]


struct UndoStack {
    private let maxItems = 12
    private var storage = [CalcState]()
    private var pauseCount: Int = 0
    
    mutating func push(_ state: CalcState ) {
        if pauseCount == 0 {
            storage.append(state)
            
            if storage.count > maxItems {
                storage.removeFirst()
            }
        }
    }
    
    mutating func pop() -> CalcState? {
        if pauseCount == 0 {
            return storage.popLast()
        }
        
        return nil
    }
    
    mutating func pause() {
        pauseCount += 1
    }

    mutating func resume() {
        pauseCount -= 1
    }
}


class ModalFunction {
    
    // String to display while modal function is active
    var statusString: String? { nil }
    
    var macroFn: [MacroOp] = []

    // Key event handler for modal function
    func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult {
        KeyPressResult.null
    }
    
    func runMacro( model: CalculatorModel ) -> KeyPressResult {
        for op in macroFn {
            if op.execute( model ) == KeyPressResult.stateError {
                return KeyPressResult.stateError
            }
        }
        return KeyPressResult.stateChange
    }
    
    func executeFn( _ event: KeyEvent, model: CalculatorModel ) -> KeyPressResult {
        if event.kc == .macro {
            return runMacro(model: model)
        }
        
        return model.keyPress(event)
    }
}


struct StatusState {
    var statusLeft:  String? = nil
    var statusMid:   String? = nil
    var statusRight: String? = nil
    
    var error = false
    
    var midText: String {
        if error {
            return "ç{StatusRedText}Errorç{}"
        }
        
        return statusMid ?? ""
    }

}


protocol StateOperator {
    func transition(_ s0: CalcState ) -> CalcState?
}


class CalculatorModel: ObservableObject, KeyPressHandler {
    // Current Calculator State
    @Published var state  = CalcState()
    @Published var entry  = EntryState()
    @Published var aux    = AuxState()
    @Published var status = StatusState()
    
    var undoStack = UndoStack()
    
    private var modalFunction : ModalFunction? = nil
    
    var modalActive: Bool { modalFunction != nil }
    
    func setModalFunction( _ fn: ModalFunction ) {
        // Set fn as handler to receive next event, display status indicator
        modalFunction = fn
        status.statusMid = fn.statusString
    }
    
    func clearModalFunction() {
        modalFunction = nil
        status.statusMid = nil
    }
    
    private var execPauseCount: Int = 0
    
    func pauseExecution() {
        execPauseCount += 1
    }
    
    func resumeExecution() -> Int {
        execPauseCount -= 1
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
        self.modalFunction = nil
        self.displayRows = 3
        
        installMatrix(self)
        installComplex(self)
        installVector(self)
    }
    
    // **** Macro Recording Stuff ***
    
    func setMacroFn( _ kc: KeyCode, _ list: [MacroOp] ) {
        state.fnList[kc] = FnRec( caption: "Fn\(kc.rawValue % 10)", macro: list)
    }
    
    func clearMacroFn( _ kc: KeyCode) {
        state.fnList[kc] = nil
    }
    
    func getMacroFn( _ kc: KeyCode ) -> [MacroOp]? {
        if let fn = state.fnList[kc] {
            return fn.macro
        }
        
        return nil
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
        undoStack.push(state)
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
        undoStack.push(state)
        acceptTextEntry()
        state.memory.append( NamedValue( value: state.Xtv) )
        aux.mode = .memoryList
    }
    
    func delMemoryItems( set: IndexSet) {
        undoStack.push(state)
        entry.clearEntry()
        state.memory.remove( atOffsets: set )
    }
    
    func renameMemoryItem( index: Int, newName: String ) {
        undoStack.push(state)
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
            aux.recordValueFn(tv)
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
    
    
    func macroKeypress( _ event: KeyEvent ) {
        if let kc = event.kcTop {
            
            switch event.kc {
            case .clrFn:
                // Clear Function Key
                clearMacroFn(kc)
                aux.stopRecFn(kc)
                
            case .recFn:
                // Start Recording Function Key
                // Accept data entry before starting recording to avoid recording the entry
                acceptTextEntry()
                aux.startRecFn(kc)
                
            case .stopFn:
                // Stop Function Key recording
                if aux.recording && !aux.list.isEmpty {
                    setMacroFn(kc, aux.list)
                }
                aux.stopRecFn(kc)
                
            case .showFn:
                // Display Function Key steps in Aux view
                if let fn = state.fnList[kc] {
                    aux.list = fn.macro
                    aux.mode = .macroList
                }

            default:
                break
            }
        }
        else {
            switch event.kc {
            case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
                if aux.recording && !aux.list.isEmpty {
                    // Stop recording pressed key
                    setMacroFn(event.kc, aux.list)
                }
                aux.stopRecFn(event.kc)
                
            case .openBrace:
                acceptTextEntry()
                if modalActive {
                    if aux.recording {
                        // If we are already recording, this is a nested {fn} so
                        // we record the open { for future playback
                        aux.recordKeyFn(.openBrace)
                    }
                    else {
                        // Start recording but don't record the open {
                        aux.startRecFn(event.kc)
                    }
                    // Increment the pause count so we resume at final }
                    pauseExecution()
                }

            default:
                break
            }
        }
    }
    
    
    // Set of keys that cause data entry mode to begin, digits and dot
    private static let entryStartKeys = digitSet.union( Set<KeyCode>([.dot]) )

    // Set of keys valid in data entry mode, all of above plus sign, back and enter exp
    private static let entryKeys =  entryStartKeys.union( Set<KeyCode>([.sign, .back, .eex]) )

    
    func keyPress(_ event: KeyEvent) -> KeyPressResult {
        let keyCode = event.kc
        
        if macroOpSet.contains(keyCode) || isKeyRecording(event.kc) {
            // Macro recording control key or the Fn key currently recording
            macroKeypress(event)
            return KeyPressResult.macroOp
        }
        
        if entry.entryMode {
            if CalculatorModel.entryKeys.contains(keyCode) {
                // Process data entry key event
                let keyRes = entry.entryModeKeypress(keyCode)
                
                if keyRes == .cancelEntry {
                    // Exited entry mode
                    // We backspace/undo out of entry mode - need to pop stack
                    // to restore state before entry mode
                    if let lastState = undoStack.pop() {
                        state = lastState
                    }
                    return KeyPressResult.stateUndo
                }
                
                // Stay in entry mode
                return KeyPressResult.dataEntry
            }
            
            // Any key other than valid Entry mode keys cause en exit from the mode
            // with acceptance of the entered value, followed by regular processing of key
            acceptTextEntry()
        }
        
        if CalculatorModel.entryStartKeys.contains(keyCode) {
            
            // Start data entry with a digit or a dot
            undoStack.push(state)
            state.stackLift()
            
            if keyCode == .dot {
                entry.startTextEntry( "0." )
            }
            else {
                // Start with single digit
                entry.startTextEntry( String(keyCode.rawValue) )
            }
            return KeyPressResult.dataEntry
        }
        
        if modalActive && execPauseCount > 0 {
            if keyCode == .closeBrace {
                if resumeExecution() > 0 {
                    if keyCode != .back && keyCode != .closeBrace {
                        // Record all keys except back/undo and data entry keys
                        aux.recordKeyFn(keyCode)
                    }
                    return KeyPressResult.recordOnly
                }
                
                // Top level } seen
                // Drop through to close modal fn
            }
            else {
                if keyCode != .back && keyCode != .closeBrace {
                    // Record all keys except back/undo and data entry keys
                    aux.recordKeyFn(keyCode)
                }
                // Do not continue to execute keypress
                return KeyPressResult.recordOnly
            }
        }

        if keyCode != .back && keyCode != .closeBrace {
            // Record all keys except back/undo and data entry keys
            aux.recordKeyFn(keyCode)
        }

        if let modalFn = self.modalFunction {
            // Pass key event to sub function processor like reduce matrix
            clearModalFunction()
            
            if keyCode == .back {
                // Cancel modal function execution
                return KeyPressResult.stateUndo
            }
            
            if keyCode == .closeBrace {
                // We have a macro function {}
                modalFn.macroFn = aux.list
                aux.stopRecFn(.openBrace)
                undoStack.push(state)
                return modalFn.keyPress( KeyEvent( kc: .macro), model: self)
            }
            
            // Function assigned to a key
            undoStack.push(state)
            return modalFn.keyPress(event, model: self)
        }
        
        switch keyCode {
        case .back:
            // Undo last operation by restoring previous state
            if let lastState = undoStack.pop() {
                state = lastState
                return KeyPressResult.stateUndo
            }
            
        case .enter:
            // Push stack up, x becomes entry value
            undoStack.push(state)
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
            undoStack.push(state)
            state.Xfmt.style = .decimal
            
        case .sci:
            undoStack.push(state)
            state.Xfmt.style = .scientific
            
        case .clX:
            // Clear X register
            undoStack.push(state)
            state.Xtv = untypedZero
            state.noLift = true
            
        case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
            if let macro = getMacroFn(keyCode) {
                // Macro playback - save inital state just in case
                undoStack.push(state)
                
                // Don't maintain undo stack during playback ops
                undoStack.pause()
                aux.pauseRecording()
                for op in macro {
                    if op.execute(self) == KeyPressResult.stateError {
                        aux.resumeRecording()
                        undoStack.resume()
                        
                        // Rewind state to start of macro playback
                        if let lastState = undoStack.pop() {
                            state = lastState
                        }
                        return KeyPressResult.stateError
                    }
                }
                aux.resumeRecording()
                undoStack.resume()
            }

        default:
            
            if let op = CalculatorModel.opTable[keyCode] {
                // Transition to new calculator state based on operation
                undoStack.push(state)
                
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
                    if let lastState = undoStack.pop() {
                        state = lastState
                    }

                    if modalFunction != nil {
                        // Modal function started with no state change, not an error
                        return KeyPressResult.modalFunction
                    }

                }
            }
            
            if let patternList = CalculatorModel.patternTable[keyCode] {
                for pattern in patternList {
                    if state.patternMatch(pattern.regPattern) {
                        // Transition to new calculator state based on operation
                        undoStack.push(state)
                        
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
                    undoStack.push(state)
                    
                    for pattern in CalculatorModel.conversionTable {
                        if state.patternMatch(pattern.regPattern) {
                            undoStack.push(state)

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
                        if let lastState = undoStack.pop() {
                            state = lastState
                        }
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
    
    
    func getKeyText( _ kc: KeyCode ) -> String? {
        if let fn = state.fnList[kc] {
            return fn.caption
        }
        
        return nil
    }

    func isKeyRecording( _ kc: KeyCode = .null ) -> Bool {
        if kc == .null {
            return aux.kcRecording != nil
        }
        return aux.kcRecording == kc
    }
    
    func enterValue(_ tv: TaggedValue) {
        state.stackLift()
        state.Xtv = tv
        state.noLift = false
    }
}
