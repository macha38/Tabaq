//
//  uploadVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 3/20/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD
import Photos

class uploadVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UI objects
    @IBOutlet weak var picImg: UIImageView!
    @IBOutlet weak var titleTxt: UITextView!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var removeBtn: UIButton!
    
    // Photo location
    var photolocation : PFGeoPoint!
    
    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable publish btn
        publishBtn.isEnabled = false
        publishBtn.backgroundColor = .lightGray
        // Hide remove button
        removeBtn.isHidden = true
        // Standard UI containt
        picImg.image = UIImage(named: "graysquare.png")
        // Reset text
        titleTxt.text = ""
        
        // Declare hide keyboard tap
        let hideTap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
        hideTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)
        
        // Declare image view tap
        let picTap = UITapGestureRecognizer(target: self, action: #selector(selectImg))
        picTap.numberOfTapsRequired = 1
        picImg.isUserInteractionEnabled = true
        picImg.addGestureRecognizer(picTap)
    }
    
    // Preload func
    override func viewWillAppear(_ animated: Bool) {
        alignment()
    }
    
    // Click publish button
    @IBAction func publishBtn_clicked(_ sender: Any) {
        
        // Dissmiss keyboard
        self.view.endEditing(true)
        
        // Send data to server to "posts" class in Parse
        let object = PFObject(className: "posts")
        object["uuid"] = "\(PFUser.current()!.objectId!)\(NSUUID().uuidString)"
        object["user"] = PFUser.current()!
        
        if titleTxt.text.isEmpty {
            object["title"] = ""
        } else {
            object["title"] = titleTxt.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        // Send pic to server after converting to File and conpression
        let imageData = UIImageJPEGRepresentation(picImg.image!, 0.5)
        let imageFile = PFFile(name: "post.jpg", data: imageData!)
        object["pic"] = imageFile
        
        object["location"] = photolocation
        object["lkcnt"] = 0
        
        // Finally save information
        SVProgressHUD.show()
        object.saveInBackground {
            (success, error) in
            SVProgressHUD.dismiss()
            if error == nil {
                
                // Send #hashtag to server
                let commentUuid = "\(PFUser.current()!.objectId!)\(NSUUID().uuidString)"
                let words:[String] = self.titleTxt.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                // Define tagged word
                for var word in words {
                    // Save #hashtag in server
                    if word.hasPrefix("#") {
                        // Cut symbol
                        word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                        word = word.trimmingCharacters(in: CharacterSet.symbols)
                        
                        let hashtagObj = PFObject(className: "hashtags")
                        hashtagObj["postuuid"] = object["uuid"]
                        hashtagObj["by"] = PFUser.current()
                        hashtagObj["commentuuid"] = commentUuid
                        hashtagObj["hashtag"] = word.lowercased()
                        hashtagObj["postspt"] = object  // Pointer to posts
                        hashtagObj.saveInBackground{
                            (success, error) in
                            if success {
                                print("hashtag \(word) is created")
                            } else {
                                print(error!.localizedDescription)
                            }
                        }
                    }
                }
                
                // Send notification with name "uploaded"
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:"uploaded"), object: nil)
                // Switch to another ViewController at 0 index of tabbar
                self.tabBarController?.selectedIndex = 0
                // Reset everything
                self.viewDidLoad()
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    // Alignment
    func alignment() {
        // Get screen width
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        
        // Actual screen height removing status bar and navigation bar
//        let actualHeight = self.view.frame.size.height - UIApplication.shared.statusBarFrame.height - (self.navigationController?.navigationBar.frame.size.height)! - self.tabBarController!.tabBar.frame.size.height
        
        picImg.frame = CGRect(x: 15, y: 50, width: width / 4.5, height: width / 4.5)
        titleTxt.frame = CGRect(x: picImg.frame.size.width + 25, y: picImg.frame.origin.y, width: width / 1.488, height: picImg.frame.size.height)
        publishBtn.frame = CGRect(x: 0, y: height / 1.09, width: width, height: width / 8)
        removeBtn.frame = CGRect(x: picImg.frame.origin.x, y: picImg.frame.origin.y + picImg.frame.size.height, width: picImg.frame.size.width, height: 20)
    }

    // Hide keyboard function
    @objc func hideKeyboardTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // Select image
    @objc func selectImg(recognizer: UITapGestureRecognizer) {

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true

        // Confirm to access to photo library
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (PHAuthorizationStatus) in
                self.present(picker, animated: true, completion: nil)
            }
        } else {
            present(picker, animated: true, completion: nil)
        }
    }
    // Connect selected image to ou ImageView
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        // Extract location
        let coordinate = (info[UIImagePickerControllerPHAsset] as? PHAsset)?.location?.coordinate
        photolocation = PFGeoPoint(latitude: coordinate!.latitude, longitude: coordinate!.longitude)
    
        // Store image
        picImg.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)

        // Enable publish button
        publishBtn.isEnabled = true
        publishBtn.backgroundColor = UIColor(red: 52.0/255.0, green: 169.0/255.0, blue: 255.0/255.0, alpha: 1)
    
        // Unhide remove button
        removeBtn.isHidden = false
        
        // Inplement second tap for zooming image
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoomImg))
        zoomTap.numberOfTapsRequired = 1
        picImg.isUserInteractionEnabled = true
        picImg.addGestureRecognizer(zoomTap)
    }
    
    @objc func zoomImg(recognizer: UITapGestureRecognizer) {
    
        // Define frame of zoomed img
        let zoomed = CGRect(x: 0, y: self.view.center.y - self.view.center.x - self.tabBarController!.tabBar.frame.size.height * 1.5, width: self.view.frame.size.width, height: self.view.frame.size.width)
        // Frame of unzoomed (small) image
        let unzoomed = CGRect(x: 15, y: 15, width: self.view.frame.size.width / 4.5, height: self.view.frame.size.width / 4.5)
        
        // If picture is unzoom, zoom it
        if picImg.frame == unzoomed {
            // With animation
            UIView.animate(withDuration: 0.3) {
                // Resize image frame
                self.picImg.frame = zoomed
                
                // Hide objects from background
                self.view.backgroundColor = .black
                self.titleTxt.alpha = 0
                self.publishBtn.alpha = 0
                self.removeBtn.alpha = 0
            }
        // To unzoom
        } else {
            // With animation
            UIView.animate(withDuration: 0.3) {
                // Resize image frame
                self.picImg.frame = unzoomed
                
                // Unhide objects from background
                self.view.backgroundColor = .white
                self.titleTxt.alpha = 1
                self.publishBtn.alpha = 1
                self.removeBtn.alpha = 1
            }
        }
    }

    // Clicked remove button
    @IBAction func removeBtn_clicked(_ sender: Any) {
        self.viewDidLoad()
    }
    

}
