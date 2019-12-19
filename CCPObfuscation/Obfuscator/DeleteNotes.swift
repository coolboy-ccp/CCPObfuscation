//
//  DeleteNotes.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

extension Obfuscator {
    
    func deleteNotes() {
        let notesRegx: String = {
            let _1 = "([^:/])?//.*" //
            let _2 = "/\\*+?[\\s\\S]*?(\\*/){1}?"/**/
            return "(\(_1))|(\(_2))"
        }()
        let spaceRegx = "(?<=\n)\\s+" //空行
        for url in urls {
            guard valid(url) else { continue }
            var content = ""
            do {
                content = try String(contentsOf: url).replace(pattern: notesRegx, with: "").replace(pattern: spaceRegx, with: "")
                try content.write(to: url, atomically: true, encoding: .utf8)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}
