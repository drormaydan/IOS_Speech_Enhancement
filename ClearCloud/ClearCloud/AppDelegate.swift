//
//  AppDelegate.swift
//  ClearCloud
//
/*
 * Copyright (c) 2018 by BabbleLabs, Inc.  ALL RIGHTS RESERVED.
 * These coded instructions, statements, and computer programs are the
 * copyrighted works and confidential proprietary information of BabbleLabs, Inc.
 * They may not be modified, copied, reproduced, distributed, or disclosed to
 * third parties in any manner, medium, or form, in whole or in part, without
 * the prior written consent of BabbleLabs, Inc.
 */

import UIKit
import PGSideMenu
import AlamofireNetworkActivityLogger
import IQKeyboardManagerSwift
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sideMenuController: PGSideMenu!
    let albumsVC:AlbumsVC = AlbumsVC(nibName: "AlbumsVC", bundle: nil)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // disable logging
        NetworkActivityLogger.shared.level = .debug
        NetworkActivityLogger.shared.startLogging()

        IQKeyboardManager.shared.enable = true
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = UIColor.black
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.black]
        UINavigationBar.appearance().isOpaque = true
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = UIColor.black
        
        
        let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
        
        let leftMenuVC:LeftNavVC = LeftNavVC(nibName: "LeftNavVC", bundle: nil)

        sideMenuController = PGSideMenu(animationType: .slideOver)
        let contentController = nav
        let leftMenuController = leftMenuVC

        sideMenuController.addContentController(contentController)
        sideMenuController.addLeftMenuController(leftMenuController)
        sideMenuController.enableMenuPanGesture = false
        
        self.window?.rootViewController = sideMenuController

        self.window!.makeKeyAndVisible()

        Fabric.with([Crashlytics.self])
        return true
    }

    // MARK: - Handle File Sharing
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // 1
        print("IMPORT URL \(url)")
        
        if url.absoluteString.lowercased() == "clearcloud://" {
        
        } else if url.absoluteString.lowercased() == "clearcloudlogin://" {
            self.albumsVC.openLogin()
        } else {
            
            guard url.pathExtension == "m4a" else { return false }
            
            
            
            let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/rewrite.m4a")
            
            if FileManager.default.fileExists(atPath: audiourl2.path) {
                do {
                    try FileManager.default.removeItem(atPath: audiourl2.path)
                }
                catch {
                    print("Could not remove file at url: \(audiourl2)")
                }
            }
            
            print("ORIGINAL AUDIO \(url)")
            
            let vc = CCViewController()
            
            vc.rewriteAudioFile(audioUrl: url, outputUrl: audiourl2, completion: { (success:Bool, error:String?) in
                if success {
                    print("REWROTE AUDIO TO \(audiourl2)")
                    AudioCaptureVC.processAudio(audioFilename: audiourl2)
                    self.albumsVC.reload()
                }
            })
            
            
        }

        /*
        // 2
        Beer.importData(from: url)
        
        // 3
        guard let navigationController = window?.rootViewController as? UINavigationController,
            let beerTableViewController = navigationController.viewControllers.first as? BeersTableViewController else {
                return true
        }
        
        // 4
        beerTableViewController.tableView.reloadData()*/
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

