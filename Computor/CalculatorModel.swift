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
    
    case y2x = 40, inv, x2, sqrt
    
    case sin = 50, cos, tan, pi, asin, acos, atan
    
    case log = 80, ln, log2, logY
    
    case tenExp = 90, eExp, e
    
    // Format
    case fix = 120, sci, eng
    
    case null = 150, noop, rcl, sto, mPlus, mMinus
    
    // Softkeys
    case fn0 = 160, fn1, fn2, fn3, fn4, fn5, fn6
    
    // Macro Op
    case macroOp = 170, clrFn, recFn, stopFn, showFn
    
    // Multi valued types
    case multiValue = 180, rationalV, vector2V, polarV, complexV
    
    // Matrix operations
    case matrix = 190, range, seq, map, reduce
    
    case unitStart = 200
    
    // Length
    case km = 201, mm, cm, m, inch, ft, yd, mi
    
    // Time
    case sec = 210, min, hr, day, yr, ms, us
    
    // Angles
    case deg = 220, rad, dms
    
    // Mass
    case kg = 230, mg, gram, tonne, lb, oz, ton, stone
    
    // Temperature
    case degC = 240, degF
    
    case unitEnd = 299
    
    var isUnit: Bool { return self.rawValue > KeyCode.unitStart.rawValue && self.rawValue < KeyCode.unitEnd.rawValue }
}

let digitSet:Set<KeyCode> = [.key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9]

let fnSet:Set<KeyCode> = [.fn1, .fn2, .fn3, .fn4, .fn5, .fn6]

let macroOpSet:Set<KeyCode> = [.macroOp, .clrFn, .recFn, .stopFn, .showFn]


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


protocol StateOperator {
    func transition(_ s0: CalcState ) -> CalcState?
}


struct CustomOp: StateOperator {
    let block: (CalcState) -> CalcState?
    
    init(_ block: @escaping (CalcState) -> CalcState? ) {
        self.block = block
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        return block(s0)
    }
}

struct ConversionOp: StateOperator {
    let block: (TaggedValue) -> TaggedValue?
    
    init(_ block: @escaping (TaggedValue) -> TaggedValue? ) {
        self.block = block
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        var s1 = s0
        
        if let newTV = block( s0.Xtv ) {
            s1.Xtv = newTV
            return s1
        }
        else {
            return nil
        }
    }
}

struct Convert: StateOperator {
    let toType: TypeTag
    let toFmt: FormatRec?
    
    init( to: TypeTag, fmt: FormatRec? = nil ) {
        self.toType = to
        self.toFmt = fmt
    }
    
    init( sym: String, fmt: FormatRec? = nil ) {
        self.toType = TypeDef.symDict[sym, default: tagUntyped]
        self.toFmt = fmt
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        var s1 = s0

        if s1.convertX( toTag: toType) {
            if let fmt = toFmt {
                s1.Xfmt = fmt
            }
            else {
                s1.Xfmt = s0.Xfmt
            }
            return s1
        }
        else {
            return nil
        }
    }
}

struct Constant: StateOperator {
    let value: Double
    let tag: TypeTag

    init( _ value: Double, tag: TypeTag = tagUntyped ) {
        self.value = value
        self.tag = tag
    }
    
    func transition(_ s0: CalcState ) -> CalcState? {
        var s1 = s0
        s1.stackLift()
        s1.X = self.value
        s1.Xt = self.tag
        s1.Xfmt = CalcState.defaultDecFormat
        return s1
    }
}


protocol ModalFunction {
    
    // String to display while modal function is active
    var statusString: String? { get }
    
    // Key event handler for modal function
    func keyPress(_ event: KeyEvent, model: CalculatorModel) -> KeyPressResult
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


class CalculatorModel: ObservableObject, KeyPressHandler {
    // Current Calculator State
    @Published var state  = CalcState()
    @Published var entry  = EntryState()
    @Published var aux    = AuxState()
    @Published var status = StatusState()
    
    var undoStack = UndoStack()
    
