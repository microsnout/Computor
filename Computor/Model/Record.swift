//
//  Record.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-19.
//
import SwiftUI


extension CalculatorModel {
    
    /// ** Macro Recording Stuff **
    
    func saveMacroFunction( _ sTag: SymbolTag, _ list: MacroOpSeq ) {
        let mr = MacroRec( tag: sTag, seq: list)
        aux.macroMod.addMacro(mr)
        saveConfiguration()
    }
    
    
    func clearMacroFunction( _ sTag: SymbolTag) {
        
        // Delete macro bound to sTag and save config
        
        // Test if we are deleting the macro currently being viewed in Aux dispaly
        if let mr = aux.macroMod.getMacro(sTag) {
            if mr === aux.macroRec {
                // Yes, clear Aux display state
                aux.clearMacroState()
            }
        }
        
        // Now delete the macro and save file
        aux.macroMod.deleteMacro(sTag)
        saveConfiguration()
    }
    
    
    func getMacroFunction( _ sTag: SymbolTag ) -> MacroOpSeq? {
        if let mr = aux.macroMod.getMacro(sTag) {
            return mr.opSeq
        }
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
            
            // TODO: Should eventually find a mr from any module not just current
            if let mr = aux.macroMod.getMacro(sTag) {
                
                aux.record(mr)
            }
            else {
                // A tag assigned to this key but no macro rec - should not happen
                assert(false)
            }
        }
        else {
            // No tag assigned - must be a blank Fn key - find matching tag
            if let sTag = SymbolTag.getFnSym(kcFn) {
                
                kstate.keyMap.assign( kcFn, tag: sTag )
                let mr = MacroRec( tag: sTag )
                aux.macroMod.addMacro(mr)
                aux.record(mr)
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
                
                // Macro assigned to this key has symbol matching key - delete it
                clearMacroFunction(tag)
            }
            
            // Remove the key mapping for this key
            kstate.keyMap.clearKeyAssignment(kcFn)
        }
    }
    
    
    /// ** NOT USED **
    ///
    func record( _ tag: SymbolTag = SymbolTag(.null) ) {
        
        if let mr = aux.macroMod.getMacro(tag) {
            
            // Start recording symbol tag - which could be null
            aux.record(mr)
        }
        else if tag == SymbolTag(.null) {
            
            // Null tag was not found - create the null rec
            let mr = MacroRec()
            aux.macroMod.addMacro(mr)
            aux.record(mr)
        }
        else {
            // A non null tag with no record
            assert(false)
        }
    }
    
    
    func createNewMacro() {
        
        /// Called from MacroListView 'plus' button
        
        // A blank macro record
        let mr = MacroRec()
        
        // Bind to null symbol for now - replacing any currently bound
        aux.macroMod.addMacro(mr )
        
        // Load into recorder
        aux.loadMacro(mr)
    }
    
    
    func setMacroCaption( _ caption: String, for tag: SymbolTag ) {
        
        aux.macroMod.setMacroCaption(tag, caption)
    }
    
    
    func changeMacroSymbol( old: SymbolTag, new: SymbolTag ) {
        
        if let kc = kstate.keyMap.keyAssignment(old) {
            
            // Update key assignment
            kstate.keyMap.assign(kc, tag: new)
        }
        
        aux.macroMod.changeMacroTag(from: old, to: new)
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
    
    
    func playMacroSeq( _ seq: MacroOpSeq ) -> KeyPressResult {
        
        acceptTextEntry()
        
        // Macro playback - save inital state just in case
        pushState()
        
        pushContext( PlaybackContext() )
        
        // Push a new local variable store
        currentLVF = LocalVariableFrame( currentLVF )
        
        // Don't maintain undo stack during playback ops
        pauseUndoStack()
        
        for op in seq {
            
            if op.execute(self) == KeyPressResult.stateError {
                resumeUndoStack()
                currentLVF = currentLVF?.prevLVF
                popContext()
                popState()
                
                logM.debug( "playMacroSeq: ERROR \(String( describing: op.getRichText(self) ))")
                return KeyPressResult.stateError
            }
        }
        resumeUndoStack()
        
        // Pop the local variable storage, restoring prev
        currentLVF = currentLVF?.prevLVF
        
        popContext( KeyEvent(.macroPlay) )
        
        return KeyPressResult.stateChange
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
