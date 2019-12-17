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
    func testFindAllFilesSuccess() {
        do {
           let result = try Obfuscation().findAllFiles(in: testURL)
            assert(result.count > 0, "该目录下没有任何文件")
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
    }
    
    func testFindAllFilesFailure() {
        do {
            let result = try Obfuscation().findAllFiles(in: "aaa")
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
    
    func testNoteRegs() {
        let source = """
//
        //  AppDelegate.swift
        //  ForAD
        //
        //  Created by 储诚鹏 on 2019/12/2.
        //  Copyright © 2019 储诚鹏. All rights reserved.
        //
/**/
abc
123
/****************/
/*
*/
/*
abc
*/
/* abc----*/
//// for aa
        import UIKit

        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {



            func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                // Override point for customization after application launch.
                return true
            }

            // MARK: UISceneSession Lifecycle

            func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
                // Called when a new scene session is being created.
                // Use this method to select a configuration to create the new scene with.
                return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            }

            func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
                // Called when the user discards a scene session.
                // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
                // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
            }


        }
"""
        let rlt = try? source.reg(pattern: .notesReg)
        print(rlt)
        

    }
    
    

}
