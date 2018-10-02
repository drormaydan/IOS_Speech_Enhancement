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
    
    @objc func clickBack(sender:UIButton?) {
        self.navigationController!.popViewController(animated: true)
    }
    
    @objc func clickMenu(sender:UIButton?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.sideMenuController.toggleLeftMenu()
    }
    
    
    func showHud() {
        DispatchQueue.main.async {
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = NSLocalizedString("Loading", comment: "")
        }
    }
    
    func showHud(message:String) {
        DispatchQueue.main.async {
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = message
        }
    }
    
    
    func hideHud() {
        DispatchQueue.main.async {
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        }
    }
    
    func showError(message:String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
        
        // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
        let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func doEnhance(_ asset:CCAsset, album:Album, completion:@escaping ((Bool, String?) -> Void)) {
        if asset.type == .audio {
            self.showHud()
            if let audio = asset.audio {
                let filemgr = FileManager.default
                let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                let docsDir = dirPaths.first!
                let newDir = docsDir.appendingPathComponent(audio.unique_id!)
                
                let audiourl2 = newDir.appendingPathComponent("enhanced.mp3")
                
                let path = asset.audio!.local_audio_path
                let url = docsDir.appendingPathComponent(path!)
                
                
                BabbleLabsApi.shared.convertAudio(filepath: url.path, email: LoginManager.shared.getUsername()!, destination: audiourl2) { (success:Bool, error:ServerError? ) in
                    self.hideHud()
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
                
                self.showHud()
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
                        let videourl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).mp4")
                        let testurl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(uuid).mov")

                        
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

                            
                        }

                        

                        
                        print("BEFORE WRITE AUDIO")

                        /*
                        self.extractAudio(aVideoAsset: avAsset, outputUrl: savePathUrl, completion: { (success:Bool, err:String?) in
                            
                            if success {
                            BabbleLabsApi.shared.convertAudio(filepath: audiourl.path, email: LoginManager.shared.getUsername()!, destination: audiourl2) { (success:Bool, error:ServerError? ) in
                                self.hideHud()
                                print("POST SUCCESS \(success) error \(error)")
                                if (success) {
                                    
                                    self.mergeFilesWithUrl(aVideoAsset: avAsset, audioUrl: audiourl2, outputUrl: videourl, completion: { (success:Bool, error:String?) in
                                        
                                        
                                        PHPhotoLibrary.shared().performChanges({
                                            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videourl);
                                            let assetPlaceholder = assetRequest!.placeholderForCreatedAsset
                                            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album.asset!)
                                            albumChangeRequest!.addAssets([assetPlaceholder!] as NSFastEnumeration)
                                            
                                        }, completionHandler: { success, error in
                                            print("added enhanced video to album")
                                            print(error)
                                            if success {
                                                
                                                let fetchOptions = PHFetchOptions()
                                                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                
                                                // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                
                                                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                try! realm.write {
                                                    enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                    print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                }
                                                completion(true,nil)
                                            } else {
                                                completion(false,error?.localizedDescription)
                                            }
                                            
                                        })
                                        
                                        
                                    })
                                    
                                    
                                    /*
                                     DispatchQueue.main.async {
                                     let realm = try! Realm()
                                     try! realm.write {
                                     audio.enhanced_audio_path = audiourl2.path.replacingOccurrences(of: docsDir.path, with: "")
                                     }
                                     
                                     }*/
                                    
                                } else {
                                    
                                }
                            }
                            
                            
                            
                            } else {
                                self.hideHud()
                                completion(false,err)
                            }
                            
                            
                            
                        })*/
                        
                        
                        avAsset.writeAudioTrack(to: audiourl, success: {
                            print("WROTE AUDIO \(audiourl)")
                            
                            BabbleLabsApi.shared.convertAudio(filepath: audiourl.path, email: LoginManager.shared.getUsername()!, destination: audiourl2) { (success:Bool, error:ServerError? ) in
                                self.hideHud()
                                print("POST SUCCESS \(success) error \(error)")
                                if (success) {
                                    
                                    self.mergeFilesWithUrl(aVideoAsset: avAsset, audioUrl: audiourl2, outputUrl: videourl, completion: { (success:Bool, error:String?) in
                                        
                                        
                                        PHPhotoLibrary.shared().performChanges({
                                            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videourl);
                                            let assetPlaceholder = assetRequest!.placeholderForCreatedAsset
                                            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album.asset!)
                                            albumChangeRequest!.addAssets([assetPlaceholder!] as NSFastEnumeration)

                                        }, completionHandler: { success, error in
                                            print("added enhanced video to album")
                                            print(error)
                                            if success {
                                                
                                                let fetchOptions = PHFetchOptions()
                                                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                
                                                // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                
                                                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                try! realm.write {
                                                    enhancedVideo!.enhanced_video_id = fetchResult?.localIdentifier
                                                    print("UPDATED ENHANCED VIDEO ID -->\(enhancedVideo!.enhanced_video_id)")
                                                }
                                                completion(true,nil)
                                            } else {
                                                completion(false,error?.localizedDescription)
                                            }
                                            
                                        })

                                        
                                    })
                                    
                                    
                                    /*
                                    DispatchQueue.main.async {
                                        let realm = try! Realm()
                                        try! realm.write {
                                            audio.enhanced_audio_path = audiourl2.path.replacingOccurrences(of: docsDir.path, with: "")
                                        }

                                    }*/
                                    
                                } else {
                                    
                                }
                            }

                            
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
    
    
    
    
    func extractAudio(aVideoAsset:AVAsset, outputUrl:URL, completion:@escaping ((Bool, String?) -> Void)) {
        let mixComposition : AVMutableComposition = AVMutableComposition()
       // var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
       // let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        
        //start merge
        
        
       // mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let aAudioAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.audio)[0]
        print("aAudioAssetTrack \(aAudioAssetTrack)")

        let compositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try compositionTrack?.insertTimeRange(aAudioAssetTrack.timeRange, of: aAudioAssetTrack, at: aAudioAssetTrack.timeRange.start)
        } catch {
            print("ZZZZZ \(error)")
        }
        
        
        print("compositionTrack \(aAudioAssetTrack)")

        //compositionTrack!.preferredTransform = aAudioAssetTrack.preferredTransform

        
        
       // let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        /*
        
        do{
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aAudioAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            
        }catch{
            print("zzError info: \(error)")
            
        }*/
        
        //totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,aAudioAssetTrack.timeRange.duration )
        
        //let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        //mutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        
       // mutableVideoComposition.renderSize = CGSize(width: aVideoAssetTrack.naturalSize.width, height: aVideoAssetTrack.naturalSize.height)
        
        //        playerItem = AVPlayerItem(asset: mixComposition)
        //        player = AVPlayer(playerItem: playerItem!)
        //
        //
        //        AVPlayerVC.player = player
        
        
        
        //find your video on this URl
        //let savePathUrl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        print("mixComposition \(mixComposition)")

        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A)!
        assetExport.outputFileType = AVFileType.m4a
        assetExport.outputURL = outputUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        print("HERE 11")
        
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

    
    
    func mergeFilesWithUrl(aVideoAsset:AVAsset, audioUrl:URL, outputUrl:URL, completion:@escaping ((Bool, String?) -> Void)) {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        
        //start merge
        
        //let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset : AVAsset = AVAsset(url: audioUrl)
        print("aVideoAsset \(aVideoAsset) aAudioAsset \(aAudioAsset)")

        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
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
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,aVideoAssetTrack.timeRange.duration )
        
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        
        mutableVideoComposition.renderSize = CGSize(width: aVideoAssetTrack.naturalSize.width, height: aVideoAssetTrack.naturalSize.height)
        
        //        playerItem = AVPlayerItem(asset: mixComposition)
        //        player = AVPlayer(playerItem: playerItem!)
        //
        //
        //        AVPlayerVC.player = player
        
        
        
        //find your video on this URl
        //let savePathUrl : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = outputUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        print("HERE 11")

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
