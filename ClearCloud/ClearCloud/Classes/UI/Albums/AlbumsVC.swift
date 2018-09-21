//
//  AlbumsVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

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
        if defaults.object(forKey: "trial") == nil {
            defaults.set(true, forKey: "trial")
            defaults.synchronize()
            let uuid = UUID().uuidString
            let username = "\(uuid)@iphone.babblelabs.com"
            let base64 = uuid.base64Encoded()
            let hash = base64!.data(using: .utf8)?.sha256()
            let password = hash!.hexEncodedString()
            LoginManager.shared.storeUsername(username: username)
            LoginManager.shared.storePassword(password: password)
        }

        
        LoginManager.shared.checkRegistration { (status:LoginManager.LoginStatus, error:String?) in
            switch status {
            case .success:
                print("HERE 1")
            case .error:
                break
            case .notLoggedIn:
                break
            }
        }

    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.loadAlbums()
                } else {
                    print("NOT AUTH")
                }
            })
        } else if (photos == .authorized) {
            self.loadAlbums()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadAlbums() {
        
        print("loadAlbums")
        
        self.albums.removeAll()
        let fetchOptions = PHFetchOptions()
        
        let smartAlbums:PHFetchResult<PHCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: fetchOptions) as! PHFetchResult<PHCollection>
        
        let topLevelfetchOptions = PHFetchOptions()
        
        
//        let fetchResult : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: fetchOptions)

        
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: topLevelfetchOptions)
        
        
        
        
        let allAlbums = [topLevelUserCollections, smartAlbums]
        print("allAlbums \(allAlbums)")

        for i in 0 ..< allAlbums.count {
            let result = allAlbums[i]
            
            result.enumerateObjects { (asset, index, stop) -> Void in
                if let a = asset as? PHAssetCollection {
                    let opts = PHFetchOptions()
                    
                    if #available(iOS 9.0, *) {
                        opts.fetchLimit = 1
                    }
                    
                    let ass = PHAsset.fetchAssets(in: a, options: opts)
                    if let _ = ass.firstObject {
                        
                        print("GOT ASSET \(a.localizedTitle)")
                        let album = Album()
                        album.asset = a
                        album.name = a.localizedTitle
                        album.type = .video
                        self.albums.append(album)
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
        return UIEdgeInsetsMake(0, 0, 0, 0)
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
        print("width =\(width)")
        
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
