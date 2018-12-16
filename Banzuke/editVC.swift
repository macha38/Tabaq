//
//  editVCViewController.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 3/20/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework

class editVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UI objects
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var avaImg: UIImageView!
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var bioTxt: UITextView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var emailTxt: UITextField!
    
    // Value to hold keyboard frame size
    var keyboard = CGRect()
    
    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check notification of keyboard - shown or not
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)

        // Declare hide keyboard tap
        let hideTap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
        hideTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)
        
        // Declare select image tap
        let avaTap = UITapGestureRecognizer(target: self, action: #selector(loadImg))
        avaTap.numberOfTapsRequired = 1
        avaImg.isUserInteractionEnabled = true
        avaImg.addGestureRecognizer(avaTap)

        // Call alignment function
        alignment()
        
        // Show userinfo data
        showUserInfo()
    }
    

    // Alignment function
    func alignment() {

        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        
        scrollView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        avaImg.frame = CGRect(x: width - 68 - 10, y: 15, width: 68, height: 68)
        avaImg.layer.cornerRadius = avaImg.frame.size.width / 2
        avaImg.clipsToBounds = true
        
        usernameTxt.frame = CGRect(x: 10, y: avaImg.frame.origin.y, width: width - avaImg.frame.size.width - 30, height: 30)
        
        bioTxt.frame = CGRect(x: 10, y: avaImg.frame.origin.y + 78, width: width - 20, height: 83)
        bioTxt.layer.borderWidth = 1
        bioTxt.layer.borderColor = UIColor.flatWhite().cgColor
        bioTxt.layer.cornerRadius = bioTxt.frame.size.width / 50
        bioTxt.clipsToBounds = true
        
        titleLbl.frame = CGRect(x: 15, y: bioTxt.frame.origin.y + 100, width: width - 20, height: 30)
        emailTxt.frame = CGRect(x: 10, y: titleLbl.frame.origin.y + 35, width: width - 20, height: 30)
 
    }
    
    // Show user information
    func showUserInfo(){
        // Read userinfo
        if let avaQuery = PFUser.current()?.object(forKey: "ava") as? PFFile {
            avaQuery.getDataInBackground {
                (data, error) in
                self.avaImg.image = UIImage(data: data!)
            }
        }
        usernameTxt.text = PFUser.current()?.object(forKey: "username") as? String
        bioTxt.text = PFUser.current()?.object(forKey: "bio") as? String
        emailTxt.text = PFUser.current()?.object(forKey: "email") as? String
    }

    // Regex restrictions for email textfield
    func validateEmail(email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]{4}+@[A-Za-z0-9.-]+\\.[A-Za-z]{2}"
        let range = email.range(of: regex, options: .regularExpression)
        let result = range != nil ? true : false
        return result
    }
    func validateWeb (web: String) -> Bool {
        let regex = "www.+[A-Z0-9a-z._+-]+.[A-Za-z]{2}"
        let range = web.range(of: regex, options: .regularExpression)
        let result = range != nil ? true : false
        return result
    }
    func alert (error: String, message: String) {
        let alert = UIAlertController(title: error, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Click save button
    @IBAction func saveBtn_clicked(_ sender: Any) {

        // dismiss keyboard
        self.view.endEditing(true)
        
        if !validateEmail(email: emailTxt.text!) {
            alert(error: "Incorrect email", message: "Please provide correct email address")
            return
        }
        
        // check empty column
        if usernameTxt.text!.isEmpty || emailTxt.text!.isEmpty {
            
            // alert message
            let alert = UIAlertController(title: "Please", message: "Fill User Name, Full Name and Email fields", preferredStyle: UIAlertControllerStyle.alert)
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
        
        // update data to server to related collums
        let user = PFUser.current()!
        user.username = usernameTxt.text?.lowercased()
        user.email = emailTxt.text?.lowercased()
        user["bio"] = bioTxt.text
        
        // convert our image for sending to server
        let avaData = UIImageJPEGRepresentation(avaImg.image!, 0.5)
        let avaFile = PFFile(name: "ava.jpg", data: avaData!)
        user["ava"] = avaFile
        
        // save data in server
        user.saveInBackground{
            (success, error) in
            if success{

                // Close View
                self.dismiss(animated: true, completion: nil)
                // remember logged user
                UserDefaults.standard.set(user.username, forKey: "username")
                UserDefaults.standard.synchronize()
                // Send notification to homeVC to be reloaded
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
                
            } else {
                
                // show alert message
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    }
    
    // Click cancel button
    @IBAction func cancelBtn_clicked(_ sender: Any) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    // Picker View Methods
    // Picker compornent number
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Hide keyboard if tapped
    @objc func hideKeyboardTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // Show keyboard
    @objc func keyboardWillShow(notification: NSNotification){
        
        // difine keyboard size
        keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue)!
        
        // move up UI
        UIView.animate(withDuration: 0.4) {
            self.scrollView.contentSize.height = self.view.frame.size.height + self.keyboard.height / 2
        }
        print("message got successfully")
    }
    // Hide keyboard func
    @objc func keyboardWillHide(notification: NSNotification) {
        
        // move down UI
        UIView.animate(withDuration: 0.4){
            self.scrollView.contentSize.height = 0
        }
    }
    // Call picker to select image
    @objc func loadImg(recognizer: UITapGestureRecognizer) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    // Connect selected image to ou ImageView
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        avaImg.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }

    
}
