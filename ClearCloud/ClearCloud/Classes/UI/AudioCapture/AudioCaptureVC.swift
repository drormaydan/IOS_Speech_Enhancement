//
//  AudioCaptureVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import RealmSwift

class AudioCaptureVC: CCViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    var timer:Timer?
    var timerCount:Int = 0
    var startRecordingTime: Date?
    var isRecording:Bool = false
    var album:Album!

    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    @IBOutlet private weak var recordButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setLogoImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.deleteButton.isHidden = true
        self.okButton.isHidden = true

        recordingSession = AVAudioSession.sharedInstance()
        self.timeLabel.isHidden = true

        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
    }

    func cleanup() {
        print("CLEANUP AUDIO")
        if self.timer != nil {
            self.timer!.invalidate()
            self.timer = nil
        }
        audioRecorder?.stop()
    }
    
    
    @IBAction func clickSave(_ sender: Any) {

        let audio = CCAudio()
        audio.unique_id = NSUUID().uuidString
        audio.local_time_start = startRecordingTime
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd-HH:mm:ss"
        audio.name = "Untitled"

        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths.first!
        let newDir = docsDir.appendingPathComponent(audio.unique_id!)
        
        let audiourl = newDir.appendingPathComponent("audio.m4a")
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        
        do {
            try filemgr.createDirectory(atPath: newDir.path,
                                        withIntermediateDirectories: true, attributes: nil)
            print("CREATED DIR \(newDir)")
            
            try filemgr.copyItem(at: audioFilename, to: audiourl)
            print("COPIED AUDIO TO \(audiourl)")
            
            audio.local_audio_path = audiourl.path.replacingOccurrences(of: docsDir.path, with: "")
            print("FINAL AUDIO PATH \(audio.local_audio_path!)")
            
            
            do {
                let attr = try filemgr.attributesOfItem(atPath: audiourl.path)
                let fileSize = attr[FileAttributeKey.size] as! UInt64
                print("audio \(audio.local_audio_path!) fileSize \(fileSize)")
                audio.audio_size = Double(fileSize)
            } catch {
                print("audio Error: \(error)")
            }
            
            
            DispatchQueue.main.async {
                let realm = try! Realm()
                try! realm.write {
                    realm.add(audio)
                }
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
            let alertController = UIAlertController(title:NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
            let okAction = UIAlertAction(title:NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        



/*
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: audioFilename)
        }) { saved, error in
            if (error != nil) {
                print("error \(error!.localizedDescription)")
            }
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
*/
    }
    
    @IBAction func clickDelete(_ sender: Any) {
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        // delete old file
        if FileManager.default.fileExists(atPath: audioFilename.path) {
            do {
                try FileManager.default.removeItem(atPath: audioFilename.path)
            }
            catch {
                print("Could not remove file at url: \(audioFilename)")
            }
        }

    }
    
    @IBAction func clickRecordButton(_ recordButton: UIButton?) {
        if (isRecording) {
            finishRecording(success: true)
            
            
        } else {
            let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.record()
                
                self.timeLabel.isHidden = false

                
                timerCount = 0
                startRecordingTime = Date.init()
                
                if (!self.isRecording) {
                    // start timer
                    if self.timer != nil {
                        self.timer!.invalidate()
                        self.timer = nil
                    }
                    self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
                }
                
                self.isRecording = true
                
            } catch {
                finishRecording(success: false)
            }
            
            
        }
    }
    @objc func timerUpdate() {
        
        
        let userCalendar = Calendar.current
        let requestedComponent: Set<Calendar.Component> = [.hour,.minute,.second]
        let timeDifference = userCalendar.dateComponents(requestedComponent, from: startRecordingTime!, to: Date.init())
        self.timeLabel.text = "\(String(format: "%02d", timeDifference.hour!)):\(String(format: "%02d", timeDifference.minute!)):\(String(format: "%02d", timeDifference.second!))"
        
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.isRecording = false
        self.recordButton.isEnabled = true
        self.timeLabel.isHidden = true

        if self.timer != nil {
            self.timer!.invalidate()
            self.timer = nil
        }

        if (flag) {
            
            self.deleteButton.isHidden = false
            self.okButton.isHidden = false

            /*
            let filemgr = FileManager.default
            let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
            do {
                let attr = try filemgr.attributesOfItem(atPath: audioFilename.path)
                let fileSize = attr[FileAttributeKey.size] as! UInt64
                print("audio \(audioFilename) fileSize \(fileSize)")
            } catch {
                print("audio Error: \(error)")
            }*/


          
        } else {
            // TODO
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

}
