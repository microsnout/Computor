//
//  Record.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-19.
//
import SwiftUI


extension CalculatorModel {
    
    /// ** Macro Recording Stuff **
    
    func clearMacroFunction( _ sTag: SymbolTag) {
        
        // Delete macro bound to sTag and save config
        
        let mod0 = db.getModZero()
        
        if let (mr, mod) = db.getMacro( for: sTag, localMod: mod0) {
            
            // Test if we are deleting the macro currently being viewed in Aux dispaly
            if mod == aux.macroMod && mr === aux.macroRec {
                aux.deactivateMacroRecorder()
            }
            
            // Now delete the macro and save file
            db.deleteMacro( sTag.localTag, from: mod)
        }
    }
    
    
    func getMacroFunction( _ sTag: SymbolTag ) -> (MacroRec, ModuleRec)? {
        
        /// ** Get Macro Function **
        
        // Get current module to resolve macro references
        let modCtx = currentMEC?.module ?? db.getModZero()
        
        if let (mr, mfr) = db.getMacro( for: sTag, localMod: modCtx ) {
            
            // Found macro rec mr in Module file mfr
            return (mr, mfr)
        }
        
        // No macro found
        return nil
    }
    
    
    func isRecordingKey( _ kc: KeyCode ) -> Bool {
        
        /// ** Is Recording Key **
        /// Return true if kc key is currently recording
        
        if let mr = aux.macroRec,
           let kcFn = kstate.keyMap.keyAssignment( mr.symTag ) {

            // We are recording a sym that is assigned to key kcFn
            return kcFn == kc && aux.recState.isRecording
        }

        // Not recording anything
        return false
    }
    
    
    func startRecordingFnKey( _ kcFn: KeyCode ) {
        
        /// ** Start Recording Fn Key **
        
        if let _ = kstate.keyMap.tagAssignment(kcFn) {
            
            // A tag assigned to this key - should not happen
            assert(false)
            return
        }
        
        // No tag assigned - must be a blank Fn key - find matching tag
        guard let sTag = SymbolTag.getKeyCodeSym(kcFn) else {
            
            // Recording kc key with no possible tag
            assert(false)
            return
        }
        
        // Reset macro recorder before reloading
        aux.deactivateMacroRecorder()
            
        // Macro will be in this module
        let recMod = aux.macroMod
        
        // Make a remote version of Fn tag if macroMod is not mod0
        let recTag = db.getRemoteSymbolTag(for: sTag, to: recMod)
        
        // Add to key map
        kstate.keyMap.assign( kcFn, tag: recTag )
        
        // Create macro rec with local tag
        let mr = MacroRec( tag: sTag )
        
        // Add macro rec to the remote module
        db.addMacro( mr, to: recMod )
        
        // Start recording
        aux.record(mr, in: recMod)
    }
    
    
    func clearRecordingFnKey( _ kcFn: KeyCode ) {
        
        /// ** Clear Recording Fn Key **
        
        // Lookup macro assigned to this key
        if let tag = kstate.keyMap.tagAssignment(kcFn) {
            
            guard let fnTag = SymbolTag.getKeyCodeSym(kcFn) else {
                // There must be a tag representing this kc because we only get here by pressing F1..F6
                assert(false)
                return
            }
            
            if tag == fnTag {
                
                // Macro assigned to this key has symbol matching key
                // Delete the macro because it only works on this key
                clearMacroFunction(tag)
            }
            
            // Remove the key mapping for this key
            // Macro will still exist unless it was deleted above
            kstate.keyMap.clearKeyAssignment(kcFn)
        }
    }
    
    
    func createNewMacro() {
        
        /// ** Create New Macro **
        ///     Called from MacroListView 'plus' button
        
        // A blank macro record
        let mr = MacroRec()
        
        // Bind to blank symbol for now - replacing any currently bound
        db.addMacro( mr, to: aux.macroMod )
        
        // Load into recorder
        aux.loadMacro(mr)
        
        hapticFeedback.impactOccurred()
    }
    
    
    func changeMacroSymbol( old: SymbolTag, new: SymbolTag ) {
        
        /// ** Change Macro Symbol **
        
        print( "model.changeMacroSymbol oldTag=\(old.getRichText())  newTag=\(new.getRichText())" )
        
        // Called from macro detail view - so sym is local to macroMod
        
        // Find remote tag from mod0
        let remTag = db.getRemoteSymbolTag( for: old, to: aux.macroMod /* from mod0 */ )

        if let kc = kstate.keyMap.keyAssignment(remTag) {
            
            // Update key assignment to new remote tag
            let newRemTag = SymbolTag( new, mod: remTag.mod )
            kstate.keyMap.assign(kc, tag: newRemTag)
        }
        
        // Change local tag to new local tag within current recording mod
        db.changeMacroTag(from: old, to: new, in: aux.macroMod)
        
        // If we are changing the tag of the current aux edit/rec macro, update it
        if old == aux.macroTag {
            aux.macroTag = new
        }
    }
    
    
    func changeMacroCaption( to newCap: String, for mTag: SymbolTag, in mod: ModuleRec ) {
        
        // Find this sym in the given module
        if let mr = mod.getLocalMacro(mTag) {
            
            // Update the caption
            mr.caption = newCap
            mod.saveModule()
        }
    }
    
    
    func assignKey( _ kc: KeyCode, to tag: SymbolTag ) {
        
        /// ** Assign Key **
        
        if let oldKey = kstate.keyMap.keyAssignment(tag) {
            
            // This tag is already assinged to a key
            // Clear that assignment
            kstate.keyMap.clearKeyAssignment(oldKey)
        }
        
        if let oldTag = kstate.keyMap.tagAssignment(kc) {
            
            if tag != oldTag {
                
                // Existing assignment for this key
                // Overwrite with new tag
                kstate.keyMap.assign(kc, tag: tag )
            }
        }
        else {
            // New assignment
            kstate.keyMap.assign(kc, tag: tag )
        }
        
        // Save now - don't wait for app losing focus
        changed()
        saveDocument()
    }
    
    
    func getKeyAssignment( for tag: SymbolTag, in mod: ModuleRec ) -> KeyCode? {
        
        /// ** Get Key Assignment **
        ///     tag is a local symbol in mfc
        
        if mod.isModZero {
            // Search for key with local sym tag
            return kstate.keyMap.keyAssignment(tag)
        }
        
        // Create a remote tag for symbols in mfc as seen from mod0
        let remTag = db.getRemoteSymbolTag( for: tag, to: mod )
        return kstate.keyMap.keyAssignment(remTag)
    }
    