    private var modalFunction : ModalFunction? = nil
    
    func setModalFunction( _ fn: ModalFunction ) {
        // Set fn as handler to receive next event, display status indicator
        modalFunction = fn
        status.statusMid = fn.statusString
    }
    
    func clearModalFunction() {
        modalFunction = nil
        status.statusMid = nil
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
    
    
    // Keycodes that are valid in data entry mode
    private let entryKeys:Set<KeyCode> = [.key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9, .dot, .sign, .back, .eex]
    
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
    
    struct UnaryOp: StateOperator {
        let parmType: TypeTag?
        let resultType: TypeTag?
        let function: (Double) -> Double
        
        init( parm: TypeTag? = nil, result: TypeTag? = nil, _ function: @escaping (Double) -> Double ) {
            self.parmType = parm
            self.resultType = result
            self.function = function
        }
        
        func transition(_ s0: CalcState ) -> CalcState? {
            var s1 = s0
            
            if let xType = self.parmType {
                // Check type of parameter
                if !s1.convertX( toTag: xType) {
                    // Cannot convert to required type
                    return nil
                }
            }
            s1.X = function( s1.X )
            
            if let rType = self.resultType {
                s1.Xt = rType
            }
            return s1
        }
    }
    
    struct BinaryOpReal: StateOperator {
        let function: (Double, Double) -> Double
        
        init(_ function: @escaping (Double, Double) -> Double ) {
            self.function = function
        }
        
        func transition(_ s0: CalcState ) -> CalcState? {
            if s0.Yt.uid != uidUntyped || s0.Xt.uid != uidUntyped {
                // Cannot use typed values
                return nil
            }
            
            var s1 = s0
            s1.stackDrop()
            s1.X = function( s0.Y, s0.X )
            return s1
        }
    }
    
    struct BinaryOpAdditive: StateOperator {
        let function: (Double, Double) -> Double
        
        init(_ function: @escaping (Double, Double) -> Double ) {
            self.function = function
        }
        
        func transition(_ s0: CalcState ) -> CalcState? {
            if let ratio = typeAddable( s0.Yt, s0.Xt) {
                // Operation is possible with scaling of X value
                var s1 = s0
                s1.stackDrop()
                s1.X = function( s0.Y, s0.X * ratio )
                return s1
            }
            else {
                // New state not possible
                return nil
            }
        }
    }
    
    
    struct BinaryOpMultiplicative: StateOperator {
        let kc: KeyCode
        
        init( _ key: KeyCode ) {
            self.kc = key
        }
        
        func _op( _ x: Double, _ y: Double ) -> Double {
            return kc == .times ? x*y : x/y
        }
        
        func transition(_ s0: CalcState ) -> CalcState? {
            var s1 = s0
            s1.stackDrop()
            
            if let (tag, ratio) = typeProduct(s0.Yt, s0.Xt, quotient: kc == .divide )
            {
                // Successfully produced new type tag
                s1.X = _op(s0.Y, s0.X) * ratio
                s1.Xt = tag
            }
            else {
                // Cannot multiply these types
                return nil
            }
            
            return s1
        }
    }
    
    static func defineOpCodes( _ newOpSet: [KeyCode : StateOperator] ) {
        // Add new operators to opTable, replacing duplicates with new value
        CalculatorModel.opTable.merge(newOpSet) { (_, newOp) in newOp }
    }
    
    static var opTable: [KeyCode : StateOperator] = [
        .plus:  BinaryOpAdditive( + ),
        .minus: BinaryOpAdditive( - ),
        .times: BinaryOpMultiplicative( .times ),
        .divide: BinaryOpMultiplicative( .divide ),

        // Math function row 0
        .sin:   UnaryOp( parm: tagRad, result: tagUntyped, sin ),
        .cos:   UnaryOp( parm: tagRad, result: tagUntyped, cos ),
        .tan:   UnaryOp( parm: tagRad, result: tagUntyped, tan ),
        
        .asin:   UnaryOp( parm: tagUntyped, result: tagRad, asin ),
        .acos:   UnaryOp( parm: tagUntyped, result: tagRad, acos ),
        .atan:   UnaryOp( parm: tagUntyped, result: tagRad, atan ),
            
        .log:   UnaryOp( result: tagUntyped, log10 ),
        .ln:    UnaryOp( result: tagUntyped, log ),
        .log2:  UnaryOp( result: tagUntyped, { x in log10(x)/log10(2) } ),
        
        .logY:  BinaryOpReal( { y, x in log10(x)/log10(y) } ),
        
        .tenExp: UnaryOp( parm: tagUntyped, result: tagUntyped, { x in pow(10.0, x) } ),
        .eExp: UnaryOp( parm: tagUntyped, result: tagUntyped, { x in exp(x) } ),

        .pi:    Constant( Double.pi ),
        .e:     Constant( exp(1.0) ),
        
        .sqrt:
            CustomOp { s0 in
                if s0.Xt == tagUntyped {
                    // Simple case, X is untyped value
                    var s1 = s0
                    s1.X = sqrt(s0.X)
                    return s1
                }
                
                if let tag = typeNthRoot(s0.Xt, n: 2) {
                    // Successful nth root of type tag
                    var s1 = s0
                    s1.Xtv = TaggedValue( tag: tag, reg: sqrt(s0.X), format: s0.Xfmt)
                    return s1
                }
                
                // Failed operation
                return nil
            },
        
        .y2x:
            CustomOp { (s0: CalcState) -> CalcState? in
                if s0.Xt != tagUntyped {
                    // Exponent must be untyped value
                    return nil
                }
                
                if s0.Yt == tagUntyped {
                    // Simple case, both operands untyped
                    var s1 = s0
                    s1.stackDrop()
                    s1.X = pow(s0.Y, s0.X)
                    return s1
                }
                
                if let exp = getInt(s0.X),
                   let tag = typeExponent( s0.Yt, x: exp )
                {
                    // Successful type exponentiation
                    var s1 = s0
                    s1.stackDrop()
                    s1.Xtv = TaggedValue( tag: tag, reg: pow(s0.Y, s0.X), format: s0.Yfmt)
                    return s1
                }
                
                // Failed operation
                return nil
            },
        
        .x2:
            CustomOp { s0 in
                if let (tag, ratio) = typeProduct(s0.Xt, s0.Xt) {
                    var s1 = s0
                    s1.Xtv = TaggedValue(tag: tag, reg: s0.X * s0.X, format: s0.Xfmt)
                    return s1
                }
                return nil
            },
        
        .percent:
            CustomOp { s0 in
                if s0.Xt == tagUntyped {
                    var s1 = s0
                    s1.Xtv = TaggedValue( tag: s0.Yt, reg: s0.X / 100.0 * s0.Y, format: s0.Yfmt)
                    return s1
                }
                return nil
            },
        
        .inv:
            CustomOp { s0 in
                if let (tag, ratio) = typeProduct(tagUntyped, s0.Xt, quotient: true) {
                    var s1 = s0
                    s1.Xtv = TaggedValue( tag: tag, reg: 1.0 / s0.X, format: s0.Xfmt)
                    return s1
                }
                return nil
            },
        
        .clX:
            // Clear X register
            CustomOp { s0 in
                var s1 = s0
                s1.Xtv = untypedZero
                s1.noLift = true
                return s1
            },

        .clY:
            // Clear Y register
            CustomOp { s0 in
                var s1 = s0
                s1.Ytv = untypedZero
                return s1
            },

        .clZ:
            // Clear Z register
            CustomOp { s0 in
                var s1 = s0
                s1.Ztv = untypedZero
                return s1
            },

        .clReg:
            // Clear registers
            CustomOp { s0 in
                var s1 = s0
                
                for i in 0 ..< stackSize {
                    s1.stack[i].value = untypedZero
                }
                s1.noLift = true
                return s1
            },
        
        .roll:
            // Roll down register stack
            CustomOp { s0 in
                var s1 = s0
                s1.stackRoll()
                return s1
            },
        
        .xy:
            // XY exchange
            CustomOp { s0 in
                var s1 = s0
                s1.Ytv = s0.Xtv
                s1.Xtv = s0.Ytv
                return s1
            },
        
        .yz:
            // Y Z exchange
            CustomOp { s0 in
                var s1 = s0
                s1.Ytv = s0.Ztv
                s1.Ztv = s0.Ytv
                return s1
            },

        .xz:
            // X Z exchange
            CustomOp { s0 in
                var s1 = s0
                s1.Ztv = s0.Xtv
                s1.Xtv = s0.Ztv
                return s1
            },
        
        .rationalV:
            // Form rational value from x, y
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xt.isType(.untyped) && s0.Yt.isType(.untyped) && isInt(s0.X) && isInt(s0.Y) && s0.Y != 0.0
                else {
                    return nil
                }
                var s1 = s0
                var (num, den) = (s0.X, s0.Y)
                if den < 0 {
                    num = -num
                    den = -den
                }
                s1.stackDrop()
                s1.set2( num, den )
                s1.Xstp = .rational
                return s1
            },

        .complexV:
            // Form complex value from x, y
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xt.isType(.untyped) && s0.Yt.isType(.untyped) else {
                    return nil
                }
                var s1 = s0
                s1.stackDrop()
                s1.set2( s0.X, s0.Y )
                s1.Xstp = .complex
                return s1
            },

