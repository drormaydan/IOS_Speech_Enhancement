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
import AudioKit

class AudioCaptureVC: CCViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    var timer:Timer?
    var timerCount:Int = 0
    var startRecordingTime: Date?
    var isRecording:Bool = false
    var album:Album!
    var endTime:Date? = nil
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    @IBOutlet private weak var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setLogoImage()
        self.navigationController?.navigationBar.isTranslucent = false
        recordButton.makeRounded()
        makeBackButton2()
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        if FileManager.default.fileExists(atPath: audioFilename.path) {
            do {
                try FileManager.default.removeItem(atPath: audioFilename.path)
            }
            catch {
                print("Could not remove file at url: \(audioFilename)")
            }
        }
        

    }
    
    func makeBackButton2() {
        let buttonBack: UIButton = UIButton(type: UIButtonType.custom) as UIButton
        buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40) // CGFloat, Double, Int
        buttonBack.setImage(#imageLiteral(resourceName: "baseline_arrow_back_ios_black_24pt"), for: UIControlState.normal)
        buttonBack.addTarget(self, action: #selector(clickBack2(sender:)), for: UIControlEvents.touchUpInside)
        
        let rightBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: buttonBack)
        // self.navigationItem.setLeftBarButton(rightBarButtonItem, animated: false)
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -13
        navigationItem.leftBarButtonItems = [negativeSpacer,rightBarButtonItem]
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        reset()
    }
    
    
    @objc func clickBack2(sender:UIButton?) {
        print("CLICKBACK")
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
        let attr = try FileManager.default.attributesOfItem(atPath: audioFilename.path)
        let fileSize = attr[FileAttributeKey.size] as! UInt64
        print("CLICKBACK fileSize \(fileSize)")
        } catch {
        print("Could not remove file at url: \(audioFilename)")
        }
        
        if FileManager.default.fileExists(atPath: audioFilename.path) {
            self.showError(message: "Please either save or delete the audio.")
        } else {
            self.navigationController!.popViewController(animated: true)
        }
    }
    
    func reset() {
        
        self.deleteButton.isHidden = true
        self.okButton.isHidden = true
        
        self.recordingSession = AVAudioSession.sharedInstance()
        self.timeLabel.isHidden = true
        self.timeLabel.text = "00:00:00"
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
        //audio.name = "Untitled"
        
        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths.first!
        let newDir = docsDir.appendingPathComponent(audio.unique_id!)
        let audiourl = newDir.appendingPathComponent("audio.m4a")
        // let testaudiourl = newDir.appendingPathComponent("caf")
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        
        do {
            try filemgr.createDirectory(atPath: newDir.path,
                                        withIntermediateDirectories: true, attributes: nil)
            print("CREATED DIR \(newDir)")
            
            try filemgr.copyItem(at: audioFilename, to: audiourl)
            print("COPIED AUDIO TO \(audiourl)")
            
            audio.local_audio_path = audiourl.path.replacingOccurrences(of: docsDir.path, with: "")
            print("FINAL AUDIO PATH \(audio.local_audio_path!)")
            
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
                print("audio \(audio.local_audio_path!) fileSize \(fileSize)")
                audio.audio_size = Double(fileSize)
                
                let userCalendar = Calendar.current
                let requestedComponent: Set<Calendar.Component> = [.hour,.minute,.second]
                let timeDifference = userCalendar.dateComponents(requestedComponent, from: startRecordingTime!, to: endTime!)
                audio.duration = timeDifference.second! + (timeDifference.minute!*60) + (timeDifference.hour!*3600)
            } catch {
                print("audio Error: \(error)")
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
            
            self.navigationController!.popViewController(animated: true)
            
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
    
    func convertAudio(_ url: URL, outputURL: URL) {
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
        
        dstFormat.mSampleRate = 44100  //Set sample rate
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
        
        // reset
        reset()
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
        endTime = Date()
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
