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
        
        if let (mr, mfr) = db.getMacro( for: sTag, localMod: mod0) {
            
            // Test if we are deleting the macro currently being viewed in Aux dispaly
            if mfr == aux.macroMod && mr === aux.macroRec {
                aux.clearMacroState()
            }
            
            // Now delete the macro and save file
            db.deleteMacro( sTag.localTag, from: mfr)
        }
    }
    
    
    func getMacroFunction( _ sTag: SymbolTag ) -> (MacroRec, ModuleRec)? {
        
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
        
        /// Return true if kc key is currently recording
        
        if let mr = aux.macroRec {
            
            if let kcFn = kstate.keyMap.keyAssignment( mr.symTag ) {
                
                // We are recording a sym that is assigned to key kcFn
                return kcFn == kc && aux.recState.isRecording
            }
            
            // recording but no key assignment
            return false
        }
        
        // Not recording anything
        return false
    }
    
    
    func startRecordingFnKey( _ kcFn: KeyCode ) {
        
        if let sTag = kstate.keyMap.tagAssignment(kcFn) {
            
            // sTag is assigned to key kcFn
            
            let mod0 = db.getModZero()
            
            if let (mr, mfr) = db.getMacro(for: sTag, localMod: mod0) {
                
                // Found a macro rec for sTag in mfr
                aux.record(mr, in: mfr)
            }
            else {
                // A tag assigned to this key but no macro rec - should not happen
                assert(false)
            }
        }
        else {
            // No tag assigned - must be a blank Fn key - find matching tag
            if let sTag = SymbolTag.getFnSym(kcFn) {
                
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
            else {
                // Recording kc key with no possible tag
                assert(false)
            }
        }
    }
    
    
    func clearRecordingFnKey( _ kcFn: KeyCode ) {
        
        // Lookup macro assigned to this key
        if let tag = kstate.keyMap.tagAssignment(kcFn) {
            
            guard let fnTag = SymbolTag.getFnSym(kcFn) else {
                // There must be a tag representing this kc because we only get here by pressing F1..F6
                assert(false)
            }
            
            if tag == fnTag {
                
                // Macro assigned to this key has symbol matching key
                // Clear assignment and delete macro
                kstate.keyMap.clearKeyAssignment(kcFn)
                clearMacroFunction(tag)
            }
            
            // Macro is assigned to a custom symbol
            // Remove the key mapping for this key
            // Macro will still exist
            kstate.keyMap.clearKeyAssignment(kcFn)
        }
    }
    
    
    func createNewMacro() {
        
        /// ** Create New Macro **
        ///     Called from MacroListView 'plus' button
        
        // A blank macro record
        let mr = MacroRec()
        
        // Bind to null symbol for now - replacing any currently bound
        db.addMacro( mr, to: aux.macroMod )
        
        // Load into recorder
        aux.loadMacro(mr)
    }
    
    
    func setMacroCaption( _ caption: String, for tag: SymbolTag ) {
        
        aux.macroMod.setMacroCaption(tag, caption)
    }
    
    
    func changeMacroSymbol( old: SymbolTag, new: SymbolTag ) {
        
        // Called from macro detail view - so sym is local to macroMod
        
        // Find remote tag from mod0
        let remTag = db.getRemoteSymbolTag( for: old, to: aux.macroMod )

        if let kc = kstate.keyMap.keyAssignment(remTag) {
            
            // Update key assignment to new remote tag
            let newRemTag = SymbolTag( new, mod: remTag.mod )
            kstate.keyMap.assign(kc, tag: newRemTag)
        }
        
        // Change local tag to new local tag within current recording mod
        aux.macroMod.changeMacroTag(from: old, to: new)
        
        // Above call saves module but cannot save Index
        db.modTable.saveTable()
    }
    
    
    func assignKeyTo( _ kc: KeyCode, tag: SymbolTag ) {
        
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
    }
    
    
    func getKeyAssignment( for tag: SymbolTag, in mfc: ModuleRec ) -> KeyCode? {
        
        /// ** Get Key Assignment **
        ///     tag is a local symbol in mfc
        
        if mfc.isModZero {
            // Search for key with local sym tag
            return kstate.keyMap.keyAssignment(tag)
        }
        
        // Create a remote tag for symbols in mfc as seen from mod0
        let remTag = db.getRemoteSymbolTag( for: tag, to: mfc )
        return kstate.keyMap.keyAssignment(remTag)
    }
    
    
    func playMacroSeq( _ seq: MacroOpSeq, in mod: ModuleRec ) -> KeyPressResult {
        
        acceptTextEntry()
        
        // Macro playback - save inital state just in case
        pushState()
        
        pushContext( PlaybackContext() )
        
        // Push a new local variable store
        currentLVF = LocalVariableFrame( currentLVF )
        
        // Don't maintain undo stack during playback ops
        pauseUndoStack()
        
        // Create new module execution context for resolving macro references
        pushMEC(mod)
        
        for op in seq {
            
            if op.execute(self) == KeyPressResult.stateError {
                popMEC()
                resumeUndoStack()
                currentLVF = currentLVF?.prevLVF
                popContext()
                popState()
                
                logM.debug( "playMacroSeq: ERROR \(String( describing: op.getRichText(self) ))")
                return KeyPressResult.stateError
            }
        }
        
        popMEC()
        resumeUndoStack()
        
        // Pop the local variable storage, restoring prev
        currentLVF = currentLVF?.prevLVF
        
        popContext( KeyEvent(.macroPlay) )
        
        return KeyPressResult.stateChange
    }
    
    
    func moveMacro( _ mTag: SymbolTag, from srcMod: ModuleRec, to dstMod: ModuleRec ) {
        
        /// ** Move Macro **
        ///     Move key assignment as well
        
        if let mr = srcMod.getMacro(mTag) {
            
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
        
        if let mr = srcMod.getMacro(mTag) {
            
            // Move this symbol to new module
            db.copyMacro( mr, from: srcMod, to: dstMod )
        }
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
            mr.opSeq.append( MacroEvent( event ) )
            
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
            mr.opSeq.append( MacroEvent( event ) )
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
    

    
}
