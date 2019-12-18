//
//  CCPObfuscationTests.swift
//  CCPObfuscationTests
//
//  Created by 储诚鹏 on 2019/12/17.
//  Copyright © 2019 储诚鹏. All rights reserved.
//

import XCTest
@testable import CCPObfuscation

class CCPObfuscationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    let testURL = "/Users/chuchengpeng/Desktop/ForObfusion"
    func testfilesSuccess() {
        do {
            let result = try Obfuscation().files(in: testURL, ignores: [], ext: .all)
            assert(result.count > 0, "该目录下没有任何文件")
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
    }
    
    func testfilesFailure() {
        do {
            let result = try Obfuscation().files(in: "aaa", ignores: [], ext: .all)
            assert(result.count > 0, "该目录下没有任何文件")
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func testDeleteNotes() {
        do {
            let result = try Obfuscation().deleteNotes(source: testURL)
            assert(result, "删除注释失败")
        } catch  {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func testNewFilesGroup() {
        do {
            _ = try Obfuscation().newFilesDocument("testFile")
        } catch  {
            assertionFailure("创建失败")
        }

    }
    
    func testIgnores() {
        do {
            let results = try Obfuscation().files(in: testURL, ignores: [.prefix("Prefix"), .suffix("Suffix"), .contains("Contains"), .document("ignore1")], ext: .all)
            assert(results.count > 0, "该目录下没有任何文件")
            for result in results {
                let path = result.deletingPathExtension().lastPathComponent
                let needIgnore = path.hasPrefix("Prefix") || path.hasSuffix("Suffix") || path.contains("Contains") || result.path.contains("ignore1/")
                assert(!needIgnore, "忽略文件失败")
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func testDeleteNotesIgnores() {
        do {
            let rlt = try Obfuscation().deleteNotes(source: testURL, ignores: [.prefix("Prefix"), .suffix("Suffix"), .contains("Contains"), .document("ignore1")])
            assert(rlt, "删除注释失败")
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    
    func testRenameClassPrefix() {
        do {
            try Obfuscation().renameClass(source: testURL, modify: .prefix("_ccp"))
        } catch  {
            assertionFailure("重命名类名失败")
        }
    }
    
    func testRenameClassSuffix() {
        do {
            try Obfuscation().renameClass(source: testURL, modify: .suffix("_ccp"))
        } catch  {
            assertionFailure("重命名类名失败")
        }
    }
    
    func testRenameClassRandom() {
        do {
            try Obfuscation().renameClass(source: testURL)
        } catch  {
            assertionFailure("重命名类名失败")
        }
    }
    
}
