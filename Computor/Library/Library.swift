//
//  Functions.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-12.
//
import Foundation


func installFunctions() {
    
    /// ** Install Fuctions **
    
    SystemLibrary.addGroup( flowGroup )
    SystemLibrary.addGroup( stdGroup )
    SystemLibrary.addGroup( rootGroup )
    SystemLibrary.addGroup( integralGroup )
}


// ***********************
// Library Data Structures
// ***********************


typealias OpResult = (_: KeyPressResult, _: CalcState?)

typealias LibFuncClosure = ( _ model: CalculatorModel ) -> OpResult


protocol TaggedItem {
    var symTag: SymbolTag { get }
    var caption: String? { get }
}


protocol TaggedItemGroup {
    var name: String { get }
    var itemList: [any TaggedItem] { get }
}


struct SystemLibrary {
    
    static var groups: [LibraryGroup] = []
    
    static func addGroup( _ group: LibraryGroup ) {
        
        // Allocate system module code
        Self.groups.append(group)
    }
    
    
    static func getLibFunction( for tag: SymbolTag ) -> LibraryFunction? {
        
        assert( tag.isSysMod )
        
        for grp in Self.groups {
            
            for fn in grp.functions {
                
                if tag == fn.symTag {
                    return fn
                }
            }
        }
        return nil
    }
    
    
    static func getSystemGroup( for tag: SymbolTag ) -> LibraryGroup? {
        
        assert( tag.isSysMod )
        
        for grp in Self.groups {
            
            for fn in grp.functions {
                
                if tag == fn.symTag {
                    return grp
                }
            }
        }
        return nil
    }
}


class LibraryGroup: TaggedItemGroup {
    
    var name: String
    var functions: [LibraryFunction]
    
    var itemList: [any TaggedItem] { self.functions }
    
    init( name: String, functions: [LibraryFunction] ) {
        self.name = name
        self.functions = functions
    }
}


class LibraryFunction: TaggedItem {
    
    var symTag: SymbolTag
    var caption: String? = nil
    var regPattern: RegisterPattern = RegisterPattern()
    var nModalParm: Int = 0
    var libFunc: LibFuncClosure
    
    init( sym localSym: SymbolTag, caption: String,  require pattern: [RegisterSpec], where test: StateTest? = nil, modals: Int = 0, _ libFunc: @escaping LibFuncClosure ) {
        
        self.symTag = SymbolTag( localSym, mod: Const.LibMod.stdlib )
        self.caption = caption
        self.regPattern = RegisterPattern(pattern, test)
        self.nModalParm = modals
        self.libFunc = libFunc
    }
}


typealias FunctionX = ( _ x: Double ) -> Double
typealias Procedure = () -> Double


class LibraryFunctionContext : ModalContext {
    
    var prompt: String
    var regLabels: [String]?
    
    var block: ( _ model: CalculatorModel, _ f: FunctionX ) -> OpResult
    
    init( prompt: String, regLabels labels: [String]? = nil, block: @escaping ( _ model: CalculatorModel, _ f: FunctionX ) -> OpResult ) {
        self.prompt = prompt
        self.regLabels = labels
        self.block = block
    }
    
    override var statusString: String? { self.prompt }
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        let f: FunctionX = { x in
            
            let tvX = TaggedValue( reg: x )
            model.enterValue(tvX)
            let _ = self.executeFn(event)
            let value = model.state.X
            model.state.stackDrop()
            return value
        }
        
        let (opRes, opState) = self.block(model, f)
        
        if let newState = opState {
            model.state = newState
        }
        return opRes
    }
    
    override func onModelSet() {
        
        super.onModelSet()
        
        guard let model = self.model else { assert(false); return }
        
        if let labels = regLabels {
            model.status.setRegisterLabels(labels)
        }
    }
    
    override func onDeactivate( lastEvent: KeyEvent ) {
        
        super.onDeactivate(lastEvent: lastEvent)
        
        guard let model = self.model else { assert(false); return }
        
        model.status.clearRegisterLabels()
    }
}


class LibraryProcedureContext : ModalContext {
    
    var prompt: String
    var regLabels: [String]?
    
    var block: ( _ model: CalculatorModel, _ proc: Procedure ) -> OpResult
    
    init( prompt: String, regLabels labels: [String]? = nil, block: @escaping ( _ model: CalculatorModel, _ proc: Procedure ) -> OpResult ) {
        self.prompt = prompt
        self.regLabels = labels
        self.block = block
    }
    
    override var statusString: String? { self.prompt }
    
    override func modalExecute(_ event: KeyEvent ) -> KeyPressResult {
        
        guard let model = self.model else { return KeyPressResult.null }
        
        let p: Procedure = {
            let _ = self.executeFn(event)
            let value = model.state.X
            return value
        }
        
        let (opRes, opState) = self.block(model, p)
        
        if let newState = opState {
            model.state = newState
        }
        return opRes
    }

    override func onModelSet() {
        
        super.onModelSet()
        
        guard let model = self.model else { assert(false); return }
        
        if let labels = regLabels {
            model.status.setRegisterLabels(labels)
        }
    }
    
    override func onDeactivate( lastEvent: KeyEvent ) {
        
        super.onDeactivate(lastEvent: lastEvent)
        
        guard let model = self.model else { assert(false); return }
        
        model.status.clearRegisterLabels()
    }
}


extension CalculatorModel {
    
    func withModalFunc( prompt: String, regLabels labels: [String]? = nil, block: @escaping (_ model: CalculatorModel, _ f: FunctionX) -> OpResult )-> OpResult {
        
        /// ** With Modal Func **
        /// Delays execution of 'block' until the user enters a function, either single key or a {..} block
        /// Passes the entred function to the block
        
        let ctx = LibraryFunctionContext( prompt: prompt, regLabels: labels, block: block )
        
        self.pushContext(ctx)
        
        return (KeyPressResult.modalFunction, nil)
    }

    func withModalProc( prompt: String, regLabels labels: [String]? = nil, block: @escaping (_ model: CalculatorModel, _ p: Procedure) -> OpResult )-> OpResult {
        
        /// ** With Modal Func **
        /// Delays execution of 'block' until the user enters a function, either single key or a {..} block
        /// Passes the entred function to the block
        
        let ctx = LibraryProcedureContext( prompt: prompt, regLabels: labels, block: block )
        
        self.pushContext(ctx)
        
        return (KeyPressResult.modalFunction, nil)
    }
    
    
    func withModalConfirmation( prompt: String, regLabels labels: [String]? = nil, block: @escaping (_ model: CalculatorModel ) -> OpResult ) -> OpResult {
        
        /// ** With Modal Confirmation **
        /// Delays execution of the function block until confirmed by pressing Enter
        /// Does Nothing (no delay) if currently in recording or playback context
       
        let withinNormalContext: Bool = self.eventContext is NormalContext
        
        if self.modalConfirmation &&  withinNormalContext {
            
            // Return confirmation context to handle Enter to confirm execution
            let ctx = ModalConfirmationContext( prompt: prompt, regLabels: labels, block: block )
            self.pushContext(ctx)
            return (KeyPressResult.modalFunction, nil)
        }
        else {
            // Execute block immediately if recording or playback
            return block( self )
        }

    }
}


