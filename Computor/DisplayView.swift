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
                let cw = ch == "%" ? self.charWidth + 5 : self.charWidth
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
            .frame( height: 20 )
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
        
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color("Display"))
            
            VStack( alignment: .leading, spacing: 5) {
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

// ************************************************************* //

struct MemoryDetailView: View {
    @StateObject var model: CalculatorModel
    @State private var editText = ""
    @FocusState private var nameFocused: Bool
    @Binding var nameEdit: Bool
        
    var index: Int
    var item: RowDataItem

    var body: some View {
        Form {
            TextField( "-Unnamed-", text: $editText )
            .focused($nameFocused)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .onAppear {
                if let name = item.prefix {
                    editText = name
                }
                nameFocused = true
            }
            .onSubmit {
                model.renameMemoryItem(index: index, newName: editText)
                nameEdit = false
            }

            TypedRegister( row: NoPrefix(item), size: .normal ).padding( .leading, 0)
        }
    }
}


struct MemoryDisplay: View {
    @StateObject var model: CalculatorModel
    
    let leadingOps: [(key: KeyCode, text: String, color: Color)]
    
    @State var nameEdit = false
    @State private var rowIndex = 0
    
    @ViewBuilder
    var memoryList: some View {
        VStack {
            let rows = model.state.memoryList
            
            if rows.isEmpty {
                Text("Memory List\n(Press + to store X register)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            else {
                List {
                    ForEach ( Array( rows.enumerated()), id: \.offset ) { index, item in
                        VStack( alignment: .leading, spacing: 0 ) {
                            let name = item.prefix != nil ? item.prefix! : "-name-"
                            
                            let color = item.prefix != nil ? Color("DisplayText") : Color(.gray)
                            
                            HStack {
                                Text(name).font(.footnote).bold().foregroundColor(color).listRowBackground(Color("List0"))
                                    .onTapGesture {
                                        rowIndex = index
                                        nameEdit = true
                                    }
                            }
                            
                            TypedRegister( row: NoPrefix(item), size: .small ).padding( .horizontal, 20)
                        }
                        .listRowSeparatorTint(.blue)
                        .frame( height: 30 )
                        .swipeActions( edge: .leading, allowsFullSwipe: true ) {
                            ForEach ( leadingOps, id: \.key) { key, text, color in
                                Button {
                                    model.memoryOp( key: key, index: index )
                                } label: { Text(text).bold() }.tint(color)
                            }
                        }
                        .swipeActions( edge: .trailing, allowsFullSwipe: false) {
                            Button( role: .destructive) {
                                model.delMemoryItems( set: IndexSet( [index] ))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listRowSeparatorTint( Color("DisplayText"))
                }
                .listRowSpacing(0)
                .listStyle( PlainListStyle() )
                .padding( .horizontal, 0)
                .padding( .top, 0)
            }
        }
    }

    var body: some View {
        let rows = model.state.memoryList
        
        if nameEdit {
            MemoryDetailView( model: model, nameEdit: $nameEdit, index: rowIndex, item: rows[rowIndex])
                .frame( maxWidth: .infinity, maxHeight: .infinity)
                .background( Color("Display") )
                .border(Color("Frame"), width: 3)
        }
        else {
            memoryList
                .frame( maxWidth: .infinity, maxHeight: .infinity)
                .background( Color("MemoryDisplay") )
                .border(Color("Frame"), width: 3)
        }
    }
}

