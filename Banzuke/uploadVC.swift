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

extension UIView {
    var screenShot: UIImage?  {
        if #available(iOS 10, *) {
            let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
            return renderer.image { (context) in
                self.layer.render(in: context.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0);
            if let _ = UIGraphicsGetCurrentContext() {
                drawHierarchy(in: bounds, afterScreenUpdates: true)
                let screenshot = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return screenshot
            }
            return nil
        }
    }
}

@IBDesignable class RoundedButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var borderWidth: CGFloat = 0.0
    @IBInspectable var borderColor: UIColor = UIColor.clear

    override func draw(_ rect: CGRect) {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        contentHorizontalAlignment = .left
        contentEdgeInsets = UIEdgeInsets(top: 0.2, left: 5, bottom: 0.1, right: 1)
        clipsToBounds = true
    }
}


class PhotoData {
    // Image data
    var photoImage: UIImage?
    // Photo location
    var photoLocation: PFGeoPoint?
}

class LocationData {
    var name: String?
    var title: String?
    var location: PFGeoPoint?
    var restuuid: String?
}

// delegation for reflect location data from mapVC
protocol uploadVCDelegate {
    func setLocationFromMap(givenLocation: LocationData)
}


class uploadVC: UIViewController, UIScrollViewDelegate, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, uploadVCDelegate {

    // UI objects
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var trimView: UIScrollView!
    @IBOutlet weak var picView: UIImageView!
    @IBOutlet weak var locationBtn: UIButton!
    @IBOutlet weak var locationCol: UICollectionView!
    @IBOutlet weak var titleTxt: UITextView!
    @IBOutlet weak var publishBtn: UIButton!
    
    // Given photo image from photoVC or camera VC
    let photoData = PhotoData()
    // Value to hold keyboard frame size
    var keyboard = CGRect()
    // Storage for restaurants data
    var selectedLocation : LocationData!
    var locationArray = [LocationData]()
    
    // default search area
    let locationlmt: Double = 0.2
    
    // Load limit of restaulants
    let limit: Int = 15

    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()

        // Delegation
        trimView.delegate = self
        titleTxt.delegate = self
        locationCol.delegate = self
        locationCol.dataSource = self
        
        // Alignment
        alignment()

        // Disable publish btn
        publishBtn.isEnabled = false
        publishBtn.backgroundColor = .lightGray
        
        // Text view
        titleTxt.text = "Comment"
        titleTxt.textColor = UIColor.lightGray
        
        // Hide tab bar
        self.tabBarController?.tabBar.isHidden = true
        
        // Declare hide keyboard tap
        let hideTap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
        hideTap.numberOfTapsRequired = 1
        hideTap.cancelsTouchesInView = false
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)
        
        // New back button
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = backBtn
        
        // Swipe to go back
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        
        // Check notification of keyboard - shown or not
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)

        // Setting trimView
        trimView.minimumZoomScale = 1.0
        trimView.maximumZoomScale = 5.0
        trimView.zoomScale = 1.0
        trimView.backgroundColor = .black
//        trimView.isScrollEnabled = true
//        trimView.isUserInteractionEnabled = true
//        trimView.showsHorizontalScrollIndicator = false
//        trimView.showsVerticalScrollIndicator = false
        
        // Setting location collection view
        locationCol.showsVerticalScrollIndicator = true
        locationCol.isUserInteractionEnabled = true
