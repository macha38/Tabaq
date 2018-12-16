//
//  signinVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 2/15/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse

class signinVC: UIViewController, UITextFieldDelegate {

    // Text field
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    
    // Buttons
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var signupBtn: UIButton!
    @IBOutlet weak var forgotBtn: UIButton!
    
    
    // default function
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pacifico font of label
        label.font = UIFont(name: "Pacifico", size: 25)
        // text color
        label.textColor = UIColor.white
        forgotBtn.setTitleColor(UIColor.white, for: .normal)
        
        // alignment
        label.frame = CGRect(x: 10, y: 80, width: self.view.frame.size.width - 20, height: 50)
        
        usernameTxt.frame = CGRect(x: 10, y: label.frame.origin.y + 70, width: self.view.frame.size.width - 20, height: 30)
        passwordTxt.frame = CGRect(x: 10, y: usernameTxt.frame.origin.y + 40, width: self.view.frame.size.width - 20, height: 30)
        forgotBtn.frame = CGRect(x: 10, y: passwordTxt.frame.origin.y + 30, width: self.view.frame.size.width - 20, height: 30)
        signinBtn.frame = CGRect(x: 20, y: forgotBtn.frame.origin.y + 40, width: self.view.frame.size.width / 4, height: 30)
        signupBtn.frame = CGRect(x: self.view.frame.size.width - self.view.frame.size.width / 4 - 20, y: signinBtn.frame.origin.y, width: self.view.frame.size.width / 4, height: 30)
        signinBtn.layer.cornerRadius = signinBtn.frame.size.width / 20
        signupBtn.layer.cornerRadius = signupBtn.frame.size.width / 20

        
        // declare hide keyboard tap
        let hideTap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
        hideTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)

        // background image
        let bg = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        bg.image = UIImage(named: "Night.jpg")
        bg.layer.zPosition = -1
        self.view.addSubview(bg)
        
        // textfield delegation
        usernameTxt.delegate = self
        passwordTxt.delegate = self
        if #available(iOS 12, *) {
            // iOS 12: Not the best solution, but it works.
            usernameTxt.textContentType = .oneTimeCode
            passwordTxt.textContentType = .oneTimeCode
        } else {
            // iOS 11: Disables the autofill accessory view.
            // For more information see the explanation below.
            usernameTxt.textContentType = .init(rawValue: "")
            passwordTxt.textContentType = .init(rawValue: "")
        }
    }
    // White status bar function
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTxt:
            passwordTxt.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return false
    }

    
    @IBAction func signInBtn_click(_ sender: Any) {
        print("sign in pressed")
        
        // hide keyboard
        self.view.endEditing(true)
        
        // if textfields are empty
        if usernameTxt.text!.isEmpty || passwordTxt.text!.isEmpty {
            
            // show alert message
            let alert = UIAlertController(title: "Please", message: "Fill in fields", preferredStyle: UIAlertControllerStyle.alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
        
        // login function
        PFUser.logInWithUsername(inBackground: usernameTxt.text!, password: passwordTxt.text!) {
            (user, error) in
            if error == nil {
                
                // remember user or save in App Memory did the user login or not
                UserDefaults.standard.set(user!.username, forKey: "username")
                UserDefaults.standard.set(user!.objectId, forKey: "userid")
                UserDefaults.standard.synchronize()
                
                // call login function from AppDelegate.swift class
                let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.login()
                
            } else {
                
                // show alert message
                let alert = UIAlertController(title: "Erorror", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)

            }
        }
        
        
    }

    
    // hide keyboard if tapped
    @objc func hideKeyboardTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    
    
    @IBAction func signUpBtn_click(_ sender: Any) {
    }
    
    
    

}
