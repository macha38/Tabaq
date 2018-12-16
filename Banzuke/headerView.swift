//
//  headerView.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 2/28/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework

class headerView: UICollectionReusableView, UICollectionViewDelegate {
    
    @IBOutlet weak var avaImg: UIImageView!
    @IBOutlet weak var bioLbl: UILabel!
    
    @IBOutlet weak var posts: UILabel!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var followings: UILabel!
    
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var followersTitle: UILabel!
    @IBOutlet weak var followingsTitle: UILabel!
    
    @IBOutlet weak var button: UIButton!

    var guestDelegate: GuestVCDelegate?


    // Default function
    override func awakeFromNib() {
        super.awakeFromNib()
        
        button.layer.cornerRadius = button.frame.size.width / 30
        
        // alignment
        let width = UIScreen.main.bounds.width
        
        avaImg.frame = CGRect(x: width / 25, y: width / 25, width: width / 4, height: width / 4)
        
        posts.frame = CGRect(x: width / 2.5, y: avaImg.frame.origin.y, width: 50, height: 30)
        followers.frame = CGRect(x: width / 1.7, y: avaImg.frame.origin.y, width: 50, height: 30)
        followings.frame = CGRect(x: width / 1.25, y: avaImg.frame.origin.y, width: 50, height: 30)
        
        postTitle.center = CGPoint(x: posts.center.x, y: posts.center.y + 20)
        followersTitle.center = CGPoint(x: followers.center.x, y: followers.center.y + 20)
        followingsTitle.center = CGPoint(x: followings.center.x, y: followings.center.y + 20)
        
        button.frame = CGRect(x: postTitle.frame.origin.x, y: postTitle.center.y + 20, width: width - postTitle.frame.origin.x - 10, height: 30)
        button.layer.cornerRadius = button.frame.size.width / 50
        
        bioLbl.frame = CGRect(x: avaImg.frame.origin.x, y: avaImg.frame.origin.y + avaImg.frame.size.height + 20, width: width - 30, height: 30)
        
        // round ava
        avaImg.layer.cornerRadius = avaImg.frame.size.width / 2
        avaImg.clipsToBounds = true

        

    }

    @IBAction func headerBtn_clicked(_ sender: Any) {
        let title = button.title(for: .normal)
        
        // To follow
        if title == "Follow" {
            // Follow -> Following
            let object = PFObject(className: "follow")
            object["followerpt"] = PFUser.current()!
            object["followingpt"] = guestptArray.last!
            object.saveInBackground {
                (success, error) in
                if success {
                    self.button.setTitle("Following", for: .normal)
                    self.button.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
                    self.button.backgroundColor = UIColor.flatWhite()
                    self.button.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
                    self.button.layer.borderWidth = 1.0
                    self.button.layer.cornerRadius = self.button.frame.size.width / 20
                    // Reflect guest header
                    self.guestDelegate?.reload()

                    // update notification
                    let newsObj = PFObject(className: "news")
                    newsObj["by"] = PFUser.current()
                    newsObj["to_userid"] = guestptArray.last?.objectId
                    newsObj["postuuid"] = ""
                    newsObj["commentuuid"] = ""
                    newsObj["type"] = "follow"
                    newsObj["checked"] = "no"
                    newsObj.saveEventually()

                } else {
                    print(error!.localizedDescription)
                }
            }
        } else {
            // Following -> Follow
            let object = PFQuery(className: "follow")
            object.whereKey("followerpt", equalTo: PFUser.current()!)
            object.whereKey("followingpt", equalTo: guestptArray.last!)
            object.findObjectsInBackground{
                (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground {
                            (success, error) in
                            if success {
                                self.button.setTitle("Follow", for: .normal)
                                self.button.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
                                self.button.backgroundColor = UIColor.flatYellow()
                                self.button.layer.borderColor = UIColor.flatYellowColorDark().cgColor
                                self.button.layer.borderWidth = 1.0
                                self.button.layer.cornerRadius = self.button.frame.size.width / 20
                                // Reflect guest header
                                self.guestDelegate?.reload()
                                
                                let newsQuery = PFQuery(className: "news")
                                newsQuery.whereKey("by", equalTo: PFUser.current()!)
                                newsQuery.whereKey("to_userid", equalTo: guestptArray.last!.objectId!)
                                newsQuery.whereKey("type", equalTo: "follow")
                                newsQuery.findObjectsInBackground{ (objects, error) in
                                    if error == nil {
                                        for object in objects! {
                                            object.deleteEventually()
                                        }
                                    }
                                }

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
