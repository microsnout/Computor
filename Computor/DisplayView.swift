//
//  DisplayView.swift
//  MoneyCalc
//
//  Created by Barry Hall on 2021-10-28.
//
import Combine
import SwiftUI

class ObservableArray<T>: ObservableObject {

    @Published var array:[T] = []
    var cancellables = [AnyCancellable]()

    init(array: [T]) {
        self.array = array

    }

    func observeChildrenChanges<K>(_ type:K.Type) throws ->ObservableArray<T> where K : ObservableObject{
        let array2 = array as! [K]
        array2.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { _ in self.objectWillChange.send() })

            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.cancellables.append(c)
        })
        return self
    }

}

typealias TextSizeSpec = ( body: Double, subscript: Double )

enum TextSize {
    case small, normal, large
}

let textSpecTable: [TextSize: TextSizeSpec] = [
    .small  : ( 12.0,  8.0 ),
    .normal : ( 14.0, 10.0 ),
    .large  : ( 16.0, 12.0 )
]

protocol RowDataItem {
    var prefix:   String? { get }
    var register: String  { get }
    var regAddon: String? { get }
    var exponent: String? { get }
    var expAddon: String? { get }
    var suffix:   String? { get }
}

struct NoPrefix: RowDataItem {
    let prefix: String? = nil
    let register: String
    let regAddon: String?
    let exponent: String?
    let expAddon: String?
    let suffix: String?
    
    init(_ row: RowDataItem ) {
        self.register = row.register
        self.regAddon = row.regAddon
        self.exponent = row.exponent
        self.expAddon = row.expAddon
        self.suffix = row.suffix
    }
}

struct TypedRegister: View {
    let row: RowDataItem
    let size: TextSize
    
    var body: some View {
        let line = row.getRichText()
        let (bodySize, subSize) = textSpecTable[size] ?? (15.0, 10.0)
        
        HStack( alignment: .bottom, spacing: 0 ) {
            RichText(
                line,
                bodyFont: .system( size: bodySize, weight: .bold, design: .serif),
                subScriptFont: .system( size: subSize, weight: .bold, design: .default))
        }
        .frame( height: 18 )
    }
}


struct Display: View {
    @StateObject var model: CalculatorModel

    let rowHeight:Double = 35.0
    
    var body: some View {
        let _ = Self._printChanges()
        
        let recText = model.isKeyRecording() ? "REC" : ""
        
        let (bodySize, subSize) = textSpecTable[.small] ?? (15.0, 10.0)
        
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color("Display"))
            
            VStack( alignment: .leading, spacing: 4) {
                // Status line above register displays
                HStack {
                    Spacer()
                    RichText(
                        recText,
                        bodyFont: .system( size: bodySize, design: .default),
                        subScriptFont: .system( size: subSize, design: .default),
                        defaultColor: "StatusRedText" )
                }.frame( height: 10 ).padding(0)
                
                ForEach (0..<model.rowCount, id: \.self) { index in
                    TypedRegister( row: model.getRow(index: index), size: .large ).padding(.leading, 10)
                }
            }
            .frame( height: rowHeight*Double(model.rowCount) )
        }
        .padding( [.leading, .trailing], 10)
        .background(Color("Display"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Frame"), lineWidth: 6))
        .fixedSize(horizontal: false, vertical: true)
    }
}

