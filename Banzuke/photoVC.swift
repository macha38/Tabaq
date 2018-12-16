//
//  photoVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/8/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import Photos

class photoVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate {
    
    let manager = PHImageManager()
    var photoArrays = [PHAsset]()

    // GeoPoint setting
    let geomanager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Confirm location authorize setting
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            geomanager.requestWhenInUseAuthorization()
        }

        // Photo authorize
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.loadPhotoes()
            }
        }
    }

    @IBAction func cancel_clicked(_ sender: Any) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadPhotoes() {
        
        // Sort option
        let sortop = PHFetchOptions()
        sortop.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: sortop)
        let indexSet = IndexSet(integersIn: 0...result.count - 1)
        let loadedPhotos = result.objects(at: indexSet)
        photoArrays = loadedPhotos
        DispatchQueue.main.sync {
            collectionView?.reloadData()
        }
    }
    
    // MARK: - Navigation
    // TODO: Cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width : CGFloat = (self.view.frame.size.width - 3) / 4
        let height = width
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArrays.count
    }

    // Cell config
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Configure the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! pictureCell

        let asset = photoArrays[indexPath.item]
        let width = (collectionView.bounds.size.width - 2) / 3
        manager.requestImage(for: asset, targetSize: CGSize(width: width, height: width), contentMode: .aspectFill, options: nil) { (result, info) in
            if let image = result {
                cell.picImg.image = image
            }
        }
        
        return cell
    }
    
    // TODO: Go uploadVC
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let asset = photoArrays[indexPath.item]
        let manager = PHImageManager()
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) {
            (result, info) in
            if let image = result {
                
                let uploadVC = self.storyboard?.instantiateViewController(withIdentifier: "uploadVC") as! uploadVC

                // Extract location
                let coordinate = asset.location?.coordinate
                if coordinate != nil {
                    uploadVC.photoData.photoLocation = PFGeoPoint(latitude: coordinate!.latitude, longitude: coordinate!.longitude)
                }
                uploadVC.photoData.photoImage = image
                
                self.navigationController?.pushViewController(uploadVC, animated: true)
            }
        }
    }
    
}
