//
//  Theme.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-03.
//
import SwiftUI

enum Theme: String, CaseIterable, Identifiable, Codable {
    case lightRed, lightGreen, lightBlue, lightYellow, lightGrey, lightPurple
    
    case mediumRed, mediumGreen, mediumBlue, mediumYellow, mediumGrey, mediumPurple

    var accentColor: Color {
        switch self {
            
        case .lightRed, .lightGreen, .lightBlue, .lightYellow, .lightPurple, .lightGrey: return .black
            
        case .mediumRed, .mediumGreen, .mediumBlue, .mediumYellow, .mediumPurple, .mediumGrey: return .black
        }
    }
    
    var mainColor: Color {
        Color(rawValue)
    }
    
    var mediumColor: Color {
        switch self {
        case .lightRed:    return .mediumRed
        case .lightBlue:   return .mediumBlue
        case .lightGreen:  return .mediumGreen
        case .lightGrey:   return .mediumGrey
        case .lightPurple: return .mediumPurple
        case .lightYellow: return .mediumYellow
            
        default:
            return mainColor
        }
    }
    
    var name: String {
        rawValue.capitalized
    }
    
    var id: String {
        name
    }
}

