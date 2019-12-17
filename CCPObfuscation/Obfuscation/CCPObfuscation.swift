//
//  CCPObfuscation.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/17.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

enum ObfuscationType {
    case className
    case funcName
    case deleteBlanks
    case deleteNotes
    case garbageInFunc
    case garbageInClass
    case garbageClasses
    case extractHardCode
    case md5ClassName
    case md5FuncName
    case layout
}

public enum ObfuscationExtension: String {
    case h
    case m
    case mm
    case swift
    case xib
    case storyboard
    case c
    case cpp
    case `default`
    
    var filter: [String] {
        switch self {
        case .default:
            return ["h", "m", "swift", "mm"]
        default:
            return [self.rawValue]
        }
    }
}

enum ObfuscationError: Error {
    case emptySource
    case invalidURL(_ url: URL)
}

extension ObfuscationError: LocalizedError {
    var errorDescription: String? {
        let base = "[ObfuscationError🐯🐯🐯]--"
        switch self {
        case .invalidURL(let url):
            return base + "无效的地址: \(url.path)"
        case .emptySource:
            return base + "空地址"
        default:
            return base + "unkonwn error"
        }
    }
}

protocol ObfuscationSource {
    func url() throws -> URL
}

extension String: ObfuscationSource {
    func url() throws -> URL {
        return URL(fileURLWithPath: self)
    }
}

extension URL: ObfuscationSource {
    func url() throws -> URL {
        return self
    }
}

extension Optional where Wrapped: ObfuscationSource {
    func url() throws -> URL {
        switch self {
        case .some(let v):
            return try v.url()
        default:
            throw ObfuscationError.emptySource
        }
    }
}

 extension Array where Element == URL {
    public func obfuscationFiles(type: ObfuscationExtension) -> [URL] {
        return self.filter { (e) -> Bool in
            return type.filter.contains(e.pathExtension)
        }
    }
}

class Obfuscation {
    typealias Completed = Bool
    
    func findAllFiles(in source: ObfuscationSource) throws -> [URL] {
        var urls = [URL]()
        let url = try source.url()
        guard let enumerators = FileManager.default.enumerator(atPath: url.path) else {
            throw ObfuscationError.invalidURL(url)
        }
        while let next = enumerators.nextObject() as? String {
            let subURL = url.appendingPathComponent(next)
            var isDirectory: ObjCBool = false
            let isExists = FileManager.default.fileExists(atPath: subURL.path, isDirectory: &isDirectory)
            if !isExists { continue }
            if !isDirectory.boolValue {
                urls.append(subURL)
            }
        }
        return urls
    }
    
    func deleteNotes(source: ObfuscationSource, ignores: [String]? = nil) throws -> Completed {
        var urls = try findAllFiles(in: source)
        urls = urls.obfuscationFiles(type: .default)
        return try urls.reduce(false, { (_, url) -> Bool in
            var content = try String(contentsOf: url)
            let notesRange = try content.reg(pattern: .notesReg)
            let mstr = NSMutableString(string: content)
            for range in notesRange.reversed() {
               mstr.replaceCharacters(in: range, with: "")
            }
            content = mstr as String
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        })
    }
    
    func openFinder(_ source: ObfuscationSource)  {
        let panel = NSOpenPanel()
        panel.directoryURL = try? source.url()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.begin { (response) in
            print(response)
        }
    }
    
}

extension String {
    static var notesReg: String {
        let _1 = "([^:/])?//.*" //
        let _2 = "/\\*+?[\\s\\S]*?(\\*/){1}?"/**/
        let _3 = "(?<=\n)\\s+(?=\n)" //空行
        return "(\(_1))|(\(_2))|(\(_3))"
    }
    
    func reg(pattern: String) throws -> [NSRange] {
        let regexp = try NSRegularExpression(pattern: pattern)
        var ranges = [NSRange]()
        regexp.enumerateMatches(in: self, options: [], range: NSRange(location: 0, length: self.count)) { (result, _, _) in
            if let rlt = result {
                ranges.append(rlt.range)
            }
        }
        return ranges
    }
}
