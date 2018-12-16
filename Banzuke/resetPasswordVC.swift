//
//  resetPasswordVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 2/15/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse

class resetPasswordVC: UIViewController {

    // text field
    @IBOutlet weak var emailTxt: UITextField!
    
    // buttons
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    // default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // alignment
        emailTxt.frame = CGRect(x: 10, y: 120, width: self.view.frame.size.width - 20, height: 30)
        resetBtn.frame = CGRect(x: 20, y: emailTxt.frame.origin.y + 50, width: self.view.frame.size.width / 4, height: 30)
        cancelBtn.frame = CGRect(x: self.view.frame.size.width - self.view.frame.size.width / 4 - 20, y: resetBtn.frame.origin.y, width: self.view.frame.size.width / 4, height: 30)
        
        resetBtn.layer.cornerRadius = resetBtn.frame.size.width / 20
        cancelBtn.layer.cornerRadius = cancelBtn.frame.size.width / 20

        
        // background
        let bg = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height) )
        bg.image = UIImage(named: "Aurora.jpg")
        bg.layer.zPosition = -1
        self.view.addSubview(bg)
    }
    
    // White status bar function
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    // click button actions
    @IBAction func resetBtn_click(_ sender: Any) {
        
        // hide keyboard
        self.view.endEditing(true)
        
        // email textfiewld is empty
        if emailTxt.text!.isEmpty {
            let alert = UIAlertController(title: "Email field", message: "is empty", preferredStyle: UIAlertControllerStyle.alert)
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alert.addAction(ok)

            self.present(alert, animated: true, completion: nil)
        }
        
        // request for resetting password
        PFUser.requestPasswordResetForEmail(inBackground: emailTxt.text!) {
            (success, error) in
            if success {
                
                // show alert message
                let alert = UIAlertController(title: "Email for resetting password", message: "has been sent to texted email", preferredStyle: UIAlertControllerStyle.alert)
                
                // if pressed OK call self.dismiss.. function
                let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ (UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                }
                alert.addAction(ok)
                
                self.present(alert, animated: true, completion: nil)
            } else {
                print(error!.localizedDescription)
            }
        }
        
        
        
    }
    @IBAction func cancelBtn_click(_ sender: Any) {
        
        // hide keyboard when press cancel
        self.view.endEditing(true)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    

}
