//
//  RichText.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-10.
//
import SwiftUI

// Rule:
//      _{} subscript
//      ^{} superscript
//      ={} monospaced
//      ç{} Return to default color
//      ç{color} Set color to Asset str named color
//      ƒ{scale} Resize fonts by multipling by real scale value
//      ƒ{} Restore default font sizes
//
//      mainFont
//      script font
//      defaultColor
//

struct RichText: View {
    let inputStr: String
    let bodyFont: Font
    let subScriptFont: Font
    let baseLine: CGFloat
    let defaultColor: String
    
    let textSize: TextSize
    let textWeight: Font.Weight
    let textDesign: Font.Design
    
    init( _ inputStr: String, size: TextSize,
          weight: Font.Weight = .regular, design: Font.Design = .default,
          defaultColor: String = "DisplayText") {
        
        let (body, sub, base) = getTextSpec(size)
        
        self.inputStr = inputStr
        self.bodyFont = .system( size: body, weight: weight, design: design)
        self.subScriptFont = .system( size: sub, weight: weight, design: design)
        self.baseLine = base
        self.defaultColor = defaultColor
        
        self.textSize   = size
        self.textWeight = weight
        self.textDesign = design
    }

    var body: some View {
        var string = inputStr
        var text   = Text("")
        var color  = defaultColor
        var bodyFont: Font = self.bodyFont
        var subScriptFont: Font = self.subScriptFont

        let opCodeSet:Set<Character> = ["^", "_", "=", "ç", "ƒ"]
        
        while let validIndex = string.firstIndex( where: { (ch) -> Bool in  return opCodeSet.contains(ch) }) {
            
            let subStrP1 = string[..<validIndex]
            var subStrP2 = string[validIndex...]
            
            text = text + Text(subStrP1).font(bodyFont).foregroundColor( Color(color))
            
            if subStrP2.count < 3 {
                // No possible string op
                return text + Text(subStrP2).font(bodyFont)
            }
            
            // Operation code is member of opCodeSet
            var opType = subStrP2.first!
            
            // Remove op code char
            subStrP2 = subStrP2.dropFirst()
            
            // Start with empty string
            var opStr = ""
            
            if subStrP2.first != "{"  {
                //Not a string op
                opStr.append(String(opType))
                opType = Character(" ") //no Op
            }
            else if let endBraceIndex = subStrP2.firstIndex(where: { (char) -> Bool in  return (char == "}") })  {
                subStrP2 = subStrP2.dropFirst() ///remove {
                opStr = String( subStrP2[..<endBraceIndex])
                subStrP2 = subStrP2[endBraceIndex...].dropFirst() //remove }
            }
            else {
                // Input string error - {} imbalance
                return Text("")
            }
            
            switch opType {
            case "^":
                text = text + Text(opStr)
                    .font(subScriptFont)
                    .baselineOffset(baseLine)
                    .foregroundColor( Color(color))
                
            case "_":
                text = text + Text(opStr)
                    .font(subScriptFont)
                    .baselineOffset(-1 * baseLine)
                    .foregroundColor( Color(color))

            case "=":
                text = text + Text(opStr)
                    .font(bodyFont).monospaced()
                    .foregroundColor( Color(color))
                
            case "ç":
                color = opStr.isEmpty ? defaultColor : opStr
                
            case "ƒ":
                if opStr.isEmpty {
                    // Restore default fonts
                    bodyFont = self.bodyFont
                    subScriptFont = self.subScriptFont
                }
                else {
                    // Create scaled fonts
                    var (body, sub, _ ) = getTextSpec(textSize)
                    let scale = Double(opStr) ?? 1.0
                    body *= scale
                    sub  *= scale
                    bodyFont = .system( size: body, weight: textWeight, design: textDesign)
                    subScriptFont = .system( size: sub, weight: textWeight, design: textDesign)
                }
                
            default:
                text = text + Text(opStr)
                    .font(bodyFont)
                    .foregroundColor( Color(color))
            }
            string = String(subStrP2)
        }
        
        text = text + Text(string).font(bodyFont).foregroundColor( Color(color))
        return text
    }
}
