//
//  AppDelegate.swift
//  CCPObfuscation
//
//  Created by 储诚鹏 on 2019/12/17.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let result = try Obfuscation().deleteNotes(source: "/Users/chuchengpeng/Desktop/ForObfusion")
            assert(result, "删除注释失败")
            Obfuscation().openFinder("/Users/chuchengpeng/Desktop/ForObfusion")
        } catch  {
            assertionFailure(error.localizedDescription)
        }
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

