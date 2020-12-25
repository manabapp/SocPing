//
//  Data+Extension.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
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
