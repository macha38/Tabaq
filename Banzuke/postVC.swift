//
//  postVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 4/29/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD


class postVC: UITableViewController {
    
    // For succeed data from homeVC, guestVC or usersVC
    var postuuid = [String]()
    // Arrays to hold posts class
    var postObj = [PFObject]()
    
    // Mentioned user
    var mentionedUser = PFUser()
    
    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title label at the top
        self.navigationItem.title = "Photo"
        // New back button
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = backBtn
        // Swipe to go back
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        // Receive notification from postCell
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "liked"), object: nil)

        // Dynamic cell height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 500

        // Find post
        let postQuery = PFQuery(className: "posts")
        postQuery.whereKey("uuid", equalTo: postuuid.last!)
        postQuery.includeKey("user")
        postQuery.findObjectsInBackground {
            (objects, error) in
            if error == nil {
                
                // Clean up
                self.postObj.removeAll(keepingCapacity: false)

                // Find related objects
                for object in objects! {
                    self.postObj.append(object)
                }
                
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source
    // TODO: Cell number
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postObj.count
    }
    
    // Cell config
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Define cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! postCell
        
        // Connect objects with our information from arrays
        cell.usernameBtn.setTitle((postObj[indexPath.row].value(forKey: "user") as! PFUser).username, for: .normal)
        cell.usernameBtn.sizeToFit()
        if let ava = (postObj[indexPath.row].value(forKey: "user") as! PFUser).object(forKey: "ava") as? PFFile {
            ava.getDataInBackground {
                (data, error) in
                cell.avaImg.image = UIImage(data: data!)
            }
        }
        cell.uuidLbl.text = postObj[indexPath.row].value(forKey: "uuid") as? String
        cell.titleLbl.text = postObj[indexPath.row].value(forKey: "title") as? String
        // Place post picture
        (postObj[indexPath.row].value(forKey: "pic") as! PFFile).getDataInBackground {
            (data, error) in
            cell.picImg.image = UIImage(data: data!)
        }
        // Calculate post date
        let from = postObj[indexPath.row].value(forKey: "createdAt") as? Date
        let now = Date()
        let difference = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfMonth], from: from!, to: now)
        
        // Logic what to show: seconds, minutes, hours, ...
        if difference.second! <= 0 {
            cell.dateLbl.text = "now"
        }
        var duration : String = ""
        if difference.second! > 0 && difference.minute! == 0 {
            switch difference.second! {
            case 1:
                duration = "second ago"
            default:
                duration = "seconds ago"
            }
            cell.dateLbl.text = "\(difference.second!) \(duration)"
        }
        if difference.minute! > 0 && difference.hour! == 0 {
            switch difference.minute! {
            case 1:
                duration = "minute ago"
            default:
                duration = "minutes ago"
            }
            cell.dateLbl.text = "\(difference.minute!) \(duration)"
        }
        if difference.hour! > 0 && difference.day! == 0 {
            switch difference.hour! {
            case 1:
                duration = "hour ago"
            default:
                duration = "hours ago"
            }
            cell.dateLbl.text = "\(difference.hour!) \(duration)"
        }
        if difference.day! > 0 && difference.weekOfMonth! == 0 {
            switch difference.day! {
            case 1:
                duration = "day ago"
            default:
                duration = "days ago"
            }
            cell.dateLbl.text = "\(difference.day!) \(duration)"
        }
        if difference.weekOfMonth! > 0 {
            switch difference.weekOfMonth! {
            case 1:
                duration = "week ago"
            default:
                duration = "weeks ago"
            }
            cell.dateLbl.text = "\(difference.weekOfMonth!) \(duration)"
        }
        
        // location name
        if let locationname = postObj[indexPath.row].value(forKey: "restname") as? String
        {
            cell.locationnameBtn.setTitle( locationname, for: UIControlState())
            cell.locationnameBtn.sizeToFit()
        } else {
            cell.locationnameBtn.setTitle("", for: .normal)
        }
        
        // Manipulate like button depending on did we user like it or not
        let didLike = PFQuery(className: "likes")
        didLike.whereKey("by", equalTo: PFUser.current()!)
        didLike.whereKey("to", equalTo: cell.uuidLbl.text!)
        didLike.countObjectsInBackground {
            (count, error) in
            if count == 0 {
                cell.likeBtn.setTitle("unlike", for: .normal)
                cell.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: .normal)
            } else {
                cell.likeBtn.setTitle("like", for: .normal)
                cell.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: .normal)
            }
        }
        
        // Count total likes of the post
        let countLikes = PFQuery(className: "likes")
        countLikes.whereKey("to", equalTo: cell.uuidLbl.text!)
        countLikes.countObjectsInBackground {
            (count, error) in
            cell.likeLbl.text = String(count)
        }
        
        // Asign PFUser data
        cell.usernameBtn.layer.setValue(postObj[indexPath.row].value(forKey: "user") as! PFUser, forKey: "user")
        cell.commentBtn.layer.setValue(indexPath, forKey: "index")
        cell.moreBtn.layer.setValue(indexPath, forKey: "index")
        cell.locationnameBtn.layer.setValue(indexPath, forKey: "index")

        // @mention is tapped
        cell.titleLbl.userHandleLinkTapHandler = { label, handle, rang in
            var mention = handle
            mention = String(mention.dropFirst())
            
            // Find user
            let userQuery = PFUser.query()
            userQuery?.whereKey("username", equalTo: mention)
            userQuery?.findObjectsInBackground {
                (objects, error) in
                if error == nil {
                    if objects?.isEmpty == false {
                        for object in objects! {
                            // Add found data to arrays
                            self.mentionedUser = object as! PFUser
                        }
                        
                        // if tapped on @currentUser go home, else go guest
                        if self.mentionedUser.objectId == PFUser.current()?.objectId {
                            let home = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! homeVC
                            self.navigationController?.pushViewController(home, animated: true)
                        } else {
                            guestptArray.append(self.mentionedUser)
                            let guest = self.storyboard?.instantiateViewController(withIdentifier: "guestVC") as! guestVC
                            self.navigationController?.pushViewController(guest, animated: true)
                        }
                        
                    } else {
                        
                        // Zero user - Create Alert
                        let alert = UIAlertController(title: "Error", message: "Couldn't find the user", preferredStyle: .alert)
                        
                        // Display Alert
                        self.present(alert, animated: true){
                            // Close Alert
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                alert.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                } else {
                    
                    print(error!.localizedDescription)
                    
                }
            }
        }
        
        // #hashtag is tapped
        cell.titleLbl.hashtagLinkTapHandler = { rabel, handle, range in
            
            var mention = handle
            mention = String(mention.dropFirst())
            let hashvc = self.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! hashtagsVC
            hashvc.hashtag.append(mention)
            self.navigationController?.pushViewController(hashvc, animated: true)
        }
        
        return cell
    }
    
    // Clicked uername button
    @IBAction func userBtn_click(_ sender: Any) {
        
        // Take PFUser from button
        let userpt = (sender as AnyObject).layer.value(forKey: "user") as? PFUser
        
        // Check who is the owner of the post
        if userpt?.objectId == PFUser.current()?.objectId {
            // Go to home
            let home = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! homeVC
            self.navigationController?.pushViewController(home, animated: true)
        } else {
            // Go to guest
            guestptArray.append(userpt!)
            let guest = self.storyboard?.instantiateViewController(withIdentifier: "guestVC") as! guestVC
            self.navigationController?.pushViewController(guest, animated: true)
        }
    }
    
    
    // click location button
    @IBAction func locationBtn_click(_ sender: Any) {
        
        // Go to locationmapVC to show location on map
        let mapvc = self.storyboard?.instantiateViewController(withIdentifier: "locationmapVC") as! locationmapVC
        let indexPath = (sender as AnyObject).layer?.value(forKey: "index") as! IndexPath
        let locationData = LocationData()
        if let geolocation = postObj[indexPath.row].value(forKey: "location") as? PFGeoPoint {

            // get geo data
            locationData.location = geolocation
            locationData.name = self.postObj[indexPath.row].value(forKey: "restname") as? String
            mapvc.selectedLocation = locationData
            self.navigationController?.pushViewController(mapvc, animated: true)
        }
    }
    
    // Clicked comment button
    @IBAction func commentBtn_click(_ sender: Any) {
        
        // Take indexPath from button object
        let indexPath = (sender as! UIButton).layer.value(forKey: "index") as! IndexPath
        // Go to comments. present vc
        let comment = self.storyboard?.instantiateViewController(withIdentifier: "commentVC") as! commentVC
        // Data succession
        comment.postObj.append(postObj[indexPath.row])
        // Execute
        self.navigationController?.pushViewController(comment, animated: true)
    }
    
    // Refresh function
    @objc func refresh() {
        self.tableView.reloadData()
    }
    
    // Clicked more button
    @IBAction func moreBtn_click(_ sender: Any) {
        
        // Call index of button
        let indexPath = (sender as! UIButton).layer.value(forKey: "index") as! IndexPath
        // Call cell to call further cell data
        let cell = tableView.cellForRow(at: indexPath) as! postCell
        // Delete action
        let delete = UIAlertAction(title: "Delete", style: .default) { (UIAlertAction) in
            
            // STEP 1. Delete row from table
            self.postObj.remove(at: indexPath.row)
            // STEP 2. Delete post from server
            let postQuery = PFQuery(className: "posts")
            postQuery.whereKey("uuid", equalTo: cell.uuidLbl.text!)
            postQuery.findObjectsInBackground{
                (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground{
                            (success, error) in
                            if success {
                                // Send notification to root ViewController to update shown posts
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uploaded"), object: nil)
                                // Push back
                                self.navigationController?.popViewController(animated: true)
                            } else {
                                print(error!.localizedDescription)
                            }
                        }
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
            // STEP 3. Delete comment from server
            let commentQuery = PFQuery(className: "comments")
            commentQuery.whereKey("postuuid", equalTo: cell.uuidLbl.text!)
            commentQuery.findObjectsInBackground{ (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteEventually()
                    }
                }
            }
            // STEP 4. Delete like from server
            let likeQuery = PFQuery(className: "likes")
            likeQuery.whereKey("to", equalTo: cell.uuidLbl.text!)
            likeQuery.findObjectsInBackground{ (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteEventually()
                    }
                }
            }
            // STEP 5. Delete hashtag from server
            let hashQuery = PFQuery(className: "hashtags")
            hashQuery.whereKey("postuuid", equalTo: cell.uuidLbl.text!)
            hashQuery.findObjectsInBackground{ (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteEventually()
                    }
                }
            }
        }
        
        // Complain Action
        let complain = UIAlertAction(title: "Complain", style: .default) { (UIAlertAction) in
            
            // Send complain to server
            let complainObj = PFObject(className: "complain")
            complainObj["by"] = PFUser.current()!
            complainObj["uuid"] = self.postObj[indexPath.row].value(forKey: "uuid") as! String
            complainObj["post"] = self.postObj[indexPath.row]
            complainObj["owner"] = self.postObj[indexPath.row].value(forKey: "user") as! PFUser
            
            complainObj.saveInBackground{ (success, error) in
                if success {
                    self.alert(title: "Complain has been made successfully", message: "Thank you! We will consider your complain")
                } else {
                    self.alert(title: "ERROR", message: error!.localizedDescription)
                }
            }
        }
        
        // Cancel Action
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Create menu controller
        let menu = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        
        // If post belongs to user you can delete post, else you can't
        if PFUser.current()?.objectId == (postObj[indexPath.row].value(forKey: "user") as! PFUser).objectId {
            menu.addAction(delete)
            menu.addAction(cancel)
        } else {
            menu.addAction(complain)
            menu.addAction(cancel)
        }
        
        // Show menu
        self.present(menu, animated: true, completion: nil)
    }
    
    // Alert action
    func alert (title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Go back function
    @objc func back() {
        
        // Push back
        self.navigationController?.popViewController(animated: true)
        
        // Clean coment uuid from last hold
        if !postuuid.isEmpty {
            postuuid.removeLast()
        }
    }
}
