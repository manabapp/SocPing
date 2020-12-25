//
//  UInt8+Extension.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

extension UInt8 {
    var char: Character {
        return Character(UnicodeScalar(self))
    }
}
