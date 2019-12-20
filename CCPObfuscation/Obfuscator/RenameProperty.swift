//
//  RenameProperty.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

class A {
    var    a: String = ""
    let b: String = ""
}

extension ObfuscatorModify {
    
    typealias PropertyUnit = (old: String, new: String)
    
    fileprivate func property(_ url: URL) -> [PropertyUnit]  {
        let isSwift = url.pathExtension == "swift"
        let regx = isSwift ? "(?:var|let)\\s+(\\w+)\\s*:{1}" : "@property\\s*\\(.+\\)\\s*\\w+[\\s*]+\\s*(\\w+)\\s*;"
        do {
            let content = try String(contentsOf: url)
            return properties(pattern: regx, str: content)
        } catch {
            print(error.localizedDescription)
        }
        return []
    }
    
    private func properties(pattern: String, str: String) -> [PropertyUnit] {
        var properties = [PropertyUnit]()
        do {
            let regexp = try NSRegularExpression(pattern: pattern)
            
            regexp.enumerateMatches(in: str, options: [], range: NSRange(location: 0, length: str.count)) { (result, _, _) in
                if let rlt = result, rlt.numberOfRanges == 2 {
                    let old = (str as NSString).substring(with: rlt.range(at: 1))
                    var new = ""
                    switch self {
                    case .prefix(let p):
                        new = p + old
                    case .suffix(let s):
                        new = old + s
                    case .random:
                        new = old + "\(old.hashValue)"
                    }
                    properties.append((old, new))
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return properties
    }
}

extension Obfuscator {
    //修改掉同名的局部变量
    func renameProperty() {
        let validURLs: [URL] = urls.compactMap {
            if valid($0) { return $0 }
            return nil
        }
        let properties = validURLs.compactMap { (url) -> [ObfuscatorModify.PropertyUnit]? in
            guard valid(url) else { return nil }
            return modify.property(url)
        }.flatMap { return $0 }
        for property in properties {
            for url in validURLs {
                replace(in: url, old: property.old, new: property.new)
            }
        }
    }
    
    private func replace(in url: URL, old: String, new: String) {
        let regx = "\\b(?<![\"])[\\s_]*(\(old))[\\s_]*(?!\")\\b"
        do {
            var content = try String(contentsOf: url)
            let regexp = try NSRegularExpression(pattern: regx)
            var ranges = [NSRange]()
            regexp.enumerateMatches(in: content, options: [], range: NSRange(location: 0, length: content.count)) { (result, _, _) in
                if let rlt = result, rlt.numberOfRanges == 2 {
                    ranges.append(rlt.range(at: 1))
                }
            }
            for range in ranges.reversed() {
                content = (content as NSString).replacingCharacters(in: range, with: new)
            }
            try content.write(to: url, atomically: true, encoding: .utf8)
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
