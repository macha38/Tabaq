//
//  cameraVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/8/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import Photos
//import AVFoundation

class cameraVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Photo location
    var photolocation : PFGeoPoint!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

//        // Call image picker
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            
//            let picker = UIImagePickerController()
//            picker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
//            picker.delegate = self
//            picker.sourceType = .camera
//            picker.allowsEditing = true
//            
//            self.present(picker, animated: true, completion: nil)
//        }

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) {
            self.tabBarController?.selectedIndex = 0
            self.removeFromParentViewController()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Extract location
        let coordinate = (info[UIImagePickerControllerPHAsset] as? PHAsset)?.location?.coordinate
        if coordinate != nil {
            photolocation = PFGeoPoint(latitude: coordinate!.latitude, longitude: coordinate!.longitude)
        }
        
        // Store image
//        picImg.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)

    }
    
}