    // func playMacroSeq<OpC: Collection>( _ seq: OpC, in mod: ModuleRec ) -> (KeyPressResult, Int ) where OpC.Element == MacroOp {

    func playMacroSeq( _ seq: ArraySlice<MacroOp>, in mod: ModuleRec ) -> (KeyPressResult, Int ) {

        /// ** Play Macro Seq **
        /// Returns number of Op macros successfully executed
        
        acceptTextEntry()
        
        // Preserve state to undo entire sequence if needed
        pushState()
        
        // Create new Playback context containing the seq
        let playCtx = PlaybackContext(seq)

        // Macro playback
        pushContext( playCtx )
        
        // Push a new local variable store
        pushLocalVariableFrame()
        
        // Don't maintain undo stack during playback ops
        pauseUndoStack()
        
        // Create new module execution context for resolving macro references
        pushMEC(mod)
        
        let (result, index) = playCtx.executeSequence()
        
        if result == KeyPressResult.stateError {
            popMEC()
            resumeUndoStack()
            popLocalVariableFrame()
            popContext()
            popState()
            
            logM.debug( "playMacroSeq: ERROR \(index )")
            return (KeyPressResult.stateError, index)
        }
        
        popMEC()
        resumeUndoStack()
        
        // Pop the local variable storage, restoring prev
        popLocalVariableFrame()
        
        popContext( KeyEvent(.macroPlay) )
        
        return (KeyPressResult.stateChange, index)
    }
    
    
    func playSingleOp( _ op: MacroOp, in mod: ModuleRec, with lvf: LocalVariableFrame ) -> KeyPressResult {
        
        pushContext( PlaybackContext([op]) )
        pushLocalVariableFrame( aux.auxLVF )
        
        let kpr = op.execute(self)

        popLocalVariableFrame()
        popContext( KeyEvent(.macroPlay) )
        return kpr
    }
    
    
    func moveMacro( _ mTag: SymbolTag, from srcMod: ModuleRec, to dstMod: ModuleRec ) {
        
        /// ** Move Macro **
        ///     Move key assignment as well
        
        if let mr = srcMod.getLocalMacro(mTag) {
            
            // Move this symbol to new module
            db.moveMacro( mr, from: srcMod, to: dstMod )
            
            // Current remote tag to source mod
            let remTag = db.getRemoteSymbolTag( for: mTag, to: srcMod)
            
            // Look for a key assignment
            if let kc = kstate.keyMap.keyAssignment(remTag) {
                
                kstate.keyMap.clearKeyAssignment(kc)
                
                // Create new tag to destination mod
                let newTag = db.getRemoteSymbolTag( for: mTag, to: dstMod)
                
                kstate.keyMap.assign(kc, tag: newTag)
            }
        }
    }

    
    func copyMacro( _ mTag: SymbolTag, from srcMod: ModuleRec, to dstMod: ModuleRec ) {
        
        /// ** Copy Macro **
        ///     Leave key assignment alone if there is one
        
        if let mr = srcMod.getLocalMacro(mTag) {
            
            // Move this symbol to new module
            db.copyMacro( mr, from: srcMod, to: dstMod )
        }
    }

