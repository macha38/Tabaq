//
//  followersVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 3/5/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework
import SVProgressHUD

var disptrg = String()
var dispUser = PFUser()

public extension UIViewController
{
    public func getPreviousViewController() -> UIViewController?
    {
        if let vcList = navigationController?.viewControllers
        {
            var prevVc: UIViewController?;
            for vc in vcList
            {
                if ( vc == self ) { break }
                prevVc = vc
            }
            return prevVc
        }
        // It should not come here
        return nil
    }
}

class followersVC: UITableViewController {
    
    // arrays to hold "user" class data
    var followPtArray = [PFUser]()
    var isFollow = [Bool]()
    
    // Arrays to hold current user's following
    var cuFollowingArray = [PFUser]()
    
    // Local data storage for global
    var dispTrgLocal: String = ""
    var dispUserLocal: PFUser?

    // default func
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // Pass global data to local storage
        dispTrgLocal = disptrg
        dispUserLocal = dispUser
        // title at the top
        self.navigationItem.title = dispTrgLocal
        
        // New back button
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = backBtn
        // Swipe to go back
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)

        // Load all necessary data from database
        reloadAll()
    }
    
    // Read all necessary data
    func reloadAll(){

        SVProgressHUD.show()

        // Save current user's following
        saveAllCurrentUsersFollowing()
        // Load data depend on target
        switch dispTrgLocal{
        // load followers when "followers" label tapped
        case "Followers":
            loadFollowers()
        // load followings when "followings" label tapped
        case "Followings":
            loadFollowings()
        default: break
        }
        
        SVProgressHUD.dismiss()
    }
    
    // Loading current user's following
    func saveAllCurrentUsersFollowing() {
        // Find followings from "follow" class
        let followQuery = PFQuery(className: "follow")
        followQuery.whereKey("followerpt", equalTo: PFUser.current()!)
        followQuery.includeKey("followingpt")
//       followQuery.findObjectsInBackground {
//            (objects, error) in
//            if error == nil {
//                // Clean up
//                self.cuFollowingArray.removeAll(keepingCapacity: false)
//                // Hold objects related to our request
//                for object in objects! {
//                    // Add found data to arrays
//                    self.cuFollowingArray.append(object.value(forKey: "followingpt") as! PFUser)
//                }
//                print("task done")
//            } else {
//                print(error!.localizedDescription)
//            }
//        }
        // Cache current users followings as syncronous reading, otherwise following status doesn't reflect correctly
        do {
            let objects: [PFObject] = try followQuery.findObjects()
            // Clean up
            self.cuFollowingArray.removeAll(keepingCapacity: false)
            // Hold objects related to our request
            for object in objects {
                // Add found data to arrays
                self.cuFollowingArray.append(object.value(forKey: "followingpt") as! PFUser)
            }
        } catch {
            // error
            print("error reading follow object")
        }
    }
    
    // Loading followers
    func loadFollowers() {
        // Find followers from "follow" class
        let followQuery = PFQuery(className: "follow")
        followQuery.whereKey("followingpt", equalTo: dispUserLocal!)
        followQuery.includeKey("followerpt")
        followQuery.addDescendingOrder("createdAt")
        followQuery.findObjectsInBackground {
            (objects, error) in
            if error == nil {
                // Clean up
                self.followPtArray.removeAll(keepingCapacity: false)
                self.isFollow.removeAll(keepingCapacity: false)
                // Hold objects related to our request
                var row = 0
                for object in objects! {
                    // Add found data to arrays
                    self.followPtArray.append(object.value(forKey: "followerpt") as! PFUser)
                    self.isFollow.append(false)
                    // Check if current user follows this follower
                    for i in 0..<self.cuFollowingArray.count {
                        if self.cuFollowingArray[i].objectId == self.followPtArray.last?.objectId {
                            self.isFollow[row] = true
                            break
                        }
                    }
                    row += 1
                }
                
                // Reload
                self.tableView.reloadData()
                
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    // Loading followings
    func loadFollowings() {
        // Find followings from "follow" class
        let followQuery = PFQuery(className: "follow")
        followQuery.whereKey("followerpt", equalTo: dispUserLocal!)
        followQuery.includeKey("followingpt")
        followQuery.addDescendingOrder("createdAt")
        followQuery.findObjectsInBackground {
            (objects, error) in
            if error == nil {
                // Clean up
                self.followPtArray.removeAll(keepingCapacity: false)
                self.isFollow.removeAll(keepingCapacity: false)
                // Hold objects related to our request
                var row = 0
                for object in objects! {
                    // Add found data to arrays
                    self.followPtArray.append(object.value(forKey: "followingpt") as! PFUser)
                    self.isFollow.append(false)
                    // Check if current user follows this follower
                    for i in 0..<self.cuFollowingArray.count {
                        if self.cuFollowingArray[i].objectId == self.followPtArray.last?.objectId {
                            self.isFollow[row] = true
                            break
                        }
                    }
                    row += 1
                }
                
                // Reload
                self.tableView.reloadData()
                
            } else {
                print(error!.localizedDescription)
            }
        }
    }

    // MARK: - Table view data source
    // cell number
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followPtArray.count
    }
    
    // Cell height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.size.width / 5.3
    }
    //    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return UITableViewAutomaticDimension
    //    }

    // cell config
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! followersCell

        cell.usernameLbl.text = followPtArray[indexPath.row].username
        cell.avaImg.image = UIImage(named: "usershape.png")
        (followPtArray[indexPath.row].object(forKey: "ava") as? PFFile)?.getDataInBackground {
            (data, error) in
            if error == nil {
                cell.avaImg.image = UIImage(data: data!)
            } else {
                print(error!.localizedDescription)
            }
        }
        // Put user pointer
        cell.layer.setValue(followPtArray[indexPath.row], forKey: "userinfo")
        
        // show follow relationship
        if isFollow[indexPath.row] == true {
            // current user follows
            cell.followBtn.setTitle("Following", for: .normal)
            cell.followBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
            cell.followBtn.backgroundColor = UIColor.flatWhite()
            cell.followBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
            cell.followBtn.layer.borderWidth = 1.0
            cell.followBtn.layer.cornerRadius = cell.followBtn.frame.size.width / 20
        } else {
            // current user not follows
            cell.followBtn.setTitle("Follow", for: .normal)
            cell.followBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
            cell.followBtn.backgroundColor = UIColor.flatYellow()
            cell.followBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
            cell.followBtn.layer.borderWidth = 1.0
            cell.followBtn.layer.cornerRadius = cell.followBtn.frame.size.width / 20
        }
        
        // hide follow button for current user
        if cell.usernameLbl.text == PFUser.current()?.username {
            cell.followBtn.isHidden = true
        }
        
        // round followBtn
        cell.followBtn.layer.cornerRadius = 2
        cell.followBtn.clipsToBounds = true
        
        return cell
    }
    
    
    // Function for tapping cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // recall cell for guest detail
        let cell = tableView.cellForRow(at: indexPath) as! followersCell
        
        // If user tapped on themself go homeVC, else go guestVC
        if (cell.layer.value(forKey: "userinfo") as! PFUser).objectId! == PFUser.current()!.objectId! {
            let home = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! homeVC
            self.navigationController?.pushViewController(home, animated: true)
        } else {
            // Get PFUser data as guestpt
            guestptArray.append(cell.layer.value(forKey: "userinfo") as! PFUser)
            let guest = self.storyboard?.instantiateViewController(withIdentifier: "guestVC") as! guestVC
            self.navigationController?.pushViewController(guest, animated: true)
        }
    }
    
    // Detect if Back button on Navigation Controller pressed
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParentViewController {
            if let home = self.getPreviousViewController() as? homeVC {
                home.reload()
            } else if let guest = self.getPreviousViewController() as? guestVC {
                guest.reload()
            }
        }
    }
    
    // Back function
    @objc func back(sender: /*UIBarButtonItem*/ UITabBarItem){
        // Push Back (go back to previous view under navigation view)
        self.navigationController?.popViewController(animated: true)
    }
}
