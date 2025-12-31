//
//  Utility.swift
//  Computor
//
//  Created by Barry Hall on 2025-01-26.
//
import SwiftUI


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


// *****

var navigationPolar: Bool = false

func rect2polar( _ x: Double, _ y: Double ) -> (Double, Double) {
    navigationPolar ? ( sqrt(x*x + y*y), atan2(x,y) ) : ( sqrt(x*x + y*y), atan2(y,x) )
}


func polar2rect( _ r: Double, _ w:  Double ) -> (Double, Double) {
    navigationPolar ? ( r*sin(w), r*cos(w) ) : ( r*cos(w), r*sin(w) )
}

// *****


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


// ******************
// iOS File Functions

func createDirectory( _ dirURL: URL ) {
    
    /// ** Create Directory **
    
    let pathTail = findPathTail( dirURL.path(), from: "Documents")
    
    do {
        try FileManager.default.createDirectory( at: dirURL, withIntermediateDirectories: false, attributes: nil)
        
        print( "Directory created: ../\(pathTail)" )
    }
    catch CocoaError.fileWriteFileExists {
        // print( "Directory already exists: ../\(pathTail)" )
    }
    catch {
        print("Error creating directory: \(pathTail) - \(error.localizedDescription)")
        assert(false)
    }
}


func listFiles( inDirectory path: String, withPrefix pattern: String ) -> [String] {
    
    /// ** List Files in Path **
    
    let fileManager = FileManager.default
    
    do {
        let contents = try fileManager.contentsOfDirectory( atPath: path)
        let filteredFiles = contents.filter { $0.hasPrefix(pattern) }
        return filteredFiles
    }
    catch {
        print("Error listing path \(path) Error: \(error) - return []")
        return []
    }
}


func deleteFile( fileName: String, inDirectory directoryURL: URL) {
    
    /// ** Delete File **
    
    let fileManager = FileManager.default
    let fileURL = directoryURL.appendingPathComponent(fileName)
    
    do {
        try fileManager.removeItem(at: fileURL)
        
#if DEBUG
        print("File '\(fileName)' successfully deleted from '\(directoryURL.lastPathComponent)' directory.")
#endif
    }
    catch {
        print("Error deleting file '\(fileName)': \(error.localizedDescription)")
    }
}


func deleteAllFiles( in directoryURL: URL) {
    
    /// ** Delete All Files **
    
    let fileManager = FileManager.default
    
    do {
        // Get the contents of the directory
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        // Iterate through the files and remove each one
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
        
#if DEBUG
        print("Successfully deleted all files in: \(directoryURL.lastPathComponent)")
#endif
    }
    catch {
        print("Error deleting files in directory: \(error)")
    }
}


func renameFile( originalURL: URL, newName: String) {
    
    /// ** Rename File **
    
    let fileManager = FileManager.default
    
    // Get the directory of the original file
    let directoryURL = originalURL.deletingLastPathComponent()
    
    // Create the new URL with the desired new name
    let newURL = directoryURL.appendingPathComponent(newName)
    
    do {
        try fileManager.moveItem(at: originalURL, to: newURL)
        
        print("File successfully renamed from \(originalURL.lastPathComponent) to \(newURL.lastPathComponent)")
    }
    catch {
        print("Error renaming file: \(error.localizedDescription)")
    }
}


func findPathTail( _ path: String, from subStr: String ) -> String {
    
    if let range = path.range( of: subStr ) {
        
        return String( path[range.lowerBound...] )
    }
    
    return ""
}