        .vector2V:
            // Form vector value from x, y
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xt.isType(.untyped) && s0.Yt.isType(.untyped) else {
                    return nil
                }
                var s1 = s0
                s1.stackDrop()
                s1.set2( s0.X, s0.Y )
                s1.Xstp = .vector
                return s1
            },

        .polarV:
            // Form polar value from x, y
            CustomOp { (s0: CalcState) -> CalcState? in
                guard s0.Xt.isType(.untyped) && s0.Yt.isType(.untyped) else {
                    return nil
                }
                var s1 = s0
                s1.stackDrop()
                s1.set2( s0.X, s0.Y )
                s1.Xstp = .polar
                return s1
            },
        
        .deg: Convert( sym: "deg", fmt: FormatRec( style: .decimal) ),
        .rad: Convert( sym: "rad", fmt: FormatRec( style: .decimal) ),
        .dms: Convert( sym: "deg", fmt: FormatRec( style: .angleDMS)),
    ]
    
    
    func acceptTextEntry() {
        if let tv = entry.makeTaggedValue() {
            // Store tagged value in X reg
            // Record data entry if recording
            // and clear data entry state
            state.stack[regX].value = tv
            aux.recordValueFn(tv)
            entry.clearEntry()
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
                
            default:
                break
            }
        }
    }
    
    
    func keyPress(_ event: KeyEvent) -> KeyPressResult {
        let keyCode = event.kc
        
        if macroOpSet.contains(keyCode) || isKeyRecording(event.kc) {
            // Macro recording control key or the Fn key currently recording
            macroKeypress(event)
            return KeyPressResult.macroOp
        }
        
        if entry.entryMode {
            if entryKeys.contains(keyCode) {
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
        
        if digitSet.contains(keyCode) {
            // Start data entry with a digit
            undoStack.push(state)
            state.stackLift()
            entry.startTextEntry( String(keyCode.rawValue) )
            return KeyPressResult.dataEntry
        }
        else if keyCode == .dot {
            // Start data entry with a decimal point
            undoStack.push(state)
            state.stackLift()
            entry.startTextEntry( "0." )
            return KeyPressResult.dataEntry
        }

        if keyCode != .back {
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
            else if keyCode.isUnit {
                // Attempt conversion of X reg to unit type keyCode
                if let tag = TypeDef.kcDict[keyCode],
                   let _   = TypeDef.typeDict[tag]
                {
                    undoStack.push(state)
                    
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
