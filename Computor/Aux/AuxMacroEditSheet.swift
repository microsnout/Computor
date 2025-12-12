//
//  AuxMacroEditSheet.swift
//  Computor
//
//  Created by Barry Hall on 2025-11-09.
//  
import SwiftUI


struct SheetHeaderText: View {
    
    var txt: String
    
    var body: some View {
        
        RichText( "ƒ{1.2}\(txt)", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
            .padding( [.top], 10 )
    }
}


struct SheetTextField: View {
    
    var label: String
    
    var placeholder: String
    
    @Binding var text: String
    
    var body: some View {
        
        VStack( alignment: .leading, spacing: 5 ) {
            SheetHeaderText( txt: label )
            
            TextField( placeholder, text: $text )
                .textFieldStyle(.roundedBorder)
                .padding( [.top], 0)
                .foregroundColor(.black)
        }
    }
}


typealias SheetContinuationClosure = ( _ str: String ) -> Void

typealias KeyCodeContinuationClosure = ( _ kc: KeyCode ) -> Void


struct KeyAssignPopup: View, KeyPressHandler {
    
    var tag: SymbolTag
    var kccc: KeyCodeContinuationClosure
    
    @State private var kcAssigned: KeyCode = .null
    
    
    func keyPress(_ event: KeyEvent ) -> KeyPressResult {
        
        kcAssigned = event.kc
        kccc( event.kc )
        return KeyPressResult.noOp
    }
    
    var body: some View {
        
        VStack( alignment: .center ) {
            
            KeypadView( padSpec: psFnUn, keyPressHandler: self )
                .padding( [.leading, .trailing, .bottom, .top] )
        }
        .frame( maxWidth: .infinity )
        .accentColor( .black )
        .onAppear() {
            // kcAssigned = tag.kc
        }
        .background() {
            
            Color( "SuperLightGray")
                .cornerRadius(10)
                .padding( [.leading, .trailing], 20 )
                .padding( [.top], 5 )
                .padding( [.bottom], 0 )
        }
    }
}


struct MacroEditSheet: View {
    
    /// Sheet editor for maco definitions with collapsible sub views
    
    @Environment(\.dismiss) var dismiss
    
    @State var mr: MacroRec
    @State var caption: String
    
    @State var model: CalculatorModel
    
    var scc: SheetContinuationClosure
    
    @State private var symName: String = ""
    @State private var kcAssigned: KeyCode? = nil
    
    struct MacroMoveRec {
        // Information to present to confirmation dialog
        var targetMod: ModuleRec
    }
    
    @State private var moveDialog = false
    @State private var moveRec = MacroMoveRec( targetMod: ModuleRec( name: "" ) )
    
