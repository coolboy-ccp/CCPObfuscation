//
//  RenameFunc.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/19.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

extension Obfuscator {
    /* oc
     * 提取.h里的方法
     ps: 如果系统类放在.h中，也会被修改
     * swift
     * 提取private和fileprivate修饰的函数
     
     * 修改方法名称, 添加参数(后缀参数，依据方法返回生成参数类型，如果返回viod，生成BOOL)
     */
    func renameFunc()  {
        validExtensions = ["h", "swift"]
        let renameFuncURLs = urls.filter { return valid($0) }
        let ocName = "-\\s*\\([a-zA-Z]+\\s*\\**\\)([a-zA-Z_]{1}\\w*\\s*:).*;+"
    }
}
