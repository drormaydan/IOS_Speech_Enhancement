//
//  AlbumsVC.swift
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
import CryptoSwift

class AlbumsVC: CCViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var albums:[Album] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        makeMenuButton()
        setLogoImage()
        
        collectionView.register(AlbumCell.self, forCellWithReuseIdentifier: "ALBUM_CELL")
        collectionView.register(UINib(nibName: "AlbumCell", bundle:nil), forCellWithReuseIdentifier: "ALBUM_CELL")
        collectionView.backgroundColor = UIColor.clear
        collectionView.backgroundView = nil
        
        
        let defaults: UserDefaults = UserDefaults.standard
        let did_trial = defaults.bool(forKey: "did_trial")
        if !did_trial {
            if defaults.object(forKey: "trial") == nil {
                defaults.set(true, forKey: "trial")
                defaults.synchronize()
                let uuid = UUID().uuidString
                let username = "\(uuid)@iphone.babblelabs.com"
                let base64 = uuid.base64Encoded()
                let hash = base64!.data(using: .utf8)?.sha256()
                let password = hash!.hexEncodedString()
                let defaults: UserDefaults = UserDefaults.standard
                defaults.set(username, forKey: "trial_username")
                defaults.synchronize()
                LoginManager.shared.storeUsername(username: username)
                LoginManager.shared.storePassword(password: password)
            }
        }
        
        LoginManager.shared.checkRegistration { (status:LoginManager.LoginStatus, error:String?) in
            switch status {
            case .success:
                NotificationCenter.default.post(name:Notification.Name(rawValue:"LoginNotification"),
                                                object: nil,
                                                userInfo: nil)
                break
            case .error:
                //defaults.set(false, forKey: "trial")
                //defaults.synchronize()
                
                let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                
                break
            case .notLoggedIn:
                if !self.showed_login {
                    self.showed_login = true
                    let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                    let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                }
                break
            }
        }
        
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"RefreshMain"),
                                               object:nil, queue:nil,
                                               using:catchNotification)
        
    }
    
    func catchNotification(notification: Notification) -> Void {
        DispatchQueue.main.async {
            self.reload()
        }
    }
    
    func openLogin() {
        let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
        let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
    }
    
    var showed_login = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func reload() {
        
        if (UserDefaults.standard.object(forKey: "showed_info") == nil) {
            UserDefaults.standard.set(true, forKey: "showed_info")
            UserDefaults.standard.synchronize()
            let albumsVC:PermissionsInfoVC = PermissionsInfoVC(nibName: "PermissionsInfoVC", bundle: nil)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.sideMenuController.present(albumsVC, animated: true, completion: nil)
            
            return
        }
        
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    DispatchQueue.main.async {
                        self.loadAlbums()
                    }
                } else {
                    print("NOT AUTH")
                }
            })
        } else if (photos == .authorized) {
            DispatchQueue.main.async {
                self.loadAlbums()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var showed_tutorial = false
    
    func loadAlbums() {
        print("LOAD ALBUMS")
        if !showed_tutorial &&  (UserDefaults.standard.object(forKey: "showed_tutorial") == nil) {
            showed_tutorial = true
            let albumsVC:TutorialVC = TutorialVC(nibName: "TutorialVC", bundle: nil)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.sideMenuController.present(albumsVC, animated: true, completion: nil)
        }
        
        self.albums.removeAll()
        
        let album = Album()
        album.name = "Audio Files"
        album.type = .audio
        self.albums.append(album)
        
        let fetchOptions = PHFetchOptions()
        
        let smartAlbums:PHFetchResult<PHCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: fetchOptions) as! PHFetchResult<PHCollection>
        let smartAlbums2:PHFetchResult<PHCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions) as! PHFetchResult<PHCollection>
        let smartAlbums3:PHFetchResult<PHCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: fetchOptions) as! PHFetchResult<PHCollection>
        
        let topLevelfetchOptions = PHFetchOptions()
        
        
        //        let fetchResult : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: fetchOptions)
        
        
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: topLevelfetchOptions)
        
        
        
        
        let allAlbums = [topLevelUserCollections, smartAlbums, smartAlbums2, smartAlbums3]
        //print("allAlbums \(allAlbums)")
        
        for i in 0 ..< allAlbums.count {
            let result = allAlbums[i]
            
            result.enumerateObjects { (asset, index, stop) -> Void in
                if let a = asset as? PHAssetCollection {
                    let opts = PHFetchOptions()
                    
                    if #available(iOS 9.0, *) {
                        opts.fetchLimit = 1
                    }
                    
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
                    let result:PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: a, options: fetchOptions)
                    if result.count > 0 {
                        
                        
                        let ass = PHAsset.fetchAssets(in: a, options: opts)
                        if let _ = ass.firstObject {
                            
                            //print("GOT ASSET \(a.localizedTitle)")
                            let album = Album()
                            album.asset = a
                            album.name = a.localizedTitle
                            album.type = .video
                            self.albums.append(album)
                        }
                    }
                }
                
                if i == (allAlbums.count - 1) && index == (result.count - 1) {
                    
                    self.albums.sort(by: { (a, b) -> Bool in
                        return a.name! < b.name!
                    })
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    
    
    // MARK: - CollectionView
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: AlbumCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALBUM_CELL", for: indexPath) as! AlbumCell
        cell.album = self.albums[indexPath.row]
        cell.populate()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        let detailVC:AlbumDetailVC = AlbumDetailVC(nibName: "AlbumDetailVC", bundle: nil)
        detailVC.album = self.albums[indexPath.row]
        self.navigationController!.pushViewController(detailVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        
        
        let width = ((screenSize.width-20)/2)-10
        //print("width =\(width)")
        
        return CGSize(width: width, height: width-12+12+59)
    }
    
}
extension String {
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
