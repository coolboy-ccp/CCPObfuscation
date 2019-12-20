//
//  ExtractHardCode.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

extension ObfuscatorModify {
    
    fileprivate typealias HardCodeUnit = (old: String, new: String)
    fileprivate static var hardCodeSet = Set<String>()
    
    fileprivate func extractHardCode(_ url: URL) {
        let reg = "[\\w\\*]*\\w+\\s*={1,2}\\s*((@\"\\w+\")|([\\d.]+))"
        do {
            let content = try String(contentsOf: url)
            let exp = try NSRegularExpression(pattern: reg)
            exp.enumerateMatches(in: content, options: [], range: NSRange(location: 0, length: content.count)) { (result, _, _) in
                if let rlt = result {
                    ObfuscatorModify.hardCodeSet.insert((content as NSString).substring(with: rlt.range(at: 1)))
                }
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    fileprivate func writeConst(in document: URL) -> [HardCodeUnit] {
        var units = [HardCodeUnit]()
        if ObfuscatorModify.hardCodeSet.count == 0 {
            print("项目中没有硬代码")
            return units
        }
        guard let url = createConstFile(in: document) else {
            print("创建常量文件失败")
            return units
        }
        let name = url.deletingPathExtension().lastPathComponent + "_h"
        var codeStr = "#ifndef \(name)\n#define \(name)\n\n"
        for code in ObfuscatorModify.hardCodeSet {
            var key = ""
            switch self {
            case .prefix(let p):
                key = "\(p)_\(abs(code.hashValue))"
            case .suffix(let s):
                key = "k\(abs(code.hashValue))_\(s)"
            default:
                key = "CCPConst_\(abs(code.hashValue))"
            }
            let str = "#define \(key) \(code)\n"
            codeStr.append(contentsOf: str)
            units.append((code, key))
        }
        codeStr.append(contentsOf: "\n#endif")
        do {
            try codeStr.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
        return units
    }
    
    private func createConstFile(in document: URL) -> URL? {
        var fileURL = document.appendingPathComponent("CCPHardCodeConst.h")
        var idx = 0
        while FileManager.default.fileExists(atPath: fileURL.path) {
            idx += 1
            fileURL = document.appendingPathComponent("CCPHardCodeConst_\(idx).h")
        }
        if FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) {
            return fileURL
        }
        return nil
    }

}


/* 暂时只支持oc
 * 将生成的CCPHardCodeConst.h移动到BUILT_PRODUCTS_DIR(就是工程创建时和proj同级的目录)
 * pch #import
 
 */
extension Obfuscator {
    func extractHardCode() {
        validExtensions = ["m"]
        let extractFilesURL = urls.filter { return valid($0) }
        for url in extractFilesURL {
            modify.extractHardCode(url)
        }
        for unit in modify.writeConst(in: rootURL) {
            let old = unit.old.replacingOccurrences(of: ".", with: "\\.")
            let reg = "(?<=\\={1,3})\\s*(\(old))(?!\\.)\\s*"
            for url in extractFilesURL {
                do {
                    var content = try String(contentsOf: url)
                    let exp = try NSRegularExpression(pattern: reg)
                    var ranges = [NSRange]()
                    exp.enumerateMatches(in: content, options: [], range: NSRange(location: 0, length: content.count)) { (reslut, _, _) in
                        if let rlt = reslut, rlt.numberOfRanges == 2 {
                            ranges.append(rlt.range(at: 1))
                        }
                    }
                    for range in ranges.reversed() {
                        content = (content as NSString).replacingCharacters(in: range, with: unit.new)
                    }
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
        
}
