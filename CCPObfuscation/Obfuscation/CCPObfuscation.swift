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
    case all
    
    var filter: [String] {
        switch self {
        case .default:
            return ["h", "m", "swift", "mm"]
        default:
            return [self.rawValue]
        }
    }
}

extension ObfuscationExtension: Equatable {
    public static func == (lhs: ObfuscationExtension, rhs: ObfuscationExtension) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    
}

enum ObfuscationError: Error {
    case emptySource
    case invalidURL(_ url: URL)
    case unkonwn
    case createFilesGroupFailed
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

 enum ObfuscationIgnores {
    case prefix(_ condition: String)
    case suffix(_ condition: String)
    case contains(_ condition: String)
    case equal(_ condition: String)
    case document(_ condition: String)
    
    //区分大小写
    //不过滤分类
    func evaluate(with value: URL) -> Bool {
        if value.lastPathComponent.contains("+") {
            return false
        }
        switch self {
        case .prefix(let condition):
            return value.lastPathComponent.hasPrefix(condition)
        case .suffix(let condition):
            return value.lastPathComponent.hasSuffix(condition)
        case .contains(let condition):
            return value.lastPathComponent.contains(condition)
        case .equal(let condition):
            return value.lastPathComponent == condition
        case .document(let condition):
           return value.path.match(pattern: "(?<=/)\(condition)(?=/)")
        }
    }
    
    static var `default`: [ObfuscationIgnores] {
        return [suffix(".xcassets"), suffix(".plist"), suffix(".app"), suffix(".xctest"), suffix(".xib"), suffix(".storyboard"), suffix(".entitlements"), suffix(".framework"), suffix(".tbd"), suffix(".png"), suffix(".jpeg"), suffix(".gif"), suffix(".jpg"), suffix(".xcodeproj"), suffix(".xcworkspace"), suffix(".md"), suffix(".lock"), suffix(".git"), suffix(".svn"), document("Pods")]
    }
    
    static var renameClass: [ObfuscationIgnores] {
        return self.default + [equal("AppDelegate")]
    }
    
    static func evalutes(ignores: [ObfuscationIgnores], value: URL) -> Bool {
        for ignore in ignores {
            if ignore.evaluate(with: value) {
                return true
            }
        }
        return false
    }
}

class Obfuscation {
    typealias Completed = Bool
    
    func files(in source: ObfuscationSource, ignores: [ObfuscationIgnores], ext: ObfuscationExtension) throws -> [URL] {
        var urls = [URL]()
        let url = try source.url()
        guard let enumerators = FileManager.default.enumerator(atPath: url.path) else {
            throw ObfuscationError.invalidURL(url)
        }
        while let next = enumerators.nextObject() as? String {
            let subURL = url.appendingPathComponent(next)
            if !ext.filter.contains(subURL.pathExtension) && !(ext == .all) { continue }
            if ObfuscationIgnores.evalutes(ignores: ignores, value: subURL.deletingPathExtension()) { continue }
            var isDirectory: ObjCBool = false
            let isExists = FileManager.default.fileExists(atPath: subURL.path, isDirectory: &isDirectory)
            if !isExists { continue }
            if !isDirectory.boolValue {
                urls.append(subURL)
            }
        }
        return urls
    }
    
    func deleteNotes(source: ObfuscationSource, ignores: [ObfuscationIgnores] = ObfuscationIgnores.default, ext: ObfuscationExtension = .default) throws -> Completed {
        let urls = try files(in: source, ignores: ignores, ext: ext)
        return try urls.reduce(false, { (_, url) -> Bool in
            let content = try String(contentsOf: url).replace(pattern: .notesReg, with: "")
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        })
    }
    
