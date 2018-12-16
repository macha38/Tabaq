//
//  postCell.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 4/29/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework

class postCell: UITableViewCell {
    // Header objects
    @IBOutlet weak var avaImg: UIImageView!
    @IBOutlet weak var usernameBtn: UIButton!
    @IBOutlet weak var dateLbl: UILabel!
    // Main picture
    @IBOutlet weak var picImg: UIImageView!
    // Buttons
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var locationImg: UIImageView!
    @IBOutlet weak var locationnameBtn: UIButton!
    // Labels
    @IBOutlet weak var likeLbl: UILabel!
    @IBOutlet weak var titleLbl: KILabel!
    @IBOutlet weak var uuidLbl: UILabel!
    // Delegate
    var feedDelegate: FeedVCDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Clear like button title color
        likeBtn.setTitleColor(UIColor.clear, for: .normal)

        // Declare double tap on the post
        let likeDbltap = UITapGestureRecognizer(target: self, action: #selector(likeTap))
        likeDbltap.numberOfTapsRequired = 2
        picImg.isUserInteractionEnabled = true
        picImg.addGestureRecognizer(likeDbltap)

        // MARK: Allow constraints
        avaImg.translatesAutoresizingMaskIntoConstraints = false
        usernameBtn.translatesAutoresizingMaskIntoConstraints = false
        dateLbl.translatesAutoresizingMaskIntoConstraints = false
        picImg.translatesAutoresizingMaskIntoConstraints = false
        likeBtn.translatesAutoresizingMaskIntoConstraints = false
        commentBtn.translatesAutoresizingMaskIntoConstraints = false
        moreBtn.translatesAutoresizingMaskIntoConstraints = false
        likeLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        uuidLbl.translatesAutoresizingMaskIntoConstraints = false
        locationnameBtn.translatesAutoresizingMaskIntoConstraints = false
        locationImg.translatesAutoresizingMaskIntoConstraints = false

        // MARK: Set Constraints
        // TODO: Vertical
        let width = UIScreen.main.bounds.width
        let pictureWidth = width
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-10-[ava(40)]-10-[pic(\(pictureWidth))]-10-[locationimg(30)]",
            options: [], metrics: nil, views: ["ava":avaImg, "pic":picImg, "locationimg":locationImg]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-15-[username]",
            options: [], metrics: nil, views: ["username":usernameBtn]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-25-[date]",
            options: [], metrics: nil, views: ["date":dateLbl]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[locationimg]-5-[title]-20-|",
            options: [], metrics: nil, views:["locationimg":locationImg, "title":titleLbl]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[pic]-10-[locationname(30)]",
            options: [], metrics: nil, views: ["pic":picImg, "locationname":locationnameBtn]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[pic]-10-[like(30)]",
            options: [], metrics: nil, views: ["pic":picImg, "like":likeBtn]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[pic]-17-[likes]",
            options: [], metrics: nil, views: ["pic":picImg, "likes":likeLbl]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[pic]-10-[comment(30)]",
            options: [], metrics: nil, views: ["pic":picImg, "comment":commentBtn]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[pic]-10-[more(30)]",
            options: [], metrics: nil, views: ["pic":picImg, "more":moreBtn]))
        // TODO: Horizontal
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-10-[ava(40)]-10-[username]",
            options: [], metrics: nil, views: ["ava":avaImg, "username":usernameBtn]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[pic]-0-|",
            options: [], metrics: nil, views: ["pic":picImg]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-10-[locationimg(30)]-3-[locationname]-10-[like(30)]-10-[likes]-20-[comment(30)]-15-[more(30)]-15-|",
            options: [], metrics: nil, views: ["locationimg":locationImg, "locationname":locationnameBtn, "like":likeBtn, "likes":likeLbl, "comment":commentBtn, "more": moreBtn]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-10-[title]-15-|",
            options: [], metrics: nil, views:["title":titleLbl]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[date]-10-|",
            options: [], metrics: nil, views: ["date":dateLbl]))
        
        // TODO: Round Avator
        self.avaImg.layer.cornerRadius = self.avaImg.frame.size.width / 2
        self.avaImg.clipsToBounds = true

    }
    
    // Double tap on the post
    @objc func likeTap() {
        
        // Implement like action
        likeAction(sender: nil)
        
        // Create large like gray heart
        let likePic = UIImageView(image: UIImage(named: "unlike.png"))
        likePic.frame.size.width = picImg.frame.size.width / 1.5
        likePic.frame.size.height = picImg.frame.size.width / 1.5
        likePic.center = picImg.center
        likePic.alpha = 0.8
        self.addSubview(likePic)
        // Hide likePic with animation and transform to be smaller
        UIView.animate(withDuration: 0.8) {
            likePic.alpha = 0
            likePic.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }
    }
    
    // Click Like Button
    @IBAction func likeBtn_click(_ sender: Any) {
        // Inplement like action
        likeAction(sender: sender)
    }
    
    // Action when like/unlike implemented
    func likeAction(sender: Any?) {
        
        // Declare title of button
        var title : String?
        if let send = sender {
            title = (send as AnyObject).title(for: .normal)
        } else {
            title = likeBtn.title(for: .normal)
        }
        
        // To like
        if title == "unlike" {
            
            // set like
            self.likeBtn.setTitle("like", for: .normal)
            self.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: .normal)

            let object = PFObject(className: "likes")
            object["by"] = PFUser.current()!
            object["to"] = uuidLbl.text
            object.saveEventually()
            
            // Count up lkcnt in Posts class
            let query = PFQuery(className: "posts")
            query.whereKey("uuid", equalTo: uuidLbl.text!)
            query.findObjectsInBackground {
                (objects, error) in
                // Find objects
                for object in objects! {
                    var likecnt = object.value(forKey: "lkcnt") as! Int
                    likecnt = likecnt + 1
                    object["lkcnt"] = likecnt
                    object.saveEventually()
                    self.likeLbl.text = String(likecnt)
                    // Send message to add like
                    self.feedDelegate?.addlike(postuuid: self.uuidLbl.text!)
                }
            }

            // update notification
            if PFUser.current()?.objectId != (usernameBtn.layer.value(forKey: "user") as! PFUser).objectId {
                let newsObj = PFObject(className: "news")
                newsObj["by"] = PFUser.current()
                newsObj["to_userid"] = (usernameBtn.layer.value(forKey: "user") as! PFUser).objectId
                newsObj["postuuid"] = uuidLbl.text!
                newsObj["commentuuid"] = ""
                newsObj["type"] = "like"
                newsObj["checked"] = "no"
                newsObj.saveEventually()
            }
            

        // To dislike
        } else {

            // set unlike
            self.likeBtn.setTitle("unlike", for: .normal)
            self.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: .normal)
            
            // Request existing likes of current user to show post
            let query = PFQuery(className: "likes")
            query.whereKey("by", equalTo: PFUser.current()!)
            query.whereKey("to", equalTo: uuidLbl.text!)
            query.findObjectsInBackground {
                (objects, error) in
                // Find objects
                for object in objects! {
                    // Delete found object
                    object.deleteEventually()
                }
            }
            
            // Count down lkcnt in Posts class
            let postsquery = PFQuery(className: "posts")
            postsquery.whereKey("uuid", equalTo: uuidLbl.text!)
            postsquery.findObjectsInBackground {
                (objects, error) in
                // Find objects
                for object in objects! {
                    var likecnt = object.value(forKey: "lkcnt") as! Int
                    if likecnt > 0 {
                        likecnt = likecnt - 1
                    } else {
                        likecnt = 0
                    }
                    object["lkcnt"] = likecnt
                    object.saveEventually()
                    self.likeLbl.text = String(likecnt)
                    // Send message to substract like
                    self.feedDelegate?.sublike(postuuid: self.uuidLbl.text!)
                }
            }
            
            // delete notification
            if PFUser.current()?.objectId != (usernameBtn.layer.value(forKey: "user") as! PFUser).objectId {

                let newsQuery = PFQuery(className: "news")
                newsQuery.whereKey("by", equalTo: PFUser.current()!)
                newsQuery.whereKey("postuuid", equalTo: uuidLbl.text!)
                newsQuery.whereKey("type", equalTo: "like")
                newsQuery.findObjectsInBackground{ (objects, error) in
                    if error == nil {
                        for object in objects! {
                            object.deleteEventually()
                        }
                    }
                }
            }
        }
    }
}
