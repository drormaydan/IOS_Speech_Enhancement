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
import AVFoundation
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sideMenuController: PGSideMenu!
    let albumsVC:AlbumsVC = AlbumsVC(nibName: "AlbumsVC", bundle: nil)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // disable logging
        //NetworkActivityLogger.shared.level = .debug
        //NetworkActivityLogger.shared.startLogging()

        IQKeyboardManager.shared.enable = true
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = UIColor.black
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
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

        FBSDKApplicationDelegate.sharedInstance()?.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        Fabric.with([Crashlytics.self])
        return true
    }

    // MARK: - Handle File Sharing
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
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
    
    let appGroupID = "group.com.babblelabs.clearcloud"
    var containerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
    }

    func handleSharedItems() {
        print("handleSharedItems")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: containerURL.path) {
            for item in contents {
                print("item \(item)")
                if item.hasSuffix("mp4") {
                    let path = "\(containerURL.path)/\(item)"
                    let url = URL(fileURLWithPath: path)
                    let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/rewrite.m4a")
                    
                    if FileManager.default.fileExists(atPath: audiourl2.path) {
                        do {
                            try FileManager.default.removeItem(atPath: audiourl2.path)
                        }
                        catch {
                            print("Could not remove file at url: \(audiourl2)")
                        }
                    }
                    
                    print("ORIGINAL VIDEO \(url)")
                    
                    
                    self.rewriteAudioFile(audioUrl: url, outputUrl: audiourl2, completion: { (success:Bool, error:String?) in
                        if success {
                            print("REWROTE VIDEO TO \(audiourl2)")
                            self.processAudio(audioFilename: audiourl2)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshMain"), object: nil, userInfo: nil)
                        }
                    })

                    
                    deleteFile(path)

                } else if item.hasSuffix("m4a") {
                    let path = "\(containerURL.path)/\(item)"
                    let url = URL(fileURLWithPath: path)
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
                    
                    
                    self.rewriteAudioFile(audioUrl: url, outputUrl: audiourl2, completion: { (success:Bool, error:String?) in
                        if success {
                            print("REWROTE AUDIO TO \(audiourl2)")
                            self.processAudio(audioFilename: audiourl2)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshMain"), object: nil, userInfo: nil)
                        }
                    })
                    deleteFile(path)
                }
            }
        }
    }
    func processAudio(audioFilename:URL) {
           let audio = CCAudio()
           audio.unique_id = NSUUID().uuidString
           audio.local_time_start = Date()
           let formatter = DateFormatter()
           formatter.dateFormat = "MMM-dd-HH:mm:ss"
           //audio.name = "Untitled"
           
           
           let filemgr = FileManager.default
           let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
           let docsDir = dirPaths.first!
           let newDir = docsDir.appendingPathComponent(audio.unique_id!)
           let audiourl = newDir.appendingPathComponent("audio.m4a")
           // let testaudiourl = newDir.appendingPathComponent("caf")
           
          // let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
           
           
           do {
               try filemgr.createDirectory(atPath: newDir.path,
                                           withIntermediateDirectories: true, attributes: nil)
               //print("CREATED DIR \(newDir)")
               
               try filemgr.copyItem(at: audioFilename, to: audiourl)
               //print("COPIED AUDIO TO \(audiourl)")
               
               audio.local_audio_path = audiourl.path.replacingOccurrences(of: docsDir.path, with: "")
               //print("FINAL AUDIO PATH \(audio.local_audio_path!)")
               
               /*
                // test
                var options = AKConverter.Options()
                options.format = "caf"
                options.sampleRate = 22500
                options.channels = UInt32(1)
                let br = UInt32(16)
                options.bitRate = br * 1_000
                let converter = AKConverter(inputURL: audiourl, outputURL: testaudiourl, options: options)
                converter.start(completionHandler: { error in
                if let error = error {
                AKLog("Error during convertion: \(error)")
                } else {
                AKLog("Conversion Complete! \(testaudiourl)")
                }
                })*/
               
               
               do {
                   let attr = try filemgr.attributesOfItem(atPath: audiourl.path)
                   let fileSize = attr[FileAttributeKey.size] as! UInt64
                   //print("audio \(audio.local_audio_path!) fileSize \(fileSize)")
                   audio.audio_size = Double(fileSize)
                   
                   let aAudioAsset : AVAsset = AVURLAsset(url: audiourl)

                   
                  // let userCalendar = Calendar.current
                  // let requestedComponent: Set<Calendar.Component> = [.hour,.minute,.second]
                  // let timeDifference = userCalendar.dateComponents(requestedComponent, from: audio.local_time_start!, to: endTime!)
                   audio.duration = Int(CMTimeGetSeconds(aAudioAsset.duration))
               } catch {
                   //print("audio Error: \(error)")
               }
               
               
               let realm = try! Realm()
               try! realm.write {
                   realm.add(audio)
               }
               
               // delete old file
               if FileManager.default.fileExists(atPath: audioFilename.path) {
                   do {
                       try FileManager.default.removeItem(atPath: audioFilename.path)
                   }
                   catch {
                       //print("Could not remove file at url: \(audioFilename)")
                   }
               }
               
               
           } catch let error as NSError {
               print("ERROR \(error)")
               /*
               let alertController = UIAlertController(title:NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
               let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
               alertController.addAction(okAction)
               self.present(alertController, animated: true, completion: nil)
               */
           }
           
       
       }
    
    func rewriteAudioFile(audioUrl:URL, outputUrl:URL, completion:@escaping ((Bool, String?) -> Void)) {
          let mixComposition : AVMutableComposition = AVMutableComposition()
          var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
          //let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
          
          //start merge
          
          //let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
          let aAudioAsset : AVAsset = AVURLAsset(url: audioUrl)
          
          //print("aAudioAsset.tracks \(aAudioAsset.tracks)")
          
          mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
          
          
          if (aAudioAsset.tracks(withMediaType: AVMediaType.audio).count == 0) {
              // no audio file
              completion(false,"Sorry, there was a problem enhancing the file. Please try again.")
              return
          }
          
          let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
          
          
          do{
              
              //In my case my audio file is longer then video file so i took videoAsset duration
              //instead of audioAsset duration
              
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aAudioAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
              
              //Use this instead above line if your audiofile and video file's playing durations are same
              
              //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
              
          }catch{
              //print("zzasdadsError info: \(error)")
              completion(false,error.localizedDescription)
              return
          }
          
          let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A)!
          assetExport.outputFileType = AVFileType.m4a
          assetExport.outputURL = outputUrl
          assetExport.shouldOptimizeForNetworkUse = true
          
          //print("bHERE 11")
          
          assetExport.exportAsynchronously { () -> Void in
              switch assetExport.status {
                  
              case AVAssetExportSessionStatus.completed:
                  
                  //Uncomment this if u want to store your video in asset
                  
                  //let assetsLib = ALAssetsLibrary()
                  //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
                  
                  //print("success")
                  completion(true,nil)
              case  AVAssetExportSessionStatus.failed:
                  //print("failed \(assetExport.error)")
                  completion(false,assetExport.error?.localizedDescription)
              case AVAssetExportSessionStatus.cancelled:
                  //print("cancelled \(assetExport.error)")
                  completion(false,assetExport.error?.localizedDescription)
              default:
                  //print("complete")
                  completion(true,nil)
              }
          }
      }

    
    func deleteFile(_ path: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                print("delete error \(path)")
            }
        }
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
        FBSDKAppEvents.activateApp()
        handleSharedItems()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

