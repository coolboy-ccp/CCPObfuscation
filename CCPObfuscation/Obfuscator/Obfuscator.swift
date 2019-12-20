//
//  Obfuscator.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

enum ObfuscationFunction: CaseIterable {
    case deleteNotes
    case renameClass
    case renameProperty
    case extractHardCode
    
    case funcName
    case garbageInFunc
    case garbageInClass
    case garbageClasses
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
        case .renameProperty:
            return obj.renameProperty
        case .extractHardCode:
            return obj.extractHardCode
        default:
            return empty
        }
    }
    
    func empty() {
        print("empty func")
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
    
    var validExtensions: [String] = []
    
    var modifyCondition: ModifyCondition = .none
    
    var pbxprojsURL: [URL] = [] //存放工程中类文件路径名称的地方，若此文件缺失，则无法修改工程中文件名称，只能在修改后从文件夹中手动引入
    var urls: [URL] = []
    
    let ignores: [ObfuscationIgnores]
    var modify: ObfuscatorModify!
    var rootURL: URL!
    
    fileprivate let source: ObfuscationSource!
        
    func go(funcs: [ObfuscationFunction] = ObfuscationFunction.allCases) {
        for f in funcs {
            validExtensions = ["h", "m", "c", "mm", "swift", "pch"]
            f._func(self)()
        }
    }
    
    init(source: ObfuscationSource,
         modifyCondition: ModifyCondition = .none,
         modify: ObfuscatorModify = .prefix("_ccp"),
         ignores: [ObfuscationIgnores] = ObfuscationIgnores.default) throws {
         self.source = source
         self.modifyCondition = modifyCondition
         self.modify = modify
         self.ignores = ignores
         try copyToDesktop()
    }
    
    func allFilesURL(in document: URL) -> [URL] {
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
    
     func valid(_ url: URL) -> Bool {
         return !ObfuscationIgnores.evalutes(ignores: ignores, value: url) && validExtensions.contains(url.pathExtension)
     }
     
    func copyToDesktop() throws {
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
            self.rootURL = newURL
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
