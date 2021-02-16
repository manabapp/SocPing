//
//  Data+Extension.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
//

import Foundation

extension Data {
    var uint8array: [UInt8]? {
        self.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) -> [UInt8] in
            let buffer = ptr.bindMemory(to: UInt8.self)  // UnsafeBufferPointer
            let start = buffer.baseAddress!  // UnsafePointer
            return [UInt8](UnsafeBufferPointer(start: start, count: self.count))
        })
    }
}

extension Data {
    var dump: String {
        var count: Int = 0
        var num: Int = 0
        var dumpString: String = ""
        var detailString: String = ""
        let bytes = self.uint8array!
        
        while count < self.count {
            dumpString += String(format: " %04d:  ", count)
            detailString = "    "
            while count < self.count {
                dumpString += String(format: "%02x", bytes[count])
                detailString += SocLogger.printableLetters.contains(bytes[count].char) ? String(format: "%c", bytes[count]) : "."
                count += 1
                if count % 16 == 0 { break }
                if count % 8 == 0  { detailString += " " }
                if count % 4 == 0  { dumpString += " " }
            }
            num = 16 - (count % 16)
            if num > 0 && num < 16 {
                dumpString += String(repeating: " ", count: num * 2 + Int(num / 4))
            }
            dumpString += detailString + "\n"
        }
        return dumpString
    }
}