    func renameClass(source: ObfuscationSource, condition: ModifyCondition = .none, modify: ObfuscationModify = .random, ignores: [ObfuscationIgnores] = ObfuscationIgnores.renameClass, ext: ObfuscationExtension = .default) throws -> Completed {
        var urls = try files(in: source, ignores: ignores, ext: ext)
        urls = condition.extract(urls: urls)
        let modifies = modify.modifies(of: urls, base: try! source.url().deletingLastPathComponent().lastPathComponent)
        for modify in modifies {
            let name = modify.oldName.replacingOccurrences(of: "+", with: "\\+")
            let fileContent = try String(contentsOf: modify.oldURL).replace(pattern: "(?<=[^\\w])\(name)(?=[^\\w])", with: modify.newName)
            try fileContent.write(to: modify.newURL, atomically: true, encoding: .utf8)
            
        }
        return true
    }
    
    func newFilesDocument(_ name: String) throws -> URL {
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            throw ObfuscationError.createFilesGroupFailed
        }
        let documentURL = desktop.appendingPathComponent("CCPObfuscationNew/\(name)")
        if FileManager.default.fileExists(atPath: documentURL.path) {
            return documentURL
        }
        do {
            try FileManager.default.createDirectory(at: documentURL, withIntermediateDirectories: true, attributes: nil)
        } catch  {
            throw ObfuscationError.createFilesGroupFailed
        }
        return documentURL
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

enum ModifyCondition {
    case prefix(_ prefix: String)
    case suffix(_ suffix: String)
    case none
    
    func extract(urls: [URL]) -> [URL] {
        
        return urls.filter { (url) -> Bool in
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
    
}

enum ObfuscationModify {
    
    typealias ModifyNew = (oldURL: URL, newURL: URL, oldName: String, newName: String)
    
    case prefix(_ prefix: String)
    case suffix(_ suffix: String)
    case random
    
    
    func modifies(of oldURLs: [URL], base: String) -> [(ModifyNew)] {
        print(oldURLs)
        return oldURLs.compactMap {
            let oldName = $0.deletingPathExtension().lastPathComponent
            let ext = $0.pathExtension
            guard let newDocumentName = $0.deletingLastPathComponent().pathComponents.split(separator: base).last?.joined(separator: "/") else {
                print("\(oldName)-->创建新文件失败")
                return nil
            }
            do {
                //分类时，只考虑xxx+xxx的场景
                let documentURL = try newFilesDocument(newDocumentName)
                var newName = ""
                let oldComponents = oldName.components(separatedBy: "+")
                if oldComponents.count > 2 { return nil }
                var last = oldComponents.last!
                switch self {
                case .prefix(let p):
                    newName = oldComponents.count > 1 ? oldComponents[0] + "+" + p + last : p + last
                case .suffix(let s):
                    newName = oldComponents.count > 1 ? oldComponents[0] + "+" + last + s : last + s
                case .random:
                    let randomIdx = Int.random(in: (0 ..< last.count))
                    newName = oldName
                    let idx = String.Index(utf16Offset: randomIdx, in: last)
                    last.insert(contentsOf: UUID().uuidString, at: idx)
                    newName = oldComponents.count > 1 ? oldComponents[0] + "+" + last : last
                }
                let fileURL = documentURL.appendingPathComponent("\(newName).\(ext)")
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    return ($0, fileURL, oldName, newName)
                }
                if FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) {
                    return ($0, fileURL, oldName, newName)
                }
                print("\(oldName)-->\(newName)创建新文件失败")
                return nil
            }
            catch {
                print(error.localizedDescription)
                return nil
            }
        }
    }
    
    func newFilesDocument(_ name: String) throws -> URL {
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            throw ObfuscationError.createFilesGroupFailed
        }
        let documentURL = desktop.appendingPathComponent("CCPObfuscationNew/\(name)")
        if FileManager.default.fileExists(atPath: documentURL.path) {
            return documentURL
        }
        do {
            try FileManager.default.createDirectory(at: documentURL, withIntermediateDirectories: true, attributes: nil)
        } catch  {
            throw ObfuscationError.createFilesGroupFailed
        }
        return documentURL
    }
}

extension String {
    static var notesReg: String {
        let _1 = "([^:/])?//.*" //
        let _2 = "/\\*+?[\\s\\S]*?(\\*/){1}?"/**/
        let _3 = "(?<=\n)\\s+" //空行
        return "(\(_1))|(\(_2))|(\(_3))"
    }
    
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
