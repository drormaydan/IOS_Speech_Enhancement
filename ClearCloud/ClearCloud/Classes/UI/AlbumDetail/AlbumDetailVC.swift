//
//  AlbumDetailVC.swift
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
import Photos
import RealmSwift
import MobileCoreServices

class AlbumDetailVC: CCViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var enhanceButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var album:Album!
    var assets:[CCAsset] = []
    var select_mode = false
    var total_selected = 0
    
    @IBOutlet weak var enhanceButtonView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        collectionView.register(AssetCell.self, forCellWithReuseIdentifier: "ASSET_CELL")
        collectionView.register(UINib(nibName: "AssetCell", bundle:nil), forCellWithReuseIdentifier: "ASSET_CELL")
        collectionView.backgroundColor = UIColor.clear
        collectionView.backgroundView = nil
        
        self.title = album.name
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(clickSelect))
        
        enhanceButtonView.isHidden = true
    }
    
    
    @objc func clickSelect(sender: UIButton?) {
        self.select_mode = !select_mode
        if (select_mode) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(clickSelect))
        } else {
            self.total_selected = 0
            for asset in self.assets {
                asset.selected = false
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(clickSelect))
            enhanceButtonView.isHidden = true
        }
        self.collectionView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reload()
    }
    
    func reload() {
        
        self.assets.removeAll()
        
        
        if album.type == .video {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let result:PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: self.album.asset!, options: fetchOptions)
            
            result.enumerateObjects({ (object, count, stop) in
                let ccasset = CCAsset()
                ccasset.type = .video
                ccasset.asset = object
                self.assets.append(ccasset)
            })
            
            let ccasset = CCAsset()
            ccasset.type = .add
            self.assets.append(ccasset)

            self.assets = self.assets.reversed() // sort newest first
            
            
        } else {
            let ccasset = CCAsset()
            ccasset.type = .add
            self.assets.append(ccasset)

            let realm = try! Realm()
            realm.refresh()
            let audios = realm.objects(CCAudio.self).sorted(byKeyPath: "local_time_start", ascending: false)
            //print("TOTAL AUDIOS \(audios.count)")
            for audio:CCAudio in audios {
                let ccasset = CCAsset()
                ccasset.type = .audio
                ccasset.audio = audio
                self.assets.append(ccasset)
            }
        }
        
        self.collectionView.reloadData()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    var assets_to_enhance:[CCAsset] = []
    
    @IBAction func clickEnhance(_ sender: Any) {
        self.showHud(message: "Enhancing...")
        assets_to_enhance.removeAll()
        for asset in self.assets {
            if asset.selected {
                assets_to_enhance.append(asset)
            }
        }
        self.enhanceNext()
    }
    
    func enhanceNext() {
        if self.assets_to_enhance.count == 0 {
            self.hideHud()
            self.clickSelect(sender: nil)
            
            self.reload()

        } else {
            let asset = self.assets_to_enhance.remove(at: 0)
            
            self.doEnhance(asset, album: self.album) { (success:Bool, error:String?) in
                self.enhanceNext()
            }
        }
    }
    
    // MARK: - CollectionView
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: AssetCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ASSET_CELL", for: indexPath) as! AssetCell
        cell.asset = assets[indexPath.row]
        cell.owner = self
        cell.populate()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        if assets[indexPath.row].type == .add {
            
            if (!select_mode) {
                
                if self.album.type == .video {
                    
                    
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                        //print("captureVideoPressed and camera available.")
                        
                        let imagePicker = UIImagePickerController()
                        imagePicker.videoMaximumDuration = 60000
                        imagePicker.delegate = self
                        imagePicker.sourceType = .camera
                        imagePicker.mediaTypes = [kUTTypeMovie] as [String]
                        imagePicker.allowsEditing = false
                        
                        imagePicker.showsCameraControls = true
                        
                        self.present(imagePicker, animated: true, completion: nil)
                    } else {
                        //print("Camera not available.")
                    }
                    
                    
                } else if self.album.type == .audio {
                    let detailVC:AudioCaptureVC = AudioCaptureVC(nibName: "AudioCaptureVC", bundle: nil)
                    detailVC.album = self.album
                    self.navigationController!.pushViewController(detailVC, animated: true)
                }
            }
        } else {
            
            if select_mode {
                if self.album.type == .video {
                    let realm = try! Realm()
                    let enhancedVideo = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", assets[indexPath.row].asset!.localIdentifier, assets[indexPath.row].asset!.localIdentifier).first
                    if let enhancedVideo = enhancedVideo {
                        if let enhanced_video_id = enhancedVideo.enhanced_video_id {
                            if enhanced_video_id == assets[indexPath.row].asset!.localIdentifier {
                                return;
                            }
                        }
                    }
                }
                assets[indexPath.row].selected = !assets[indexPath.row].selected
                
                if assets[indexPath.row].selected {
                    self.total_selected += 1
                } else {
                    self.total_selected -= 1
                }
                if self.total_selected > 0 {
                    if self.total_selected == 1 {
                        self.enhanceButton.setTitle("Enhance Selected File", for: .normal)
                    } else {
                        self.enhanceButton.setTitle("Enhance Selected Files", for: .normal)
                    }
                    enhanceButtonView.isHidden = false
                } else {
                    enhanceButtonView.isHidden = true
                }
                
                self.collectionView.reloadData()
            } else {
                let detailVC:ItemDetailVC = ItemDetailVC(nibName: "ItemDetailVC", bundle: nil)
                detailVC.asset = self.assets[indexPath.row]
                detailVC.album = self.album
                self.navigationController!.pushViewController(detailVC, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        
        
        let width = ((screenSize.width-20)/2)-10
        ////print("width =\(width)")
        
        return CGSize(width: width, height: width)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let videoUrl = info[UIImagePickerControllerMediaURL] as! URL
        let pathString = videoUrl.relativePath
        //print("GOT URL \(videoUrl)")
        self.dismiss(animated: true, completion: {
            
            
            self.addToAlbum(videourl: videoUrl, album: self.album!.asset!, completion: { (success:Bool, error:String?) in
                if success {
                    DispatchQueue.main.async {
                        self.reload()
                    }
                    
                    
                } else {
                    // fallback to ClearCloud album
                    
                    self.getClearCloudAlbum(completion: { (clearcloudalbum:PHAssetCollection?) in
                        
                        //print("CC ALBUM \(clearcloudalbum)")
                        self.addToAlbum(videourl: videoUrl, album: clearcloudalbum, completion: { (success:Bool, error:String?) in

                            DispatchQueue.main.async {
                                self.reload()
                            }
                        })
                        
                        
                    })
                    
                    
                }
                
            })
            
            /*
             PHPhotoLibrary.requestAuthorization { (status) in
             PHPhotoLibrary.shared().performChanges({
             let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl);
             
             
             if let asset = assetRequest?.placeholderForCreatedAsset {
             let request = PHAssetCollectionChangeRequest(for: self.album!.asset!)
             request?.addAssets([asset] as NSArray)
             }
             
             
             //let assetPlaceholder = assetRequest!.placeholderForCreatedAsset
             //let albumChangeRequest = PHAssetCollectionChangeRequest(for: album.asset!)
             //albumChangeRequest!.addAssets([assetPlaceholder!] as NSFastEnumeration)
             
             }, completionHandler: { success, error in
             //print("added new video to album")
             //print("success = \(success) error=\(error)")
             self.reload()
             })
             }*/
            
        })
    }
    
}
