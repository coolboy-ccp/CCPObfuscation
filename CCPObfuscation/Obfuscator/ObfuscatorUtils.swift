//
//  CCPObfuscation.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/17.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa


enum ObfuscationError: Error {
    case emptySource
    case invalidURL(_ url: URL)
    case unkonwn
    case createFilesGroupFailed
    case failedToCreate(_ url: URL)
    case noDesktop
}

extension ObfuscationError: LocalizedError {
    var errorDescription: String? {
        let base = "[ObfuscationError🐯🐯🐯]--"
        switch self {
        case .invalidURL(let url):
            return base + "无效的地址: \(url.path)"
        case .emptySource:
            return base + "空地址"
        case .createFilesGroupFailed:
            return base + "创建新代码文件夹失败"
        case .failedToCreate(let url):
            return base + "创建\(url.path)失败"
        case .noDesktop:
            return base + "找不到桌面文件夹"
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

extension String {    
    func match(pattern: String) -> Bool {
        do {
            let regexp = try NSRegularExpression(pattern: pattern)
            if let rlt = regexp.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) {
                return rlt.range.location != NSNotFound
            }
        } catch {
            print(error.localizedDescription)
        }
        return false
    }
    
    func replace(pattern: String, with str: String) throws -> String {
        let regexp = try NSRegularExpression(pattern: pattern)
        var ranges = [NSRange]()
        regexp.enumerateMatches(in: self, options: [], range: NSRange(location: 0, length: self.count)) { (result, _, _) in
            if let rlt = result {
                ranges.append(rlt.range)
            }
        }
        
        let mstr = NSMutableString(string: self)
        for range in ranges.reversed() {
            mstr.replaceCharacters(in: range, with: str)
        }
        return mstr as String
    }
    
    
    
}
