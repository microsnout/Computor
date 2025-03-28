//
//  ComputorTests.swift
//  ComputorTests
//
//  Created by Barry Hall on 2024-10-22.
//

import Testing
@testable import Computor

struct ComputorTests {

    @Suite("Basic") struct basicSuite {
        
        
        @Test("Basic Stack Ops") func testStackOps() async throws {
            
            let model = CalculatorModel()
            _ = model.keyPress( KeyEvent( kc: .key5 ))
            _ = model.keyPress( KeyEvent( kc: .enter ))
            
            #expect( model.state.X == 5.0 )
        }
        
        @Test("Basic Stack Ops 2") func testTwo() async throws {
            
            let model = CalculatorModel()
            _ = model.keyPress( KeyEvent( kc: .key3 ))
            _ = model.keyPress( KeyEvent( kc: .plus ))
            
            #expect( model.state.X == 3.0 )
        }
    }

}
