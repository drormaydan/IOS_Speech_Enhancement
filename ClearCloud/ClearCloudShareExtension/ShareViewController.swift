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
import RealmSwift

class ShareViewController: SLComposeServiceViewController {

    let videoContentType = kUTTypeMovie as String
    let audioContentType = kUTTypeAudio as String
    let appGroupID = "group.com.babblelabs.clearcloud"
    var containerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        for item: Any in self.extensionContext!.inputItems {
            let inputItems = item as! NSExtensionItem
            for provider: Any in inputItems.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(videoContentType) {
                    return true
                }
                if itemProvider.hasItemConformingToTypeIdentifier(audioContentType) {
                    return true
                }

            }
        }
        return false
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        let group = DispatchGroup()

        for item: Any in self.extensionContext!.inputItems {
            let inputItems = item as! NSExtensionItem

            for provider: Any in inputItems.attachments! {
                let itemProvider = provider as! NSItemProvider
                
                if itemProvider.hasItemConformingToTypeIdentifier("public.file-url") {
                    group.enter()
                    itemProvider.loadItem(forTypeIdentifier: "public.file-url" as String, options: nil) { data, error in
                        if let url = data as? URL {
                            
                            let fileName: String = "\(ProcessInfo.processInfo.globallyUniqueString)_\(".mp4")"
                            let path = self.containerURL.appendingPathComponent(fileName).path
                            try? (try? Data(contentsOf: url))?.write(to: URL(fileURLWithPath: path), options: [.atomic])
                            group.leave()
                        } else {
                            group.leave()
                        }
                    }
                } else if itemProvider.hasItemConformingToTypeIdentifier(videoContentType) {
                    group.enter()
                    itemProvider.loadItem(forTypeIdentifier: videoContentType as String, options: nil) { data, error in
                        if let url = data as? URL {
                            let fileName: String = "\(ProcessInfo.processInfo.globallyUniqueString)_\(".mp4")"
                            let path = self.containerURL.appendingPathComponent(fileName).path
                            try? (try? Data(contentsOf: url))?.write(to: URL(fileURLWithPath: path), options: [.atomic])
                            group.leave()
                        } else {
                            group.leave()
                        }
                    }

                } else if itemProvider.hasItemConformingToTypeIdentifier(audioContentType) {
                    group.enter()
                    itemProvider.loadItem(forTypeIdentifier: audioContentType, options: nil) { data, error in
                        if let url = data as? URL {
                            let fileName: String = "\(ProcessInfo.processInfo.globallyUniqueString)_\(".m4a")"
                            let path = self.containerURL.appendingPathComponent(fileName).path
                            try? (try? Data(contentsOf: url))?.write(to: URL(fileURLWithPath: path), options: [.atomic])
                            group.leave()
                        } else {
                            group.leave()
                        }
                    }

                }
                
            }
        }
        
        group.notify(queue: .main) {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
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
          
          do {
              try filemgr.createDirectory(atPath: newDir.path,
                                          withIntermediateDirectories: true, attributes: nil)
              
              try filemgr.copyItem(at: audioFilename, to: audiourl)
              
              audio.local_audio_path = audiourl.path.replacingOccurrences(of: docsDir.path, with: "")
              
              do {
                  let attr = try filemgr.attributesOfItem(atPath: audiourl.path)
                  let fileSize = attr[FileAttributeKey.size] as! UInt64
                  audio.audio_size = Double(fileSize)
                  
                  let aAudioAsset : AVAsset = AVURLAsset(url: audiourl)
                  audio.duration = Int(CMTimeGetSeconds(aAudioAsset.duration))
              } catch {
                  print("ERROR \(error.localizedDescription)")
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
                      print("Could not remove file at url: \(audioFilename)")
                  }
              }
              
              
          } catch let error as NSError {
            print("ERROR \(error.localizedDescription)")
          }
          
      
      }
    func rewriteAudioFile(audioUrl:URL, outputUrl:URL, completion:@escaping ((Bool, String?) -> Void)) {
          let mixComposition : AVMutableComposition = AVMutableComposition()
          var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
          let aAudioAsset : AVAsset = AVURLAsset(url: audioUrl)
                    
          mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
          
          
          if (aAudioAsset.tracks(withMediaType: AVMediaType.audio).count == 0) {
              // no audio file
              completion(false,"Sorry, there was a problem enhancing the file. Please try again.")
              return
          }
          
          let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
          
          
          do{
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aAudioAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
                            
          }catch{
              //print("zzasdadsError info: \(error)")
              completion(false,error.localizedDescription)
              return
          }
          
          let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A)!
          assetExport.outputFileType = AVFileType.m4a
          assetExport.outputURL = outputUrl
          assetExport.shouldOptimizeForNetworkUse = true
          
          
          assetExport.exportAsynchronously { () -> Void in
              switch assetExport.status {
                  
              case AVAssetExportSessionStatus.completed:
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
