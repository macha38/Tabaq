//
//  followersCell.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 3/5/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework

class followersCell: UITableViewCell {
    
    @IBOutlet weak var avaImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var followBtn: UIButton!
    
    // Default function
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Alignment
        // alignment
        let width = UIScreen.main.bounds.width
        
        avaImg.frame = CGRect(x: 10, y: 10, width: width / 6.5, height: width / 6.5)
        usernameLbl.frame = CGRect(x: avaImg.frame.size.width + 20, y: 28, width: width / 3.2, height: 30)
        followBtn.frame = CGRect(x: width - width / 3.5 - 10, y: 30, width: width / 3.5, height: 30)
        followBtn.layer.cornerRadius = followBtn.frame.size.width / 20

        // round ava
        avaImg.layer.cornerRadius = avaImg.frame.size.width / 2
        avaImg.clipsToBounds = true
    }
 
    // Click follow / following button
    @IBAction func followBtn_click(_ sender: Any) {
        
        let title = followBtn.title(for: .normal)
        let userinfo = self.layer.value(forKey: "userinfo") as! PFUser
        
        // To follow
        if title == "Follow" {
            // Follow -> Following
            let object = PFObject(className: "follow")
            object["followerpt"] = PFUser.current()
            object["followingpt"] = userinfo
            object.saveInBackground {
                (success, error) in
                if success {
                    
                    self.followBtn.setTitle("Following", for: .normal)
                    self.followBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
                    self.followBtn.backgroundColor = UIColor.flatWhite()
                    self.followBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
                    self.followBtn.layer.borderWidth = 1.0
                    self.followBtn.layer.cornerRadius = self.followBtn.frame.size.width / 20
                } else {
                    print(error!.localizedDescription)
                }
            }
        } else {
            // Following -> Follow
            let object = PFQuery(className: "follow")
            object.whereKey("followerpt", equalTo: PFUser.current()!)
            object.whereKey("followingpt", equalTo: userinfo)
            object.findObjectsInBackground{
                (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground {
                            (success, error) in
                            if success {
                                
                                self.followBtn.setTitle("Follow", for: .normal)
                                self.followBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
                                self.followBtn.backgroundColor = UIColor.flatYellow()
                                self.followBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
                                self.followBtn.layer.borderWidth = 1.0
                                self.followBtn.layer.cornerRadius = self.followBtn.frame.size.width / 20
                            } else {
                                print(error!.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
    }
    

}