    // *** *** ***
    
    func pauseRecording() {
        
        /// ** Pause Recording **
        
        pauseRecCount += 1
    }
    
    func resumeRecording() {
        
        /// ** Resume Recording **
        
        pauseRecCount -= 1
    }
    
    
    func markMacroIndex() -> Int {
        
        /// ** Mark Macro Index **
        
        guard let mr = aux.macroRec else {
            assert(false)
            return 0
        }
        
        // The index of the next element to be added will be...
        return mr.opSeq.count
    }
    
    
    func recordKeyEvent( _ event: KeyEvent ) {
        
        /// ** Record Key Event **
        
        if pauseRecCount > 0 {
            logAux.debug( "recordKeyFn: Paused" )
            return
        }
        
        if !aux.isRec
        {
            logAux.debug( "recordKeyFn: Not Recording" )
            return
        }
        
        // TODO: Delete this var soon...
        guard let mr = aux.macroRec else {
            // No macro record despite isRec is true
            assert(false)
            return
        }
        
        guard let mrSeq = aux.macroRec else {
            // No way to record key event
            assert(false)
            return
        }
        
        switch event.kc {
            
        case .enter:
            if aux.opCursor > 0 && aux.opCursor <= mr.opSeq.count {
                
                let op = mr.opSeq[aux.opCursor-1]
                
                if let value = op as? MacroValue
                {
                    if value.tv.tag == tagUntyped {
                        
                        // An enter is not needed in recording if preceeded by an untyped value
                        break
                    }
                }
            }
            // Otherwise record the key
            mr.opSeq.insert( MacroEvent( event ), at: aux.opCursor )
            aux.opCursor += 1

        case .backUndo:
            // Backspace, need to remove last op or possibly undo a unit tag
            if aux.opCursor > 0 && aux.opCursor <= mr.opSeq.count {
                
                let op = mr.opSeq[aux.opCursor-1]
            
                if let value = op as? MacroValue
                {
                    // Last op is a value op
                    if value.tv.tag == tagUntyped {
                        
                        // No unit tag, just remove the value
                        _ = mr.opSeq.remove( at: aux.opCursor-1 )
                        aux.opCursor -= 1
                    }
                    else {
                        // A tagged value, remove the tag
                        _ = mr.opSeq.remove( at: aux.opCursor-1 )
                        var tv = value.tv
                        tv.tag = tagUntyped
                        mr.opSeq.insert( MacroValue(tv: tv), at: aux.opCursor-1 )
                    }
                }
                else {
                    // Last op id just a key op
                    _ = mr.opSeq.remove( at: aux.opCursor-1 )
                    aux.opCursor -= 1
                }
            }
            
        case let kc where kc.isUnit:
            if aux.opCursor > 0 && aux.opCursor <= mr.opSeq.count {
                
                let op = mr.opSeq[aux.opCursor-1]
                
                if let value = op as? MacroValue
                {
                    if value.tv.tag == tagUntyped {
                        
                        // Last macro op is an untyped value
                        if let tag = TypeDef.tagFromKeyCode(kc) {
                            
                            var tv = value.tv
                            _ = mr.opSeq.remove( at: aux.opCursor-1 )
                            aux.opCursor -= 1
                            tv.tag = tag
                            mr.opSeq.insert( MacroValue(tv: tv), at: aux.opCursor )
                            aux.opCursor += 1
                            break
                        }
                    }
                }
            }
            mr.opSeq.insert( MacroEvent( event ), at: aux.opCursor )
            aux.opCursor += 1
            
        default:
            if event.kc.isFuncKey {
                
                if let tag = kstate.keyMap.tagAssignment(event.kc) {
                    
                    // There is a macro assigned to this key, record the macro tag not the key code
                    mr.opSeq.insert( MacroEvent( KeyEvent( .lib, mTag: tag ) ), at: aux.opCursor )
                    aux.opCursor += 1
                    break
                }
            }
            
            // Not an Fn Key or an Fn key with no macro assignment
            mr.opSeq.insert( MacroEvent( event ), at: aux.opCursor )
            aux.opCursor += 1
        }
        
        // Log debug output
        let auxTxt = aux.getDebugText()
        logAux.debug( "recordKeyFn: \(auxTxt)" )
    }
    
    
    func recordValueEvent( _ tv: TaggedValue ) {
        
        /// ** Record Value Event **
        
        if aux.isRec
        {
            guard let mr = aux.macroRec else {
                // No macro record despite isRec is true
                assert(false)
                return
            }
            
            mr.opSeq.insert( MacroValue( tv: tv), at: aux.opCursor )
            aux.opCursor += 1

            // Log debug output
            let auxTxt = aux.getDebugText()
            logAux.debug( "recordValueFn: \(auxTxt)" )
        }
    }
    
    
    // *******************************
    // Macro Recorder Button Functions
    // ***
    
