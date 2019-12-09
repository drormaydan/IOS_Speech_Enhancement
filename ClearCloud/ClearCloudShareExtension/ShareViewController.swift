//
//  ShareViewController.swift
//  ClearCloudShareExtension
//
//  Created by Boris Katok on 12/8/19.
//  Copyright © 2019 Boris Katok. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import AVFoundation

class ShareViewController: SLComposeServiceViewController {

    let videoContentType = kUTTypeMovie as String
    let audioContentType = kUTTypeAudio as String

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        for item: Any in self.extensionContext!.inputItems {
            let inputItems = item as! NSExtensionItem
            for provider: Any in inputItems.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(videoContentType) {
                    print("VIDEO ITEM")
                    return true
                }
                if itemProvider.hasItemConformingToTypeIdentifier(audioContentType) {
                    print("AUDIO ITEM")
                    return true
                }

            }
        }
        return false
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        for item: Any in self.extensionContext!.inputItems {
            let inputItems = item as! NSExtensionItem
            print("inputItems \(inputItems)")
            for provider: Any in inputItems.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(videoContentType) {
                    print("1 VIDEO ITEM")
                    
                    itemProvider.loadItem(forTypeIdentifier: videoContentType, options: nil) { data, error in
                        if let url = data as? URL {
                            print("1 VIDEO ITEM \(url)")
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
                            
                            
                            rewriteAudioFile(audioUrl: url, outputUrl: audiourl2, completion: { (success:Bool, error:String?) in
                                if success {
                                    print("REWROTE AUDIO TO \(audiourl2)")
                                    processAudio(audioFilename: audiourl2)
                                   // self.albumsVC.reload()
                                }
                            })


                        }
                    }

                } else if itemProvider.hasItemConformingToTypeIdentifier(audioContentType) {
                    print("1 AUDIO ITEM zz")
                    
                    
                    itemProvider.loadItem(forTypeIdentifier: audioContentType, options: nil) { data, error in
                        print("1 AUDIO ITEM error \(error)")
                        if let url = data as? URL {
                            print("1 AUDIO ITEM \(url)")
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
                            
                            
                            rewriteAudioFile(audioUrl: url, outputUrl: audiourl2, completion: { (success:Bool, error:String?) in
                                if success {
                                    print("REWROTE AUDIO TO \(audiourl2)")
                                    processAudio(audioFilename: audiourl2)
                                   // self.albumsVC.reload()
                                }
                            })


                        } else {
                            print("1 AUDIO ITEM not URL \(data)")
                        }
                    }

                }
                
            }
        }
        
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
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
              //print("ERROR \(error)")
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
              
              try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aAudioAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)
              
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
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
