//
//  CCViewController.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import AVFoundation
import Photos
import AudioKit
import AudioToolbox
import JGProgressHUD
//import FFmpegWrapper

class CCViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func setLogoImage() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "clear_cloud")
        navigationItem.titleView = imageView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func makeBackButton() {
        let buttonBack: UIButton = UIButton(type: UIButtonType.custom) as UIButton
        buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40) // CGFloat, Double, Int
        buttonBack.setImage(#imageLiteral(resourceName: "ic_arrow_back_48pt"), for: UIControlState.normal)
        buttonBack.addTarget(self, action: #selector(clickBack(sender:)), for: UIControlEvents.touchUpInside)
        
        let rightBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: buttonBack)
        // self.navigationItem.setLeftBarButton(rightBarButtonItem, animated: false)
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -13
        navigationItem.leftBarButtonItems = [negativeSpacer,rightBarButtonItem]
        
    }
    
    func makeMenuButton() {
        let buttonBack: UIButton = UIButton(type: UIButtonType.custom) as UIButton
        buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40) // CGFloat, Double, Int
        buttonBack.setImage(#imageLiteral(resourceName: "baseline_menu_black_24pt"), for: UIControlState.normal)
        buttonBack.addTarget(self, action: #selector(clickMenu(sender:)), for: UIControlEvents.touchUpInside)
        
        let rightBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: buttonBack)
        // self.navigationItem.setLeftBarButton(rightBarButtonItem, animated: false)
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -13
        navigationItem.leftBarButtonItems = [negativeSpacer,rightBarButtonItem]
        
    }
    
    func makeCloseButton() {
        let buttonBack: UIButton = UIButton(type: UIButtonType.custom) as UIButton
        buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40) // CGFloat, Double, Int
        buttonBack.setImage(#imageLiteral(resourceName: "ic_close_48pt"), for: UIControlState.normal)
        buttonBack.addTarget(self, action: #selector(clickClose(sender:)), for: UIControlEvents.touchUpInside)
        
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -13
        
        let rightBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: buttonBack)
        navigationItem.rightBarButtonItems = [negativeSpacer, rightBarButtonItem]
        //self.navigationItem.setRightBarButton(rightBarButtonItem, animated: false)
    }
    
    @objc func clickClose(sender:UIButton?) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func clickBack(sender:UIButton?) {
        self.navigationController!.popViewController(animated: true)
    }
    
    @objc func clickMenu(sender:UIButton?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.sideMenuController.toggleLeftMenu()
    }
    
    var hud:JGProgressHUD? = nil
    
    func showHud() {
        DispatchQueue.main.async {
            
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
/*
            self.hud = JGProgressHUD(style: .dark)
            self.hud!.textLabel.text = "Loading"
            self.hud!.show(in: self.view)
*/
            
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = NSLocalizedString("Loading", comment: "")
        }
    }
    
    func showHud(message:String) {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.isUserInteractionEnabled = false

            /*
            self.hud = JGProgressHUD(style: .dark)
            self.hud!.textLabel.text = message
            self.hud!.show(in: self.view)
 */
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = message
        }
    }
    
    
    func hideHud() {
        DispatchQueue.main.async {
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            
            /*if let hud = self.hud {
                hud.dismiss()
            }*/
            self.navigationController?.navigationBar.isUserInteractionEnabled = true
        }
    }
    
    func showError(message:String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
            
            // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
            let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
        
    func doEnhance(_ asset:CCAsset, album:Album, completion:@escaping ((Bool, String?) -> Void)) {
        LoginManager.shared.checkRegistration(force: true, completion: { (status:LoginManager.LoginStatus, error:String?) in
            switch status {
            case .success:
                print("REG SUCCESS")
                self.doEnhanceImpl(asset, album: album, completion: completion)
                break
            case .error:
                print("REG ERROR")
                self.showError(message: error!)
                completion(false,nil)
                break
            case .notLoggedIn:
                print("REG NOT LOGGED")
                completion(false,nil)
                let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                break
            }
        })
    }

    func doEnhanceImpl(_ asset:CCAsset, album:Album, completion:@escaping ((Bool, String?) -> Void)) {
        if asset.type == .audio {
            if let audio = asset.audio {
                let filemgr = FileManager.default
                let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                let docsDir = dirPaths.first!
                let newDir = docsDir.appendingPathComponent(audio.unique_id!)
                
                let uuid = UUID().uuidString
                let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_enhanced.m4a")

                //let audiourl2 = newDir.appendingPathComponent("enhanced.mp3")
                
                let path = asset.audio!.local_audio_path
                let url = docsDir.appendingPathComponent(path!)
                
                print("BEFORE WEB SERVICE")
                BabbleLabsApi.shared.convertAudio(filepath: url.path, email: LoginManager.shared.getUsername()!, destination: audiourl2, video:false) { (success:Bool, error:ServerError?, trialover:Bool ) in
                    print("POST SUCCESS \(success) error \(error)")
                    if (success) {
                        DispatchQueue.main.async {
                            let realm = try! Realm()
                            try! realm.write {
                                audio.enhanced_audio_path = audiourl2.path.replacingOccurrences(of: docsDir.path, with: "")
                            }
                            completion(true,nil)
                        }
                        
                    } else {
                        if trialover {
                            
                            let alertController = UIAlertController(title: nil, message: error!.getMessage()!, preferredStyle: UIAlertControllerStyle.alert)
                            
                            let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default) {
                                (result : UIAlertAction) -> Void in
                                print("OK")
                                /*
                                let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                                let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                appDelegate.sideMenuController.present(nav, animated: true, completion: nil)*/
                            }
                            
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                            completion(false,error!.getMessage()!)
                            
                        } else {
                            completion(false,error!.getMessage()!)
                           // self.showError(message: error!.getMessage()!)
                        }
                    }
                }
            }
        } else {
            
            if let phasset = asset.asset {
                
                
                guard (phasset.mediaType == PHAssetMediaType.video)
                    
                    else {
                        print("Not a valid video media type")
                        return
                }
                
                // get persistent object
                let realm = try! Realm()
                var enhancedVideo:CCEnhancedVideo? = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", phasset.localIdentifier, phasset.localIdentifier).first
                if (enhancedVideo == nil) {
                    enhancedVideo = CCEnhancedVideo()
                    enhancedVideo?.original_video_id = phasset.localIdentifier
                    try! realm.write {
                        realm.add(enhancedVideo!)
                    }
                }
                
                let uuid = UUID().uuidString
                
                print("BEFORE REQUEST ASSET")
                PHCachingImageManager().requestAVAsset(forVideo: phasset, options: nil, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                    if let avAsset = asset {
                        
                        // get sample rate
                        
                        let aAudioAssetTrack : AVAssetTrack = avAsset.tracks(withMediaType: AVMediaType.audio)[0]
                        let desc = aAudioAssetTrack.formatDescriptions[0] as! CMAudioFormatDescription
                        let basic = CMAudioFormatDescriptionGetStreamBasicDescription(desc)
                        let sample_rate = basic!.pointee.mSampleRate
                        print("SAMPLE RATE \(sample_rate)")

                        let filemgr = FileManager.default
                        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                        let docsDir = dirPaths.first!
                        let newDir = docsDir.appendingPathComponent(uuid)
                       // let audiourl = newDir.appendingPathComponent("audio.m4a")
                       // print("audiourl \(audiourl)")

                        //let testurl = URL(fileURLWithPath: audiourl.path)
                        //print("testurl \(testurl)")

                        let audiourl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).m4a")
                        print("audiourl \(audiourl)")

                        //let audiourl2 = newDir.appendingPathComponent("enhanced.mp3")
                        //let videourl = newDir.appendingPathComponent("final.mp4")

                        let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_enhanced.m4a")
                        let audiourl3 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_sample_enhanced.m4a")
                        let audiourl4 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_mooved_enhanced.m4a")
                        let audiourlwav : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_enhanced.aif")
                        let videourl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).mov")
                        let testurl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).mov")
                        let wavurl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).aif")

                        /*
                        if let avassetURL = avAsset as? AVURLAsset {
                            
                            guard let video = try? Data(contentsOf: avassetURL.url) else {
                                return
                            }
                            
                          //  asds
                            
                            do {
                                try video.write(to: testurl)
                            } catch {
                                print("ZZZZZ \(error)")
                            }

                            
                        }*/

                        

                        
                        print("BEFORE WRITE AUDIO")

            
                        
                        
                        avAsset.writeAudioTrack(to: audiourl, success: {
                            print("WROTE AUDIO \(audiourl)")
                            
                            
                            BabbleLabsApi.shared.convertAudio(filepath: audiourl.path, email: LoginManager.shared.getUsername()!, destination: audiourl2, video:true) { (success:Bool, error:ServerError?, trialover:Bool ) in
                                print("POST SUCCESS \(success) error \(error)")
                                if (success) {
                                    
                                    print("ENHANCED AUDIO \(audiourl2)")

                                    
                                    do {
                                        let resources = try audiourl2.resourceValues(forKeys:[.fileSizeKey])
                                        let fileSize = resources.fileSize!
                                        print ("ENHANCED AUDIO SIZE \(fileSize)")
                                    } catch {
                                        print("Error: \(error)")
                                    }
                                    
                                    
                                    
                                    self.convertAudioSamplerate(audiourl2, outputURL: audiourl3, sample_rate: sample_rate, completion: { (success:Bool, error:String?) in
                                        
                                        if success {
                                            
                                            // move the atom
                                            self.rewriteAudioFile(audioUrl: audiourl3, outputUrl: audiourl4, completion: { (success:Bool, error:String?) in
                                                if success {
                                                    
                                                    
                                                    self.mergeFilesWithUrl(aVideoAsset: avAsset, audioUrl: audiourl4, outputUrl: videourl, sampleRate: sample_rate, completion: { (success:Bool, error:String?) in
                                                        
                                                        print("DONE MERGE \(videourl)")
                                                        
                                                        DispatchQueue.main.async {
                                                            print("ADD ALBUM \(album.asset!)")
                                                            
                                                            
                                                            self.addToAlbum(videourl: videourl, album: album.asset!, completion: { (suc:Bool, err:String?) in
                                                                if suc {
                                                                    DispatchQueue.main.async {
                                                                        let fetchOptions = PHFetchOptions()
                                                                        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                                        
                                                                        // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                                        
                                                                        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                                        let realm = try! Realm()
                                                                        try! realm.write {
                                                                            enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                                            print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                                        }
                                                                        completion(true,nil)
                                                                    }
                                                                    
                                                                    
                                                                } else {
                                                                    // fallback to ClearCloud album
                                                                    
                                                                    self.getClearCloudAlbum(completion: { (clearcloudalbum:PHAssetCollection?) in
                                                                        
                                                                        print("CC ALBUM \(clearcloudalbum)")
                                                                        self.addToAlbum(videourl: videourl, album: clearcloudalbum, completion: { (suc:Bool, err:String?) in
                                                                            
                                                                            if suc {
                                                                                DispatchQueue.main.async {
                                                                                    let fetchOptions = PHFetchOptions()
                                                                                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                                                    
                                                                                    // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                                                    
                                                                                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                                                    let realm = try! Realm()
                                                                                    try! realm.write {
                                                                                        enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                                                        print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                                                    }
                                                                                    completion(true,nil)
                                                                                }
                                                                                
                                                                            } else {
                                                                                completion(false,err)
                                                                                
                                                                            }
                                                                        })
                                                                        
                                                                        
                                                                    })
                                                                    
                                                                    
                                                                }
                                                            })
                                                            
                                                            
                                                            
                                                        }
                                                        
                                                    })
                                                    
                                                    ////
                                                } else {
                                                    completion(false,error)
                                                }
                                                
                                            })
                                            
                                        } else {
                                            completion(false,error)
                                        }
                                    })

                                    
                                    
                                    
                                } else {
                                    if trialover {
                                        
                                        let alertController = UIAlertController(title: nil, message: error!.getMessage()!, preferredStyle: UIAlertControllerStyle.alert)
                                        
                                        let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default) {
                                            (result : UIAlertAction) -> Void in
                                            print("OK")
                                            let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                                            let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                            appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                                        }
                                        
                                        alertController.addAction(okAction)
                                        self.present(alertController, animated: true, completion: nil)
                                        completion(false,error!.getMessage()!)

                                        
                                    } else {
                                        self.showError(message: error!.getMessage()!)
                                        completion(false,error!.getMessage()!)
                                    }

                                }
                            }
 
                            
                            
                            
                            // convert to AIF
                            /*
                            var options = AKConverter.Options()
                            options.format = "aif"
                            options.sampleRate = 22500
                            options.channels = UInt32(1)
                            let br = UInt32(16)
                            options.bitRate = br * 1_000

                            let converter = AKConverter(inputURL: audiourl, outputURL: wavurl, options: options)
                            converter.start(completionHandler: { (error:Error?) in
                                if let error = error {
                                    AKLog("Error during convertion: \(error)")
                                } else {
                                    AKLog("Conversion 1 Complete!")
                                    
                                   // BabbleLabsApi.shared.convertAudio(filepath: audiourl.path, email: LoginManager.shared.getUsername()!, destination: audiourl2) { (success:Bool, error:ServerError? ) in

                                    BabbleLabsApi.shared.convertAudio(filepath: wavurl.path, email: LoginManager.shared.getUsername()!, destination: audiourlwav) { (success:Bool, error:ServerError? ) in
                                        print("POST SUCCESS \(success) error \(error)")
                                        if (success) {
                                            
                                            
                                            
                                            
                                            self.mergeFilesWithUrl(aVideoAsset: avAsset, audioUrl: audiourlwav, outputUrl: videourl, completion: { (success:Bool, error:String?) in
                                             
                                                print("DONE MERGE \(videourl)")

                                                DispatchQueue.main.async {
                                                    print("ADD ALBUM \(album.asset!)")

                                                    
                                                    self.addToAlbum(videourl: videourl, album: album.asset!, completion: { (suc:Bool, err:String?) in
                                                        if suc {
                                                            DispatchQueue.main.async {
                                                                let fetchOptions = PHFetchOptions()
                                                                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                                
                                                                // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                                
                                                                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                                let realm = try! Realm()
                                                                try! realm.write {
                                                                    enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                                    print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                                }
                                                                completion(true,nil)
                                                            }

                                                            
                                                        } else {
                                                            // fallback to ClearCloud album
                                                            
                                                            self.getClearCloudAlbum(completion: { (clearcloudalbum:PHAssetCollection?) in
                                                                
                                                                print("CC ALBUM \(clearcloudalbum)")
                                                                self.addToAlbum(videourl: videourl, album: clearcloudalbum, completion: { (suc:Bool, err:String?) in
                                                                    
                                                                    if suc {
                                                                        DispatchQueue.main.async {
                                                                            let fetchOptions = PHFetchOptions()
                                                                            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                                            
                                                                            // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                                            
                                                                            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                                            let realm = try! Realm()
                                                                            try! realm.write {
                                                                                enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                                                print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                                            }
                                                                            completion(true,nil)
                                                                        }

                                                                    } else {
                                                                        completion(false,err)

                                                                    }
                                                                })
                                                                
                                                                
                                                            })
                                                            
                                                            
                                                        }
                                                    })


                                                    

                                                }
                                                
                                            })
                                            
                                        } else {
                                            
                                        }
                                    }
                                    
                                    
                                    
                                }
                            })
                            
                            */
                            
                    

                            
                        }) { (error) in
                            print(error.localizedDescription)
                        }
                        
                    }
                })
                
                
                
            } else {
                
                completion(false,"error")
            }
        }
        
        
    }
    
    
    func doEnhanceImplTest(_ asset:CCAsset, album:Album, completion:@escaping ((Bool, String?) -> Void)) {
        if asset.type == .audio {
            if let audio = asset.audio {
                let filemgr = FileManager.default
                let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                let docsDir = dirPaths.first!
                let newDir = docsDir.appendingPathComponent(audio.unique_id!)
                
                let uuid = UUID().uuidString
                let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_enhanced.m4a")
                
                //let audiourl2 = newDir.appendingPathComponent("enhanced.mp3")
                
                let path = asset.audio!.local_audio_path
                let url = docsDir.appendingPathComponent(path!)
                
                
                BabbleLabsApi.shared.convertAudio(filepath: url.path, email: LoginManager.shared.getUsername()!, destination: audiourl2, video:false) { (success:Bool, error:ServerError?, trialover:Bool ) in
                    print("POST SUCCESS \(success) error \(error)")
                    if (success) {
                        DispatchQueue.main.async {
                            let realm = try! Realm()
                            try! realm.write {
                                audio.enhanced_audio_path = audiourl2.path.replacingOccurrences(of: docsDir.path, with: "")
                            }
                            completion(true,nil)
                        }
                        
                    } else {
                        if trialover {
                            
                            let alertController = UIAlertController(title: nil, message: error!.getMessage()!, preferredStyle: UIAlertControllerStyle.alert)
                            
                            let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default) {
                                (result : UIAlertAction) -> Void in
                                print("OK")
                                let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                                let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                            }
                            
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                            completion(false,error!.getMessage()!)
                            
                        } else {
                            completion(false,error!.getMessage()!)
                            self.showError(message: error!.getMessage()!)
                        }
                    }
                }
            }
        } else {
            
            if let phasset = asset.asset {
                
                
                guard (phasset.mediaType == PHAssetMediaType.video)
                    
                    else {
                        print("Not a valid video media type")
                        return
                }
                
                // get persistent object
                let realm = try! Realm()
                var enhancedVideo:CCEnhancedVideo? = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", phasset.localIdentifier, phasset.localIdentifier).first
                if (enhancedVideo == nil) {
                    enhancedVideo = CCEnhancedVideo()
                    enhancedVideo?.original_video_id = phasset.localIdentifier
                    try! realm.write {
                        realm.add(enhancedVideo!)
                    }
                }
                
                let uuid = UUID().uuidString
                
                print("BEFORE REQUEST ASSET")
                PHCachingImageManager().requestAVAsset(forVideo: phasset, options: nil, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                    if let avAsset = asset {
                        
                        let filemgr = FileManager.default
                        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                        let docsDir = dirPaths.first!
                        let newDir = docsDir.appendingPathComponent(uuid)
                        // let audiourl = newDir.appendingPathComponent("audio.m4a")
                        // print("audiourl \(audiourl)")
                        
                        //let testurl = URL(fileURLWithPath: audiourl.path)
                        //print("testurl \(testurl)")
                        
                        let audiourl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).m4a")
                        print("audiourl \(audiourl)")
                        
                        //let audiourl2 = newDir.appendingPathComponent("enhanced.mp3")
                        //let videourl = newDir.appendingPathComponent("final.mp4")
                        
                        let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_enhanced.m4a")
                        let audiourlwav : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid)_enhanced.aif")
                        let videourl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).mov")
                        let testurl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).mov")
                        let wavurl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).aif")
                        
                        /*
                         if let avassetURL = avAsset as? AVURLAsset {
                         
                         guard let video = try? Data(contentsOf: avassetURL.url) else {
                         return
                         }
                         
                         //  asds
                         
                         do {
                         try video.write(to: testurl)
                         } catch {
                         print("ZZZZZ \(error)")
                         }
                         
                         
                         }*/
                        
                        
                        
                        
                        print("BEFORE WRITE AUDIO")
                        
                        
                        
                        
                        avAsset.writeAudioTrack(to: audiourl, success: {
                            print("WROTE AUDIO \(audiourl)")
                            
                            
                            
                            
                            self.mergeFilesWithUrl(aVideoAsset: avAsset, audioUrl: audiourl, outputUrl: videourl, sampleRate:0, completion: { (success:Bool, error:String?) in
                                
                                print("DONE MERGE \(videourl)")
                                
                                DispatchQueue.main.async {
                                    print("ADD ALBUM \(album.asset!)")
                                    
                                    
                                    self.addToAlbum(videourl: videourl, album: album.asset!, completion: { (suc:Bool, err:String?) in
                                        if suc {
                                            DispatchQueue.main.async {
                                                let fetchOptions = PHFetchOptions()
                                                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                
                                                // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                
                                                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                let realm = try! Realm()
                                                try! realm.write {
                                                    enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                    print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                }
                                                completion(true,nil)
                                            }
                                            
                                            
                                        } else {
                                            // fallback to ClearCloud album
                                            
                                            self.getClearCloudAlbum(completion: { (clearcloudalbum:PHAssetCollection?) in
                                                
                                                print("CC ALBUM \(clearcloudalbum)")
                                                self.addToAlbum(videourl: videourl, album: clearcloudalbum, completion: { (suc:Bool, err:String?) in
                                                    
                                                    if suc {
                                                        DispatchQueue.main.async {
                                                            let fetchOptions = PHFetchOptions()
                                                            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                            
                                                            // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                            
                                                            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                            let realm = try! Realm()
                                                            try! realm.write {
                                                                enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                                print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                            }
                                                            completion(true,nil)
                                                        }
                                                        
                                                    } else {
                                                        completion(false,err)
                                                        
                                                    }
                                                })
                                                
                                                
                                            })
                                            
                                            
                                        }
                                    })
                                    
                                    
                                    
                                }
                                
                            })
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            /*
                            
                            BabbleLabsApi.shared.convertAudio(filepath: audiourl.path, email: LoginManager.shared.getUsername()!, destination: audiourl2, video:true) { (success:Bool, error:ServerError?, trialover:Bool ) in
                                print("POST SUCCESS \(success) error \(error)")
                                if (success) {
                                    
                                    print("ENHANCED AUDIO \(audiourl2)")
                                    
                                    
                                    do {
                                        let resources = try audiourl2.resourceValues(forKeys:[.fileSizeKey])
                                        let fileSize = resources.fileSize!
                                        print ("ENHANCED AUDIO SIZE \(fileSize)")
                                    } catch {
                                        print("Error: \(error)")
                                    }
                                    

                                    
                                } else {
                                    if trialover {
                                        
                                        let alertController = UIAlertController(title: nil, message: error!.getMessage()!, preferredStyle: UIAlertControllerStyle.alert)
                                        
                                        let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default) {
                                            (result : UIAlertAction) -> Void in
                                            print("OK")
                                            let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                                            let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                            appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                                        }
                                        
                                        alertController.addAction(okAction)
                                        self.present(alertController, animated: true, completion: nil)
                                        completion(false,error!.getMessage()!)
                                        
                                        
                                    } else {
                                        self.showError(message: error!.getMessage()!)
                                        completion(false,error!.getMessage()!)
                                    }
                                    
                                }
                            }*/
                            
                            
                            
                            
                            // convert to AIF
                            /*
                             var options = AKConverter.Options()
                             options.format = "aif"
                             options.sampleRate = 22500
                             options.channels = UInt32(1)
                             let br = UInt32(16)
                             options.bitRate = br * 1_000
                             
                             let converter = AKConverter(inputURL: audiourl, outputURL: wavurl, options: options)
                             converter.start(completionHandler: { (error:Error?) in
                             if let error = error {
                             AKLog("Error during convertion: \(error)")
                             } else {
                             AKLog("Conversion 1 Complete!")
                             
                             // BabbleLabsApi.shared.convertAudio(filepath: audiourl.path, email: LoginManager.shared.getUsername()!, destination: audiourl2) { (success:Bool, error:ServerError? ) in
                             
                             BabbleLabsApi.shared.convertAudio(filepath: wavurl.path, email: LoginManager.shared.getUsername()!, destination: audiourlwav) { (success:Bool, error:ServerError? ) in
                             print("POST SUCCESS \(success) error \(error)")
                             if (success) {
                             
                             
                             
                             
                             self.mergeFilesWithUrl(aVideoAsset: avAsset, audioUrl: audiourlwav, outputUrl: videourl, completion: { (success:Bool, error:String?) in
                             
                             print("DONE MERGE \(videourl)")
                             
                             DispatchQueue.main.async {
                             print("ADD ALBUM \(album.asset!)")
                             
                             
                             self.addToAlbum(videourl: videourl, album: album.asset!, completion: { (suc:Bool, err:String?) in
                             if suc {
                             DispatchQueue.main.async {
                             let fetchOptions = PHFetchOptions()
                             fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                             
                             // After uploading we fetch the PHAsset for most recent video and then get its current location url
                             
                             let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                             let realm = try! Realm()
                             try! realm.write {
                             enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                             print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                             }
                             completion(true,nil)
                             }
                             
                             
                             } else {
                             // fallback to ClearCloud album
                             
                             self.getClearCloudAlbum(completion: { (clearcloudalbum:PHAssetCollection?) in
                             
                             print("CC ALBUM \(clearcloudalbum)")
                             self.addToAlbum(videourl: videourl, album: clearcloudalbum, completion: { (suc:Bool, err:String?) in
                             
                             if suc {
                             DispatchQueue.main.async {
                             let fetchOptions = PHFetchOptions()
                             fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                             
                             // After uploading we fetch the PHAsset for most recent video and then get its current location url
                             
                             let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                             let realm = try! Realm()
                             try! realm.write {
                             enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                             print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                             }
                             completion(true,nil)
                             }
                             
                             } else {
                             completion(false,err)
                             
                             }
                             })
                             
                             
                             })
                             
                             
                             }
                             })
                             
                             
                             
                             
                             }
                             
                             })
                             
                             } else {
                             
                             }
                             }
                             
                             
                             
                             }
                             })
                             
                             */
                            
                            
                            
                            
                        }) { (error) in
                            print(error.localizedDescription)
                        }
                        
                    }
                })
                
                
                
            } else {
                
                completion(false,"error")
            }
        }
        
        
    }
    
    func addToAlbum(videourl:URL, album:PHAssetCollection!, completion:@escaping ((Bool, String?) -> Void)) {
        PHPhotoLibrary.requestAuthorization { (status) in
            PHPhotoLibrary.shared().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videourl);
                
                
                if let asset = assetRequest?.placeholderForCreatedAsset {
                    let request = PHAssetCollectionChangeRequest(for: album)
                    request?.addAssets([asset] as NSArray)
                }
                
                
                //let assetPlaceholder = assetRequest!.placeholderForCreatedAsset
                //let albumChangeRequest = PHAssetCollectionChangeRequest(for: album.asset!)
                //albumChangeRequest!.addAssets([assetPlaceholder!] as NSFastEnumeration)
                
            }, completionHandler: { success, error in
                print("try added video to album \(album) success = \(success) error=\(error)")
                if success {
                    completion(true,nil)
                
                } else {
                    print("success = \(success) error=\(error!.localizedDescription)")
                    
                    
                    
                    completion(false,error?.localizedDescription)
                }
                
            })
            
        }
    }
    
    func orientation(forTrack asset: AVAsset?) -> UIInterfaceOrientation {
        let videoTrack: AVAssetTrack? = asset?.tracks(withMediaType: .video)[0]
        let size: CGSize? = videoTrack?.naturalSize
        let txf: CGAffineTransform? = videoTrack?.preferredTransform
        
        if size?.width == txf?.tx && size?.height == txf?.ty {
            return .landscapeRight
        } else if txf?.tx == 0 && txf?.ty == 0 {
            return .landscapeLeft
        } else if txf?.tx == 0 && txf?.ty == size?.width {
            return .portraitUpsideDown
        } else {
            return .portrait
        }
    }

    
    func getClearCloudAlbum(completion:@escaping ((PHAssetCollection?) -> Void)) {
        let albumName = "ClearCloud"
        var album:PHAssetCollection? = nil
        
        //Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let first_Obj:AnyObject = collection.firstObject{
            //found the album
            album = (first_Obj as! PHAssetCollection)
            completion(album)
        }else{
            //Album placeholder for the asset collection, used to reference collection in completion handler
            var albumPlaceholder:PHObjectPlaceholder!
            //create the folder
            NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                albumPlaceholder = request.placeholderForCreatedAssetCollection
            },
                                                   completionHandler: {(success:Bool, error:Error!)in
                                                    if(success){
                                                        print("Successfully created folder")
                                                        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                                                        if let first_Obj:AnyObject = collection.firstObject{
                                                            //found the album
                                                            album = (first_Obj as! PHAssetCollection)
                                                            completion(album)
                                                        } else {
                                                            completion(nil)
                                                        }
                                                        /*
                                                        let collection = PHAssetCollection.fetchAssetCollections(with: [albumPlaceholder.localIdentifier], subtype: nil){
                                                            album = collection.firstObject as! PHAssetCollection
                                                            completion(album)
                                                        }*/
                                                    }else{
                                                        print("Error creating folder")
                                                        completion(nil)
                                                    }
            })
            
        }
        
    }
    
    

    // MARK: - Rotate Video to Original Orientation
    
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        }
        else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 &&  transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        }
        else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0  {
            assetOrientation = .up
        }
        else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform( assetTrack.preferredTransform.concatenating( scaleFactor), at: kCMTimeZero)
            
        }
        else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(M_PI))
                let windowBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: kCMTimeZero)
        }
        
        return instruction
    }
    
    
    func convertAudioSamplerate(_ audiourl: URL, outputURL: URL, sample_rate:Double, completion:@escaping ((Bool, String?) -> Void)) {
        var options = AKConverter.Options()
        options.format = "m4a"
        options.sampleRate = sample_rate
        options.channels = UInt32(1)
        let br = UInt32(16)
        options.bitRate = br * 1_000
        let converter = AKConverter(inputURL: audiourl, outputURL: outputURL, options: options)
        converter.start(completionHandler: { error in
            if let error = error {
                AKLog("Error during convertion: \(error)")
                completion(false,error.localizedDescription)
            } else {
                AKLog("Conversion Complete! \(outputURL)")
                completion(true,nil)
            }
        })
    }
    
    func convertAudioSamplerate2(_ url: URL, outputURL: URL, sample_rate:Double) {
        var error : OSStatus = noErr
        var destinationFile: ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil
        
        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        ExtAudioFileOpenURL(url as CFURL, &sourceFile)
        
        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))
        
        ExtAudioFileGetProperty(sourceFile!,
                                kExtAudioFileProperty_FileDataFormat,
                                &thePropertySize, &srcFormat)
        
        dstFormat.mSampleRate = sample_rate  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked |
        kAudioFormatFlagIsSignedInteger
        
        // Create destination file
        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            kAudioFileWAVEType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        print("Error 1 in convertAudio: \(error.description)")
        
        error = ExtAudioFileSetProperty(sourceFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        print("Error 2 in convertAudio: \(error.description)")
        
        error = ExtAudioFileSetProperty(destinationFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        print("Error 3 in convertAudio: \(error.description)")
        
        let bufferByteSize : UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        var sourceFrameOffset : ULONG = 0
        
        while(true){
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 2,
                    mDataByteSize: UInt32(srcBuffer.count),
                    mData: &srcBuffer
                )
            )
            var numFrames : UInt32 = 0
            
            if(dstFormat.mBytesPerFrame > 0){
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }
            
            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            print("Error 4 in convertAudio: \(error.description)")
            
            if(numFrames == 0){
                error = noErr;
                break;
            }
            
            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            print("Error 5 in convertAudio: \(error.description)")
        }
        
        error = ExtAudioFileDispose(destinationFile!)
        print("Error 6 in convertAudio: \(error.description)")
        error = ExtAudioFileDispose(sourceFile!)
        print("Error 7 in convertAudio: \(error.description)")
    }
    
    
    func mergeFilesWithUrl(aVideoAsset:AVAsset, audioUrl:URL, outputUrl:URL, sampleRate:Double, completion:@escaping ((Bool, String?) -> Void)) {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        let orientation = self.orientation(forTrack: aVideoAsset)
        let is_portrait = (orientation == .portrait) || (orientation == .portraitUpsideDown)
        print("IS PORTRAIT \(is_portrait)");
        
        //start merge
        
        //let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset : AVAsset = AVURLAsset(url: audioUrl)
        print("aVideoAsset \(aVideoAsset) aAudioAsset \(aAudioAsset)")
        print("aAudioAsset.tracks \(aAudioAsset.tracks)")

        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        print("audio duration \(aAudioAssetTrack.timeRange.duration) video duration \(aVideoAssetTrack.timeRange.duration)")

        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: kCMTimeZero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            
        }catch{
            print("zzError info: \(error)")

        }
        
        // =========> VERY IMPORTANT -- fixes orientation of video
        mutableCompositionVideoTrack[0].preferredTransform = aVideoAssetTrack.preferredTransform
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,aVideoAssetTrack.timeRange.duration )
        
        let firstTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        do {
            try firstTrack!.insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAsset.duration), of: aVideoAsset.tracks(withMediaType: AVMediaType.video)[0], at: kCMTimeZero)
        }
        catch _ {
            print("Failed to load first track")
        }
        
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mov
        assetExport.outputURL = outputUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        print("aHERE 11")

        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSessionStatus.completed:
                
                //Uncomment this if u want to store your video in asset
                
                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
                
                print("success")
                completion(true,nil)
            case  AVAssetExportSessionStatus.failed:
                print("failed \(assetExport.error)")
                completion(false,assetExport.error?.localizedDescription)
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(assetExport.error)")
                completion(false,assetExport.error?.localizedDescription)
            default:
                print("complete")
                completion(true,nil)
            }
        }
        
        
    }
    
    
    func rewriteAudioFile(audioUrl:URL, outputUrl:URL, completion:@escaping ((Bool, String?) -> Void)) {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        //let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        //start merge
        
        //let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset : AVAsset = AVURLAsset(url: audioUrl)
        
        print("aAudioAsset.tracks \(aAudioAsset.tracks)")
        
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        
        do{
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aAudioAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            
        }catch{
            print("zzasdadsError info: \(error)")
            completion(false,error.localizedDescription)
            return
        }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A)!
        assetExport.outputFileType = AVFileType.m4a
        assetExport.outputURL = outputUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        print("bHERE 11")
        
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSessionStatus.completed:
                
                //Uncomment this if u want to store your video in asset
                
                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
                
                print("success")
                completion(true,nil)
            case  AVAssetExportSessionStatus.failed:
                print("failed \(assetExport.error)")
                completion(false,assetExport.error?.localizedDescription)
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(assetExport.error)")
                completion(false,assetExport.error?.localizedDescription)
            default:
                print("complete")
                completion(true,nil)
            }
        }
    }
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }

}
extension UIView{
    
    func boundInside(superView: UIView){
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutFormatOptions.directionLeadingToTrailing, metrics:nil, views:["subview":self]))
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: NSLayoutFormatOptions.directionLeadingToTrailing, metrics:nil, views:["subview":self]))
        
        
    }
}
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        assert(hex[hex.startIndex] == "#", "Expected hex string of format #RRGGBB")
        
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1  // skip #
        
        var rgb: UInt32 = 0
        scanner.scanHexInt32(&rgb)
        
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16)/255.0,
            green: CGFloat((rgb &   0xFF00) >>  8)/255.0,
            blue:  CGFloat((rgb &     0xFF)      )/255.0,
            alpha: alpha)
    }
}
extension UIView {
    func makeRounded() {
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.height/2
        self.clipsToBounds = true
    }
}