    var body: some View {
        let kcFn: KeyCode? = model.getKeyAssignment( for: mr.symTag, in: model.aux.macroMod)
        let fnText = kcFn == nil ? "" : "F\(kcFn!.rawValue % 10)"
        let modSymStr = model.aux.macroMod.name
        
        VStack( alignment: .leading ) {
            
            // DONE Button
            HStack {
                Spacer()
                
                // DONE
                Button( action: { dismiss() } ) {
                    RichText( "Done", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                }
            }
            .padding( [.top], 5 )
            
            // Symbol Editor
            SheetCollapsibleView( label: "={Symbol: }\(symName)" ) {
                
                NewSymbolPopup( tag: mr.symTag ) { newTag in
                    model.changeMacroSymbol( old: mr.symTag, new: newTag)
                    symName = newTag.getRichText()
                }
            }
            
            // Caption Editor
            SheetTextField( label: "Caption:", placeholder: "-caption-", text: $caption )
            
            // Assigned Key Editor
            SheetCollapsibleView( label: "={Assigned Key: }\(fnText)" ) {
                
                KeyAssignPopup( tag: mr.symTag ) { kc in
                    
                    // Update state variable to display key
                    kcAssigned = kc
                    
                    // If macroMod is mod0 this will not change the tag
                    let remTag = model.db.getRemoteSymbolTag( for: mr.symTag, to: model.aux.macroMod /*from mod0*/ )
                    
                    model.assignKey( kc, to: remTag )
                }
            }
            
            // Module Editor
            SheetCollapsibleView( label: "={Module: }\(modSymStr)" ) {
                
                SelectModulePopup( db: model.db ) { mod in
                    
                    // Present the mod info to dialog to display the name
                    moveRec = MacroMoveRec( targetMod: mod )
                    moveDialog = true
                }
            }
            
            Spacer()
        }
        .padding( [.leading, .trailing], 40 )
        .presentationBackground( Color.black.opacity(0.7) )
        .presentationDetents( [.fraction(0.8), .large] )
        .onAppear() {
            symName = mr.symTag.getRichText()
            kcAssigned = model.kstate.keyMap.keyAssignment(mr.symTag)
        }
        .onSubmit {
            scc( caption )
            dismiss()
        }
        
        // MOVE MACRO SHEET
        .confirmationDialog("Confirm Deletion", isPresented: $moveDialog, presenting: moveRec ) { mmr in
            
            Button("Move to Module: \(mmr.targetMod.name)") {
                
                // Move the macro and set aux display to destination mod
                model.moveMacro( mr.symTag, from: model.aux.macroMod, to: moveRec.targetMod )
                model.aux.macroMod = moveRec.targetMod
            }
            
            Button("Copy to Module: \(mmr.targetMod.name)") {
                
                // Copy the macro and leave aux display on source mod
                model.copyMacro( mr.symTag, from: model.aux.macroMod, to: moveRec.targetMod )
            }
            
            
            Button("Cancel", role: .cancel) {
                // Nothing to do
            }
        }
    }
}


// **************


struct ModuleKeyView: View {
    
    /// A view of a single module key
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    let modSym: String
    let keySpec: KeySpec
    
    var body: some View {
        
        let keyW = keySpec.width
        
        VStack {
            
            Rectangle()
                .foregroundColor( Color(keySpec.keyColor) )
                .frame( width: keyW, height: keySpec.height )
                .cornerRadius( keySpec.radius )
                .overlay(
                    RichText( modSym, size: .normal, weight: .regular, defaultColor: keySpec.textColor)
                )
        }
        .frame( width: keyW, height: keySpec.height )
    }
}


typealias ModSelectClosure = ( _ mfr: ModuleRec ) -> Void


struct SelectModulePopup: View {
    
    /// Select from list of existing symbol tags, could be memories or macros
    
    @Environment(CalculatorModel.self) var model
    @Environment(KeyData.self) var keyData
    
    let keySpec: KeySpec = ksModuleKey
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Parameters
    var db: Database
    var msc: ModSelectClosure
    
    var body: some View {
        let modRowList: [[ModuleRec]] = db.modList.chunked(into: 3)
        
        VStack( alignment: .center, spacing: 0) {
            
            ScrollView( [.vertical] ) {
                
                VStack( alignment: .center ) {
                    Grid {
                        
                        ForEach ( modRowList.indices, id: \.self ) { r in
                            let row = modRowList[r]
                            
                            GridRow {
                                let n = row.count
                                
                                ForEach ( row.indices, id: \.self ) { c in
                                    let sym = row[c].name
                                    
                                    ModuleKeyView( modSym: sym, keySpec: keySpec )
                                        .onTapGesture {
                                            hapticFeedback.impactOccurred()
                                            msc( row[c] )
                                        }
                                }
                                
                                // Pad the row to 4 col so the frame doesn't shrink
                                if n < 3 {
                                    ForEach ( 1 ... 3-n, id: \.self ) { _ in
                                        Color.clear
                                            .frame( width: keySpec.width, height: keySpec.height )
                                    }
                                }
                            }
                            .padding( .top, 5 )
                        }
                    }
                }
                .padding( 15)
            }
            .accentColor( .black )
            .background() {
                
                Color( "SuperLightGray")
                    .cornerRadius(10)
                    .padding( [.leading, .trailing], 0 )
                    .padding( [.top, .bottom], 5 )
            }
        }
        .frame( maxWidth: .infinity )
        .padding( [.leading, .trailing], 20 )
        // .frame( maxHeight: 340 )
    }
}
