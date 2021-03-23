//
//  AppDelegate.swift
//  Destini
//
//  Created by Philipp Muellauer on 01/09/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //一番最初に呼び出されるmethod(viewDidLoad()より前)
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }

    //appが終わろうとする時に発火するmehtod,ホームボタンをダブルクリックしてアプリを上にスワイプさせて終了した時(can be user-triggerd or system-triggerd)
    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }

    // MARK: - Core Data stack
    //persistentContainer: dataの保存場所（SQLite database）
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: K.dataModelName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {

                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    //appが終了する時，dataの保存をsupportするメソッド
    func saveContext () {
        let context = persistentContainer.viewContext//保存されたデータの変更
        if context.hasChanges {//変更があった場合
            do {
                try context.save()//変更を保存
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

