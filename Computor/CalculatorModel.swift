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


func isInt( _ x: Double ) -> Int? {
    /// Test if a Double is an integer
    /// Valid down to 1.0000000000000005 or about 16 significant digits
    ///
    x == floor(x) ? Int(x) : nil
}

func isEven( _ x: Int ) -> Bool {
    // Return true if x is evenly divisible by 2.
    x % 2 == 0
}


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
    
    mutating func pauseStack() {
        pauseCount += 1
    }

    mutating func resumeStack() {
        pauseCount -= 1
    }
}


protocol StateOperator {
    func transition(_ s0: CalcState ) -> CalcState?
}


enum AuxDispMode: Int {
    case memoryList = 0, memoryDetail, fnList
}

struct AuxState {
    var mode: AuxDispMode = .memoryList
    var list: [MacroOp] = []
    
    var kcRecording: KeyCode? = nil
    var recording: Bool { kcRecording != nil }
    var pauseCount: Int = 0
    
    mutating func pauseRecording() {
        pauseCount += 1
    }

    mutating func resumeRecording() {
        pauseCount -= 1
    }
    
    mutating func startRecFn( _ kc: KeyCode ) {
        if fnSet.contains(kc) && kcRecording == nil {
            kcRecording = kc
            list = []
            mode = .fnList
            
            // Disable all Fn keys except the one recording
            for key in fnSet {
                if key != kc {
                    SubPadSpec.disableList.insert(key)
                }
            }
        }
    }
    
    mutating func recordKeyFn( _ kc: KeyCode ) {
        if pauseCount > 0 {
            return
        }
        
        if recording
        {
            // Fold unit keys into value on stack if possible
            if kc.isUnit {
                if let last = list.last,
                   let value = last as? MacroValue
                {
                    if value.tv.tag == tagUntyped {
                        if let tag = TypeDef.kcDict[kc] {
                            var tv = value.tv
                            list.removeLast()
                            tv.tag = tag
                            list.append( MacroValue( tv: tv))
                            return
                        }
                    }
                }
            }
            
            list.append( MacroKey( kc: kc) )
            
            let ix = list.indices
            
            logM.debug("recordKey: \(ix)")
        }
    }
    
    mutating func recordValueFn( _ tv: TaggedValue ) {
        if recording
        {
            list.append( MacroValue( tv: tv) )
        }
    }
    
    mutating func stopRecFn( _ kc: KeyCode ) {
        if kc == kcRecording {
            kcRecording = nil
            list = []
            mode = .memoryList
            SubPadSpec.disableList.removeAll()
        }
    }
}


protocol MacroOp {
    func execute( _ model: CalculatorModel )
    
    var auxListMode: AuxListMode { get }
    
    func getText( _ model: CalculatorModel ) -> String?
    
    func getRowData( _ model: CalculatorModel ) -> RowDataItem?
}

struct MacroKey: MacroOp {
    var kc: KeyCode
    
    func execute( _ model: CalculatorModel ) {
        model.keyPress( KeyEvent( kc: kc) )
    }
    
    var auxListMode: AuxListMode { return .auxListSubSuper }
    
    func getText( _ model: CalculatorModel ) -> String? {
        if let key = Key.keyList[kc] {
            return key.text == nil ? model.getKeyText(kc) : key.text
        }
        return nil
    }
    
    func getRowData( _ model: CalculatorModel ) -> RowDataItem? { return nil }
}

struct MacroValue: MacroOp {
    var tv: TaggedValue
    
    func execute( _ model: CalculatorModel ) {
        model.state.stackLift()
        model.state.Xtv = tv
        model.state.noLift = false
    }
    
    var auxListMode: AuxListMode { return .auxListTaggedValue }

    func getText( _ model: CalculatorModel ) -> String? {
        let str = String( format: "%f", tv.reg)
        return str
    }
    
    func getRowData( _ model: CalculatorModel ) -> RowDataItem? {
        return tv.getRegisterRow()
    }
}


