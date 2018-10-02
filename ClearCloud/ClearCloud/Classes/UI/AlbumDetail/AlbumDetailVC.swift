//
//  AlbumDetailVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import Photos
import RealmSwift

class AlbumDetailVC: CCViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    var album:Album!
    var assets:[CCAsset] = []
    var select_mode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        collectionView.register(AssetCell.self, forCellWithReuseIdentifier: "ASSET_CELL")
        collectionView.register(UINib(nibName: "AssetCell", bundle:nil), forCellWithReuseIdentifier: "ASSET_CELL")
        collectionView.backgroundColor = UIColor.clear
        collectionView.backgroundView = nil
        
        self.title = album.name
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(clickSelect))

        
    }
    
    
    @objc func clickSelect(sender: UIButton?) {
        self.select_mode = !select_mode
        if (select_mode) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(clickSelect))
        } else {
            for asset in self.assets {
                asset.selected = false
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(clickSelect))
        }
        self.collectionView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.assets.removeAll()
        
        let ccasset = CCAsset()
        ccasset.type = .add
        self.assets.append(ccasset)
        
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
            
            self.collectionView.reloadData()
            
        } else {
            let realm = try! Realm()
            let audios = realm.objects(CCAudio.self).sorted(byKeyPath: "local_time_start", ascending: false)
            for audio:CCAudio in audios {
                let ccasset = CCAsset()
                ccasset.type = .audio
                ccasset.audio = audio
                self.assets.append(ccasset)
            }
            self.collectionView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            

            if self.album.type == .video {
                
            } else if self.album.type == .audio {
                let detailVC:AudioCaptureVC = AudioCaptureVC(nibName: "AudioCaptureVC", bundle: nil)
                detailVC.album = self.album
                self.navigationController!.pushViewController(detailVC, animated: true)
            }
        } else {
            
            if select_mode {
                assets[indexPath.row].selected = !assets[indexPath.row].selected
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
        print("width =\(width)")
        
        return CGSize(width: width, height: width)
    }



}
