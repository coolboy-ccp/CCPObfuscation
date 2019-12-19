//
//  ObfuscatorModify.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

enum ModifyCondition {
    case prefix(_ prefix: String)
    case suffix(_ suffix: String)
    case none

    func validFile(url: URL) -> Bool {
        let last = url.deletingPathExtension().lastPathComponent
        switch self {
        case .prefix(let p):
            return last.hasPrefix(p)
        case .suffix(let s):
            return last.hasSuffix(s)
        default:
            return true
        }
    }
}

enum ObfuscatorModify {
    
    typealias FileUnit = (oldURL: URL, newURL: URL, oldName: String, newName: String)
        
    case prefix(_ prefix: String)
    case suffix(_ suffix: String)
    case random    
}

