//
//  RenameClass.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

extension ObfuscatorModify {
    fileprivate func file(of oldURL: URL) -> FileUnit? {
        //分类时，只考虑xxx+xxx的场景
        let oldFileName = oldURL.deletingPathExtension().lastPathComponent
        if oldFileName == "main" || oldURL.pathExtension == "pch" {  return nil }
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


extension Obfuscator {
    func renameClass() {
        var newUnits = [ObfuscatorModify.FileUnit]()
        let renamedURLs = urls.compactMap { (url) -> URL? in
            guard valid(url) else { return nil }
            guard modifyCondition.validFile(url: url) else { return nil }
            if let new = modify.file(of: url) {
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
}