//        locationCol.allowsSelection = true
//        locationCol.allowsMultipleSelection = true
        

        // Set photo
        self.picView.image = photoData.photoImage
        self.picView.contentMode = .scaleAspectFit
        self.picView.isUserInteractionEnabled = true
        // Recalculate framesize
        if self.picView.image!.size.width < self.picView.image!.size.height {
            self.picView.frame.size.height = self.picView.frame.width * self.picView.image!.size.height / self.picView.image!.size.width
            let offset : CGFloat = (self.picView.frame.size.height - self.trimView.frame.size.height) / 2
            self.trimView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        } else {
            self.picView.frame.size.width = self.picView.frame.height * self.picView.image!.size.width / self.picView.image!.size.height
            let offset : CGFloat = (self.picView.frame.size.width - self.trimView.frame.size.width) / 2
            self.trimView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        }
        self.trimView.contentSize = self.picView.frame.size
        
        // search nearby locations
        if photoData.photoLocation != nil {

            // send photo location to select location
//            let iniLocation = RestData()
//            iniLocation.location = photoData.photoLocation
//            selRest = iniLocation

            // Load posts
            let query = PFQuery(className: "restaurants")
            query.whereKey("location", nearGeoPoint: photoData.photoLocation!, withinKilometers: locationlmt)
            query.limit = limit
            query.findObjectsInBackground {
                
                (objects, error) in
                if error == nil {
                    
                    // Find related objects
                    for object in objects! {
                        
                        let tmprest = LocationData()
                        tmprest.name = object.value(forKey: "name") as? String
                        tmprest.location = object.value(forKey: "location") as? PFGeoPoint
                        tmprest.restuuid = object.objectId
                        self.locationArray.append(tmprest)
                    }
                    
                    // Display data
                    self.locationCol.reloadData()
                    
                } else {
                    print(error!.localizedDescription)
                }
            }
        }
        
        // Activate publish button
        self.publishBtn.isEnabled = true
        self.publishBtn.backgroundColor = UIColor.flatYellowColorDark()
    }
    
    // Alignment
    func alignment() {
        // Get screen width
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        
        trimView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        picView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        locationBtn.frame = CGRect(x: 20, y: width + 10, width: width - 40, height: 24)
        locationCol.frame = CGRect(x: 20, y: locationBtn.frame.origin.y + 24 + 5, width: width - 40, height: 35)
        titleTxt.frame = CGRect(x: 20, y: locationCol.frame.origin.y + 35 + 5, width: width - 40, height: 100)
        publishBtn.frame = CGRect(x: 0, y: height / 1.067, width: width, height: width / 8)
        scrollView.frame = CGRect(x: 0, y: 0, width: width, height: height - publishBtn.frame.size.height)
    }

    // set title
    func setLocationFromMap(givenLocation: LocationData) {
        
        selectedLocation = givenLocation
        locationBtn.setTitle(selectedLocation.name, for: .normal)
        locationBtn.setTitleColor(UIColor.black, for: .normal)
    }
    
    // Cell number
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locationArray.count
    }
    
    // Cell config
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LocCell", for: indexPath) as! locationCell
        
        // return when before loading nearby locations
        if locationArray.count == 0 {
            return cell
        }
        
        cell.locationLbl.text = locationArray[indexPath.row].name
        cell.locationLbl.sizeToFit()
        
        return cell
    }
    
    // cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let size = locationArray[indexPath.row].name!.size(withAttributes: nil)
        
        return CGSize(width: size.width + 25, height: locationCol.frame.size.height)
    }
    
    // tap cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedLocation = locationArray[indexPath.row]
        locationBtn.setTitle(selectedLocation.name, for: .normal)
        locationBtn.setTitleColor(UIColor.black, for: .normal)
    }
    
    // assign zooming view
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return picView
    }
    
    
    // Placeholder to textView
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Comment"
            textView.textColor = UIColor.lightGray
        }
    }
    
    
    // Show keyboard
    @objc func keyboardWillShow(notification: NSNotification){
        
        // difine keyboard size
        keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue)!
        
        // move up UI
        UIView.animate(withDuration: 0.4) {
            self.scrollView.contentSize.height = self.view.frame.size.height + self.keyboard.height / 2
            self.scrollView.contentOffset.y = 150
        }
    }
    
    // Hide keyboard func
    @objc func keyboardWillHide(notification: NSNotification) {
        
        // move down UI
        UIView.animate(withDuration: 0.4){
            self.scrollView.contentSize.height = 0
        }
    }

    // go select location
    @IBAction func locationBtn_clicked(_ sender: Any) {
        
        // Go to mapVC to search restaurant from Maps
        let mapvc = self.storyboard?.instantiateViewController(withIdentifier: "mapVC") as! mapVC
        mapvc.uploadDelegate = self
        if selectedLocation != nil {
            mapvc.selectedLocation = selectedLocation
        } else if photoData.photoLocation != nil {
            let location = LocationData()
            location.location = photoData.photoLocation
            mapvc.selectedLocation = location
        }
        self.navigationController?.pushViewController(mapvc, animated: true)
    }
    
    // Click publish button
    @IBAction func publishBtn_clicked(_ sender: Any) {
        
        // Dissmiss keyboard
        self.view.endEditing(true)
        
        // hide button
        publishBtn.isHidden = true
        
        // Send data to server to "posts" class in Parse
        let object = PFObject(className: "posts")
        object["uuid"] = "\(PFUser.current()!.objectId!)\(NSUUID().uuidString)"
        object["user"] = PFUser.current()!
        
        if titleTxt.text.isEmpty {
            object["title"] = ""
        } else if titleTxt.text == "Comment" {
            object["title"] = ""
        } else {
            object["title"] = titleTxt.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        // Send pic to server after converting to File and conpression
        let preimageData = trimView.screenShot
        let imageData = UIImageJPEGRepresentation(preimageData!, 0.5)
        let imageFile = PFFile(name: "post.jpg", data: imageData!)
        object["pic"] = imageFile
        
        if selectedLocation != nil {
            object["location"] = selectedLocation.location
            object["restname"] = selectedLocation.name
            object["restuuid"] = selectedLocation.restuuid
        } else {
            if photoData.photoLocation != nil {
                object["location"] = photoData.photoLocation
            }
        }
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
                // Close view
                self.dismiss(animated: true, completion: nil)
                // Switch to another ViewController at 0 index of tabbar
                self.tabBarController?.selectedIndex = 0
//                // Reset everything
//                self.viewDidLoad()
            } else {
                
                // hide button
                self.publishBtn.isHidden = false
                print(error!.localizedDescription)
            }
        }
    }
    

    // Hide keyboard function
    @objc func hideKeyboardTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    
    // Back function
    @objc func back(sender: UITabBarItem){
        
        self.tabBarController?.tabBar.isHidden = false
        // Push Back (go back to previous view under navigation view)
        self.navigationController?.popViewController(animated: true)
    }

}
