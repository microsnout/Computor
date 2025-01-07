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

struct MonoText: View {
    let content: String
    let addon: String?
    let charWidth: CGFloat
    let font: Font
    let alignment: VerticalAlignment

    init(_ content: String, addon: String?, charWidth: CGFloat, font: Font = .body, align: VerticalAlignment = .center ) {
        self.content = content
        self.addon = addon
        self.charWidth = charWidth
        self.font = font
        self.alignment = align
    }

    var body: some View {
        HStack( alignment: self.alignment, spacing: 0 ) {
            let chSeq = Array(self.content)
            
            ForEach(0..<self.content.count, id: \.self) { index in
                let ch = chSeq[index]
                let cw = self.charWidth
                
                Text( String(ch))
                    .font(font)
                    .foregroundColor(Color("DisplayText")).frame(width: cw)
            }
            .if ( addon != nil ) { view in
                // Used to add an underscore cursor in text entry mode
                HStack( alignment: self.alignment, spacing: 0 ) {
                    view
                    Text(addon!)
                        .font(font)
                        .foregroundColor(Color(.red)).frame(width: self.charWidth)
                }
            }
        }
    }
}

typealias TextSpec = ( prefixFont: Font, registerFont: Font, suffixFont: Font, monoSpace: Double )

enum TextSize {
    case normal, small, large
}

let textSpecTable: [TextSize: TextSpec] = [
    .normal : ( .footnote, .body, .footnote, 12.0 ),
    .small  : ( .caption, .footnote, .caption, 9.0 ),
    .large  : ( .footnote, .headline, .footnote, 12.0 )
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
        if let spec = textSpecTable[size] {
            HStack( alignment: .bottom, spacing: 0 ) {
                if let prefix = row.prefix {
                    Text(prefix).font(spec.prefixFont).bold().foregroundColor(Color("Frame")).padding(.trailing, 10)
                }
                
                MonoText(row.register, addon: row.regAddon, charWidth: spec.monoSpace, font: spec.registerFont)
                
                if let exp: String = row.exponent {
                    MonoText(exp, 
                             addon: row.expAddon,
                             charWidth: spec.monoSpace - 3,
                             font: spec.suffixFont,
                             align: .bottom).alignmentGuide(.bottom, computeValue: { d in 25 })
                }
                
                if let suffix = row.suffix {
                    Text(suffix).font(spec.suffixFont).bold().foregroundColor(Color("Units")).padding(.leading, 10)
                }
            }
            .frame( height: 18 )
        }
        else {
            EmptyView()
        }
    }
}

struct Display: View {
    @StateObject var model: CalculatorModel

    let rowHeight:Double = 35.0
    
    var body: some View {
        let _ = Self._printChanges()
        
        let recText = model.isKeyRecording() ? "REC" : ""
        
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color("Display"))
            
            VStack( alignment: .leading, spacing: 4) {
                HStack {
                    Spacer()
                    Text(recText).font(.caption).foregroundColor( Color(.red))
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