    func macroRecord( execute: Bool ) {
        
        switch aux.recState {
            
        case .record:
            break
            
        default:
            // Switch to recording context
            pushContext( RecordingContext( exeflag: execute ), lastEvent: KeyEvent(.macroRecord) )
            hapticFeedback.impactOccurred()
        }
    }
    
    
    func macroPlay() {
        
        /// ** Play Macro **
        /// Run the macro currently loaded in recorder
        
        if let mr = aux.macroRec {
            
            let (kpr, count) = playMacroSeq( mr.opSeq.seq, in: aux.macroMod )
            
            if kpr == .stateError {
                
                let opSeq = mr.opSeq
                
                aux.startDebug()
                
                if let lvf = aux.auxLVF {
                    
                    for x in 0 ..< count {
                        let op = opSeq[x]
                        let kpr = playSingleOp(op, in: aux.macroMod, with: lvf)
                        
                        if kpr == .stateError {
                            break
                        }
                    }
                    
                    aux.setError( at: count )
                }
            }
        }
        hapticFeedback.impactOccurred()
    }

    
    func macroPlay( _ mr: MacroRec ) {
        
        /// ** Play Macro **
        /// Run the macro currently loaded in recorder
        
        let (kpr, count) = playMacroSeq( mr.opSeq.seq, in: aux.macroMod )
        
        if kpr == .stateError {
            
            let opSeq = mr.opSeq
            
            aux.loadMacro(mr)
            aux.startDebug()
            
            if let lvf = aux.auxLVF {
                
                for x in 0 ..< count {
                    let op = opSeq[x]
                    let kpr = playSingleOp(op, in: aux.macroMod, with: lvf)
                    
                    if kpr == .stateError {
                        break
                    }
                }
                
                aux.setError( at: count )
            }
        }
        hapticFeedback.impactOccurred()
    }
    
    
    func macroStop() {
        
        if aux.recState.isRecording {
            // Restore normal context only if we are in recording context - not Debug state
            _ = keyPress( KeyEvent(.macroStop) )
            
            refreshAllComputedMemories()
        }
        
        // Save current state of macro
        aux.macroMod.saveModule()

        // Stop recorder
        aux.recordStop()
        aux.resetMacroCursor()
        hapticFeedback.impactOccurred()
    }

    
    func macroStep() {
        
        aux.startDebug()
        
        if let mr = aux.macroRec,
           let lvf = aux.auxLVF {
            
            let opSeq = mr.opSeq
            let x = aux.opCursor
            
            if x < opSeq.count {
                
                let op = opSeq[x]
                let kpr = playSingleOp(op, in: aux.macroMod, with: lvf)
                
                if kpr == .stateError {
                    aux.setError(at: x)
                }
                else {
                    aux.opCursor += 1
                }
                hapticFeedback.impactOccurred()
            }
        }
    }
    
    
    func macroRecExecute( _ enable: Bool ) {
        
        if let ctx = eventContext as? RecordingContext {
            
            ctx.exeflag = enable
            hapticFeedback.impactOccurred()
        }
    }
    
    
    func macroBack() {
        
        let x = aux.opCursor
        
        if x > 0 {
            popState()
            aux.opCursor -= 1
            aux.clearError()
            hapticFeedback.impactOccurred()
        }
    }
    
    
    func macroTapLine( _ n: Int ) {
        
        switch aux.recState {
            
        case .stop:
            aux.startDebug( at: n )

        case .record:
            aux.opCursor = n
            
        case .debug:
            aux.opCursor = n

        default:
            break
        }
    }
    
    
    func switchDebugToRecord( _ evt: KeyEvent ) {
        
        assert( aux.recState == .debug )
        assert( eventContext is DebugContext  )
        
        popContext(evt, runCCC: false)
        pushContext( RecordingContext( exeflag: true ), lastEvent: evt )
    }

    
    func switchRecordToDebug( _ evt: KeyEvent ) {
        
        assert( aux.recState.isRecording )
        assert( eventContext is RecordingContext )
        
        popContext(evt, runCCC: false)
        pushContext( DebugContext(), lastEvent: evt )
    }
    
    
    func deleteMacro( _ tag: SymbolTag, from mod: ModuleRec ) {
        
        
        db.deleteMacro( tag, from: mod )
        
        // Clear a key assignment for this macro if any
        if let kcFn = kstate.keyMap.keyAssignment( tag ) {
            
            kstate.keyMap.clearKeyAssignment(kcFn)
        }
        
        // Delete a matching computed memory if any
        let cmTag = SymbolTag( tag, mod: SymbolTag.computedMemMod )
        
        if let _ = getMemory(cmTag) {
            
            state.deleteMemoryRecords( tags: [cmTag])
        }
    }
}
