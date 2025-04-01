//
//  Utility.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-26.
//
import SwiftUI
import Combine


// *****************
// Numeric Utilities

func getInt( _ x: Double ) -> Int? {
    /// Test if a Double is an integer
    /// Valid down to 1.0000000000000005 or about 16 significant digits
    ///
    x == floor(x) ? Int(x) : nil
}

func isInt( _ x: Double ) -> Bool {
    /// Test if a Double is an integer
    /// Valid down to 1.0000000000000005 or about 16 significant digits
    ///
    x == floor(x)
}

func isEven( _ x: Int ) -> Bool {
    // Return true if x is evenly divisible by 2.
    x % 2 == 0
}


func rect2polar( _ x: Double, _ y: Double ) -> (Double, Double) {
    ( sqrt(x*x + y*y), atan2(y,x) )
}


func polar2rect( _ r: Double, _ w:  Double ) -> (Double, Double) {
    ( r*cos(w), r*sin(w) )
}


func rect2spherical( _ x: Double, _ y: Double, _ z: Double ) -> (Double, Double, Double) {
    let r = sqrt(x*x + y*y + z*z)
    return ( r, atan2(y,x), acos(z/r) )
}

func spherical2rect( _ r: Double, _ w: Double, _ p: Double ) -> (Double, Double, Double) {
    ( r*sin(p)*cos(w), r*sin(p)*sin(w), r*cos(p) )
}

func deg2rad( _ d: Double ) -> Double {
    d / 180.0 * Double.pi
}


func rad2deg( _ w: Double ) -> Double {
    w / Double.pi * 180.0
}


// **************
// Swift Utiliies

extension Array {
    
    func chunked(into size: Int) -> [[Element]] {
        return stride( from: 0, to: count, by: size).map {
            Array( self[$0 ..< Swift.min($0 + size, count)] )
        }
    }
    
    mutating func resize( to size: Int, with filler: Element ) {
        let sizeDifference = size - count
        
        guard sizeDifference != 0 else {
            return
        }
        
        if sizeDifference > 0 {
            self.append( contentsOf: Array<Element>(repeating: filler, count: sizeDifference));
        }
        else {
            self.removeLast( sizeDifference * -1 ) //*-1 because sizeDifference is negative
        }
    }
    
    func resized( to size: Int, with filler: Element ) -> Array {
        var selfCopy = self;
        selfCopy.resize(to: size, with: filler)
        return selfCopy
    }
}


// ****************
// SwiftUI Utiliies

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

// Used only by View extension below
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
