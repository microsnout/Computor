//
//  Functions.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-12.
//
import Foundation


func installFunctions( _ model: CalculatorModel ) {
    
    /// ** Install Fuctions **
    
    SystemLibrary.addGroup( stdGroup )
}


// ***********************
// Library Data Structures
// ***********************

typealias LibFuncClosure = ( _ s0: CalcState ) -> (CalcState?, KeyPressResult)


struct SystemLibrary {
    
    static var groups: [LibraryGroup] = []
    
    static func addGroup( _ group: LibraryGroup ) {
        
        // Allocate system module code
        group.modCode = Self.groups.count + SymbolTag.firstSysMod
        
        Self.groups.append(group)
    }
    
    
    static func getLibFunction( for tag: SymbolTag ) -> LibraryFunction? {
        
        assert( tag.isSysMod )
        
        let index = tag.mod - SymbolTag.firstSysMod
        let localTag = tag.localTag
        return Self.groups[index].functions.first( where: { $0.sym == localTag } )
    }
}


class LibraryGroup {
    
    var name: String
    var functions: [LibraryFunction]
    
    var modCode: Int = 0
    
    init( name: String, functions: [LibraryFunction] ) {
        self.name = name
        self.functions = functions
    }
}


class LibraryFunction {
    
    var sym: SymbolTag
    var regPattern: RegisterPattern = RegisterPattern()
    var libFunc: LibFuncClosure
    
    init( sym: SymbolTag, require pattern: [RegisterSpec], where test: StateTest? = nil, _ libFunc: @escaping LibFuncClosure ) {
        
        self.sym = sym
        self.regPattern = RegisterPattern(pattern, test)
        self.libFunc = libFunc
    }
}


// **************************
// Standard Library Functions
// **************************

var stdGroup = LibraryGroup(
    name: "Std",
    functions: [
        
        LibraryFunction(
            sym: SymbolTag( [.Q, .f] ),
            require: [ .X([.real]), .Y([.real]), .Z([.real])], where: { s0 in s0.Xt == s0.Yt && s0.Yt == s0.Zt && s0.Xt == tagUntyped },
            libQuadraticFormula(_:)
        )
    ])


func libQuadraticFormula( _ s0: CalcState) -> (CalcState?, KeyPressResult) {
    
    /// Solve quadratic function
    /// 0 = ax^2 + bx + c
    /// where X=a, Y=b, Z=c
    
    let (a, b, c) = (s0.X, s0.Y, s0.Z)
    
    var s1 = s0
    s1.stackDrop()
    s1.stackDrop()
    
    let rad = b*b - 4*a*c
    
    if rad == 0.0 {
        // One solution
        s1.setRealValue( -b / 2*a, fmt: s0.Xfmt )
    }
    else if rad > 0.0 {
        // Two real solutions
        s1.setShape( cols: 2 )
        s1.stack[regX].set1( (-b + sqrt(rad))/2*a, c: 1 )
        s1.stack[regX].set1( (-b - sqrt(rad))/2*a, c: 2 )
    }
    else {
        // Return 2 complex values
        s1.stack[regX].setMatrix( .complex, cols: 2 )
        let re = -b/2*a
        let im = sqrt(-rad)/2*a
        s1.stack[regX].set2( re, im, c: 1 )
        s1.stack[regX].set2( re, -im, c: 2 )
    }
    return (s1, KeyPressResult.stateChange)
}