struct FnRec {
    var caption: String
    var macro: [MacroOp] = []
}

class CalculatorModel: ObservableObject, KeyPressHandler {
    // Current Calculator State
    @Published var state = CalcState()
    @Published var entry = EntryState()
    @Published var aux   = AuxState()
    
    var undoStack = UndoStack()

    // Display window into register stack
    @AppStorage(.settingsDisplayRows)
    private var displayRows = 3
    
    var rowCount: Int { return displayRows}
    
    // **** Macro Recording Stuff ***
    
    var fnList: [KeyCode : FnRec] = [:]
    
    func setMacroFn( _ kc: KeyCode, _ list: [MacroOp] ) {
        fnList[kc] = FnRec( caption: "Fn\(kc.rawValue % 10)", macro: list)
    }
    
    func clearMacroFn( _ kc: KeyCode) {
        fnList[kc] = nil
    }
    
    func getMacroFn( _ kc: KeyCode ) -> [MacroOp]? {
        if let fn = fnList[kc] {
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
    
    func getRow( index: Int ) -> RowDataItem {
        let stkIndex = bufferIndex(index)
        
        // Are we are in data entry mode and looking for the X reg
        if entry.entryMode && stkIndex == regX {
            return RegisterRow(
                prefix: state.stack[regX].name,
                register: entry.entryText,
                regAddon: entry.exponentEntry ? nil : "_",
                exponent: entry.exponentEntry ? entry.exponentText : nil,
                expAddon: entry.exponentEntry ? "_" : nil )
        }
        return state.stackRow(stkIndex)
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
            self.toType = TypeDef.symDict[sym, default: tagNone]
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
    
    let opTable: [KeyCode : StateOperator] = [
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
                    s1.Xtv = TaggedValue(tag, sqrt(s0.X), format: s0.Xfmt)
                    return s1
                }
                
                // Failed operation
                return nil
            },
        
        .y2x:
            CustomOp { s0 in
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
                
                if let exp = isInt(s0.X),
                   let tag = typeExponent( s0.Yt, x: exp )
                {
                    // Successful type exponentiation
                    var s1 = s0
                    s1.stackDrop()
                    s1.Xtv = TaggedValue(tag, pow(s0.Y, s0.X), format: s0.Yfmt)
                    return s1
                }
                
                // Failed operation
                return nil
            },
        
        .x2:
            CustomOp { s0 in
                if let (tag, ratio) = typeProduct(s0.Xt, s0.Xt) {
                    var s1 = s0
                    s1.Xtv = TaggedValue(tag, s0.X * s0.X, format: s0.Xfmt)
                    return s1
                }
                return nil
            },
        
        .percent:
            CustomOp { s0 in
                if s0.Xt == tagUntyped {
                    var s1 = s0
                    s1.Xtv = TaggedValue(s0.Yt, s0.X / 100.0 * s0.Y, format: s0.Yfmt)
                    return s1
                }
                return nil
            },
        
        .inv:
            CustomOp { s0 in
                if let (tag, ratio) = typeProduct(tagUntyped, s0.Xt, quotient: true) {
                    var s1 = s0
                    s1.Xtv = TaggedValue(tag, 1.0 / s0.X, format: s0.Xfmt)
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
                s1.Xtv = untypedZero
                s1.Ytv = untypedZero
                s1.Ztv = untypedZero
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

    
    func EntryModeKeypress(_ keyCode: KeyCode ) {
        if entry.exponentEntry {
            switch keyCode {
            case .key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9:
                // Append a digit to exponent
                if entry.exponentText.starts( with: "-") && entry.exponentText.count < 4 || entry.exponentText.count < 3 {
                    entry.appendExpEntry( String(keyCode.rawValue))
                }

            case .dot, .eex:
                // No op
                break
                
            case .sign:
                if entry.exponentText.starts( with: "-") {
                    entry.exponentText.removeFirst()
                }
                else {
                    entry.exponentText.insert( "-", at: entry.exponentText.startIndex )
                }

            case .back:
                if entry.exponentText.isEmpty {
                    entry.exponentEntry = false
                    entry.entryText.removeLast(3)
                }
                else {
                    entry.exponentText.removeLast()
                }
                
            default:
                // No op
                break

            }
        }
        else {
            switch keyCode {
            case .key0, .key1, .key2, .key3, .key4, .key5, .key6, .key7, .key8, .key9:
                // Append a digit
                entry.appendTextEntry( String(keyCode.rawValue))
                
            case .dot:
                entry.appendTextEntry(".")
                
            case .eex:
                entry.startExpEntry()

            case .sign:
                entry.flipTextSign()

            case .back:
                entry.backspaceEntry()
                
                if !entry.entryMode {
                    // Exited entry mode
                    // We backspace/undo out of entry mode - need to pop stack
                    // to restore state before entry mode
                    if let lastState = undoStack.pop() {
                        state = lastState
                    }
                }

            default:
                // No op
                break
            }
        }
    }
    
    func macroKeypress( _ event: KeyEvent ) {
        if let kc = event.kcTop {
            
            switch event.kc {
            case .clrFn:
                clearMacroFn(kc)
                aux.stopRecFn(kc)
                
            case .recFn:
                // Accept data entry before starting recording to avoid recording the entry
                acceptTextEntry()
                aux.startRecFn(kc)
                
            case .stopFn:
                if aux.recording && !aux.list.isEmpty {
                    setMacroFn(kc, aux.list)
                }
                aux.stopRecFn(kc)
                
            case .showFn:
                if let fn = fnList[kc] {
                    aux.list = fn.macro
                    aux.mode = .fnList
                }

            default:
                break
            }
        }
        else {
            switch event.kc {
            case .fn1, .fn2, .fn3, .fn4, .fn5, .fn6:
                if aux.recording && !aux.list.isEmpty {
                    setMacroFn(event.kc, aux.list)
                }
                aux.stopRecFn(event.kc)
                
            default:
                break
            }
        }
    }
    
    
    func keyPress(_ event: KeyEvent) {
        let keyCode = event.kc
        
        if macroOpSet.contains(keyCode) || isKeyRecording(event.kc) {
            // Macro recording control key or the Fn key currently recording
            macroKeypress(event)
            return
        }
        
        if entry.entryMode {
            // We are in data entry mode
            if entryKeys.contains(keyCode) {
                // Process data entry event
                EntryModeKeypress(keyCode)
                return
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
            return
        }
        else if keyCode == .dot {
            // Start data entry with a decimal point
            undoStack.push(state)
            state.stackLift()
            entry.startTextEntry( "0." )
            return
        }

        if keyCode != .back {
            // Record all keys except back/undo and data entry keys
            aux.recordKeyFn(keyCode)
        }
        
        switch keyCode {
        case .back:
            // Undo last operation by restoring previous state
            if let lastState = undoStack.pop() {
                state = lastState
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
                undoStack.push(state)
                
                // Don't maintain undo stack during playback ops
                undoStack.pauseStack()
                aux.pauseRecording()
                for op in macro {
                    op.execute(self)
                }
                aux.resumeRecording()
                undoStack.resumeStack()
            }

        default:
            if let op = opTable[keyCode] {
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
                }
                else {
                    // else no-op as there was no new state
                    if let lastState = undoStack.pop() {
                        state = lastState
                    }
                }
            }
            else if keyCode.isUnit {
                if let tag = TypeDef.kcDict[keyCode],
                   let _   = TypeDef.typeDict[tag]
                {
                    undoStack.push(state)
                    
                    if state.convertX( toTag: tag) {
                        state.noLift = false
                    }
                    else {
                        // else no-op as there was no new state
                        if let lastState = undoStack.pop() {
                            state = lastState
                        }
                    }
                }
            }
        }
    }
    
    
    func getKeyText( _ kc: KeyCode ) -> String? {
        if let fn = fnList[kc] {
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
}
