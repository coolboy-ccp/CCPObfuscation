//
//  CCPObfuscation.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/17.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

enum ObfuscationFunction: CaseIterable {
    case renameClass
    case deleteNotes
    
    case funcName
    case garbageInFunc
    case garbageInClass
    case garbageClasses
    case extractHardCode
    case md5ClassName
    case md5FuncName
    case layout
}

extension ObfuscationFunction {
    func _func(_ obj: Obfuscator) -> (() ->()) {
        switch self {
        case .renameClass:
            return obj.renameClass
        case .deleteNotes:
            return obj.deleteNotes
        default:
            return empty
        }
    }
    
    func empty() {
        print("empty func")
    }
    
}

enum ModifyCondition {
    case prefix(_ prefix: String)
    case suffix(_ suffix: String)
    case none

    func valid(url: URL) -> Bool {
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

enum ObfuscationModify {
    
    typealias Unit = (oldURL: URL, newURL: URL, oldName: String, newName: String)
        
    case prefix(_ prefix: String)
    case suffix(_ suffix: String)
    case random
    
    func modify(of oldURL: URL) -> Unit? {
        //分类时，只考虑xxx+xxx的场景
        let oldFileName = oldURL.deletingPathExtension().lastPathComponent
        if oldFileName == "main" {  return nil }
        let components = oldFileName.components(separatedBy: "+")
        guard (1 ... 2).contains(components.count) else { return nil }
        let oldName = components.last!
        let oldClass = components.count == 2 ? components.first! : nil
        
        var newName = ""
        switch self {
        case .prefix(let p):
            newName = oldClass != nil ? "\(oldClass!)+\(p + oldName)" : "\(p + oldName)"
        case .suffix(let s):
            newName = oldClass != nil ? "\(oldClass!)+\(oldName + s)" : "\(oldName + s)"
        case .random:
            let randomIdx = Int.random(in: (0 ... oldName.count))
            let idx = String.Index(utf16Offset: randomIdx, in: oldName)
            var varOldName = oldName
            varOldName.insert(contentsOf: "\(oldName.hashValue)", at: idx)
            newName = oldClass != nil ? "\(oldClass!)+\(varOldName)" : varOldName
        }
        let newFileURL = oldURL.deletingLastPathComponent().appendingPathComponent("\(newName).\(oldURL.pathExtension)")
        do {
            try FileManager.default.copyItem(at: oldURL, to: newFileURL)
            try FileManager.default.removeItem(at: oldURL)
            return (oldURL, newFileURL, oldFileName, newName)
        } catch  {
            print(error.localizedDescription)
        }
        return nil
        
    }
}


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
        return [document("Pods")]
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


class Obfuscator {
    
    static let validExtensionsDefault = ["h", "m", "c", "mm", "swift"]
    fileprivate let validExtensions: [String]!
    fileprivate let ignores: [ObfuscationIgnores]!
    fileprivate let modifyCondition: ModifyCondition!
    fileprivate let modify: ObfuscationModify!
    fileprivate let source: ObfuscationSource!
    fileprivate var urls: [URL] = []
    fileprivate var pbxprojsURL: [URL] = [] //存放工程中类文件路径名称的地方，若此文件缺失，则无法修改工程中文件名称，只能在修改后从文件夹中手动引入
    
    func go(funcs: [ObfuscationFunction] = ObfuscationFunction.allCases) {
        for f in funcs {
            f._func(self)()
        }
    }
    
    init(source: ObfuscationSource,
         modifyCondition: ModifyCondition = .none,
         modify: ObfuscationModify = .prefix("_ccp"),
         ignores: [ObfuscationIgnores] = ObfuscationIgnores.default,
         validExtensions: [String] = Obfuscator.validExtensionsDefault) throws {
         self.source = source
         self.modifyCondition = modifyCondition
         self.modify = modify
         self.ignores = ignores
         self.validExtensions = validExtensions
         try copyToDesktop()
    }
    
    fileprivate func allFilesURL(in document: URL) -> [URL] {
        var urls = [URL]()
        guard let enumerators = FileManager.default.enumerator(atPath: document.path) else {
            return urls
        }
        while let next = enumerators.nextObject() as? String {
            let url = document.appendingPathComponent(next)
            var isDirectory: ObjCBool = false
            let isExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            if !isExists { continue }
            if !isDirectory.boolValue {
                if url.pathExtension == "pbxproj" {
                    self.pbxprojsURL.append(url)
                }
                urls.append(url)
            }
        }
        return urls
    }
    
    fileprivate  func deleteNotes() {
        for url in urls {
            guard valid(url) else { continue }
            var content = ""
            do {
                content = try String(contentsOf: url).replace(pattern: .notesReg, with: "")
                try content.write(to: url, atomically: true, encoding: .utf8)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    fileprivate func valid(_ url: URL) -> Bool {
        return !ObfuscationIgnores.evalutes(ignores: ignores, value: url) && validExtensions.contains(url.pathExtension)
    }
    
    fileprivate func renameClass() {
        var newUnits = [ObfuscationModify.Unit]()
        let renamedURLs = urls.compactMap { (url) -> URL? in
            guard valid(url) else { return nil }
            guard modifyCondition.valid(url: url) else { return nil }
            if let new = modify.modify(of: url) {
                newUnits.append(new)
                return new.newURL
            }
            return url
        }
        for unit in newUnits {
            urls.removeAll { $0 == unit.oldURL }
            urls.append(unit.newURL)
            let oldName = unit.oldName.replacingOccurrences(of: "+", with: "\\+")
            for url in renamedURLs + pbxprojsURL {
                do {
                    let content = try String(contentsOf: url).replace(pattern: "(?<=[^\\w])\(oldName)(?=[^\\w])", with: unit.newName)
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    
    fileprivate func copyToDesktop() throws {
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            throw ObfuscationError.noDesktop
        }
        let oldURL = try source.url()
        var newURL = desktop.appendingPathComponent("\(oldURL.lastPathComponent)_ccp")
        var idx = 0
        while FileManager.default.fileExists(atPath: newURL.path) {
            idx += 1
            newURL = desktop.appendingPathComponent("\(oldURL.lastPathComponent)_ccp_\(idx)")
        }
        do {
            try FileManager.default.copyItem(at: oldURL, to: newURL)
            self.urls = allFilesURL(in: newURL)
            
        } catch {
            print(error.localizedDescription)
        }
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
