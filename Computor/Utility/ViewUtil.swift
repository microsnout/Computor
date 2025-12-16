//
//  ViewUtil.swift
//  Computor
//
//  Created by Barry Hall on 2025-10-24.
//
//  Utility View components

import SwiftUI
import Combine


extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


struct SheetCollapsibleView<Content: View>: View {
    
    var code: Int
    var label: String
    
    @Binding var drop: Int
    
    @ViewBuilder var content: Content
    
    @State private var isCollapsed = true
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            HStack {
                RichText( "ƒ{1.2}\(label)", size: .large, weight: .bold, design: .default, defaultColor: "WhiteText")
                
                Spacer()
                
                Button( "", systemImage: isCollapsed ? Const.Icon.chevronDn : Const.Icon.chevronUp ) {
                    
                    if drop == code {
                        withAnimation {
                            drop = 0
                        }
                    }
                    else {
                        withAnimation {
                            drop = code
                        }
                    }
                }
            }
            .padding(0)
            
            if drop == code {
                content
                    .transition( .asymmetric( insertion: .push(from: .top), removal: .push( from: .bottom)) )
            }
            
            Divider()
                .overlay( Color(.white))
        }
        .accentColor( Color("WhiteText") )
        .padding([.top], 10)
    }
}


struct SheetAlternateView<Content: View>: View {
    
    var label: String
    var textSize: TextSize = .normal
    var textWeight: Font.Weight = .bold
    var textDesign: Font.Design = .default
    
    var textColor: String = "WhiteText"
    var accentColor: String = "WhiteText"

    // System Image names
    var defIcon: String = Const.Icon.bulletList
    var altIcon: String = Const.Icon.gridList
    
    // Default view and alternate view
    @ViewBuilder var defView: Content
    @ViewBuilder var altView: Content

    @State private var isDefault = true
    
    var body: some View {
        
        VStack( alignment: .leading ) {
            
            HStack {
                RichText( label, size: textSize, weight: textWeight, design: textDesign, defaultColor: textColor)
                
                Spacer()
                
                Button( "", systemImage: isDefault ? defIcon : altIcon ) {
                    withAnimation {
                        isDefault.toggle()
                    }
                }
            }
            .padding(0)
            
            if isDefault {
                defView
                    .transition( .asymmetric( insertion: .push(from: .top), removal: .push( from: .bottom)) )
            }
            else {
                altView
                    .transition( .asymmetric( insertion: .push(from: .top), removal: .push( from: .bottom)) )
            }
            
            Divider()
                .overlay( Color(.white))
        }
        .accentColor( Color(accentColor) )
        .padding([.top], 10)
    }
}


// ******************
// Not currently used
struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


// Not currently used
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner( radius: radius, corners: corners))
    }
}


// Not currently used
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

