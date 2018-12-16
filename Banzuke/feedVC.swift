//
//  feedVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 8/13/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

// Delegation for refreshing view
protocol FeedVCDelegate {
    func addlike(postuuid: String)
    func sublike(postuuid: String)
}

class feedVC: UITableViewController, FeedVCDelegate {
    
    // UI objects
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var refresher = UIRefreshControl()
    
    // arrays to hold server data
    var postObj = [PFObject]()
    var followArray = [PFObject]()
    var uuidArray = [String]()
    // Mentioned user
    var mentionedUser = PFUser()

    // page size
    var page : Int = 20
    let moreload : Int = 10
    
    // default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title at the top
        self.navigationItem.title = "Feed"
        
        // automatic row height - dynamic cell
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 550
        
        // pull to refresh
        refresher.addTarget(self, action: #selector(loadPosts), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresher)
        
        // receive notification from postsCell if picture is liked, to update tableView
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "liked"), object: nil)
        
        // indicator's x(horizontal) center
        indicator.center.x = tableView.center.x
        
        // receive notification from uploadVC
        NotificationCenter.default.addObserver(self, selector: #selector(uploaded), name: NSNotification.Name(rawValue: "uploaded"), object: nil)
        
       // Get all postuuid from which this user liked and then loadPost
        getPostsUuid()
    }
    
    
    // refreshign function after like to update degit
    @objc func refresh() {
        tableView.reloadData()
    }
    
    // reloading func with posts  after received notification
    @objc func uploaded(_ notification:Notification) {
        loadPosts()
    }
    
    // Change likes feedback from postCell
    func addlike(postuuid: String) {

        uuidArray.append(postuuid)
        
        for object in postObj {
            if object.value(forKey: "uuid") as? String == postuuid {
                if let likecnt = object.value(forKey: "lkcnt") as? Int {
                    object.setValue(likecnt + 1, forKey: "lkcnt")
                } else {
                    object.setValue( 1, forKey: "lkcnt")
                }
                break
            }
        }
    }
    
    // substract target postuuid
    func sublike(postuuid: String) {
        var num = 0
        for uuid in uuidArray {
            if uuid == postuuid {
                uuidArray.remove(at: num)
                break
            }
            num += 1
        }
        
        for object in postObj {
            if object.value(forKey: "uuid") as? String == postuuid {
                if let likecnt = object.value(forKey: "lkcnt") as? Int {
                    if likecnt > 0 {
                        object.setValue(likecnt - 1, forKey: "lkcnt")
                    } else {
                        object.setValue( 0, forKey: "lkcnt")
                    }
                } else {
                    object.setValue( 0, forKey: "lkcnt")
                }
                break
            }
        }
    }

    // get all postuuid from likes by this user
    func getPostsUuid() {

        let likesQuery = PFQuery(className: "likes")
        likesQuery.whereKey("by", equalTo: PFUser.current()!)
        likesQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                
                // clean up
                self.uuidArray.removeAll(keepingCapacity: false)
                
                // find related objects
                for object in objects! {
                    self.uuidArray.append(object.object(forKey: "to") as! String)
                }
                
                // calling function to load posts
                self.loadPosts()
            }
        }
    }
    
    
    // checking if the user likes this post or not
    func checkLiked( postuuid: String, completion: (Bool) -> Void ){
        
        // does something time consuming
        var isFind = false
        
        if uuidArray.contains(postuuid) == true {
            isFind = true
        }
        
//        for uuid in uuidArray {
//            if postuuid == uuid {
//                isFind = true
//                break
//            }
//        }
        
        completion(isFind)
    }
    
    // load posts
    @objc func loadPosts() {
        
        // STEP 1. Find posts realted to people who we are following
        let followQuery = PFQuery(className: "follow")
        followQuery.whereKey("followerpt", equalTo: PFUser.current()!)
        followQuery.includeKey("followingpt")
        followQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                
                // clean up
                self.followArray.removeAll(keepingCapacity: false)
                
                // find related objects
                for object in objects! {
                    self.followArray.append(object.object(forKey: "followingpt") as! PFObject)
                }
                
                // append current user to see own posts in feed
                self.followArray.append(PFUser.current()!)
                
                // STEP 2. Find posts made by people appended to followArray
                let query = PFQuery(className: "posts")
                query.whereKey("user", containedIn: self.followArray)
                query.includeKey("user")
                query.limit = self.page
                query.addDescendingOrder("createdAt")
                query.findObjectsInBackground{ (objects, error) in
                    if error == nil {
                        
                        // clean up
                        self.postObj.removeAll(keepingCapacity: false)
                        
                        // find related objects
                        for object in objects! {
                            self.postObj.append(object)
                        }
                        
                        if objects?.count == 0 {
                            self.indicator.stopAnimating()
                        }
                        
                        // reload tableView & end spinning of refresher
                        self.tableView.reloadData()
                        self.refresher.endRefreshing()
                        
                    } else {
                        print(error!.localizedDescription)
                    }
                }
            } else {
                self.indicator.stopAnimating()
                print(error!.localizedDescription)
            }
        }
    }
    
    
    // scrolled down
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    
    // pagination
    func loadMore() {
        
        // if posts on the server are more than shown
        if page <= postObj.count {
            
            // start animating indicator
            indicator.startAnimating()
            
            // increase load size
            page = page + moreload
            
            // STEP 1. Find posts realted to people who we are following
            let followQuery = PFQuery(className: "follow")
            followQuery.whereKey("followerpt", equalTo: PFUser.current()!)
            followQuery.includeKey("followingpt")
            followQuery.findObjectsInBackground{ (objects, error) in
                if error == nil {
                    
                    // clean up
                    self.followArray.removeAll(keepingCapacity: false)
                    
                    // find related objects
                    for object in objects! {
                        self.followArray.append(object.object(forKey: "followingpt") as! PFObject)
                    }
                    
                    // append current user to see own posts in feed
                    self.followArray.append(PFUser.current()!)
                    
                    // STEP 2. Find posts made by people appended to followArray
                    let query = PFQuery(className: "posts")
                    query.whereKey("user", containedIn: self.followArray)
                    query.includeKey("user")
                    query.limit = self.page
                    query.addDescendingOrder("createdAt")
                    query.findObjectsInBackground {
                        (objects, error) in
                        if error == nil {
                            
                            // clean up
                            self.postObj.removeAll(keepingCapacity: false)
                            
                            // find related objects
                            for object in objects! {
                                self.postObj.append(object)
                            }
                            
                            // reload tableView & stop animating indicator
                            self.tableView.reloadData()
                            self.indicator.stopAnimating()
                            
                        } else {
                            print(error!.localizedDescription)
                        }
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
            
        }
        
    }
    
    
    // cell numb
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postObj.count
    }


    // Handling dissapear cell
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // define cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! postCell
        // This cell is already disappeare so no need to display like or not
        cell.likeBtn.layer.setValue(false, forKey: "renew")
    }
    
    // cell config
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // define cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! postCell
        //  Pass Delegate
        cell.feedDelegate = self

        // connect objects with our information from arrays
        cell.usernameBtn.setTitle( (postObj[indexPath.row].value(forKey: "user") as! PFUser).username, for: UIControlState())
        cell.usernameBtn.sizeToFit()
        cell.uuidLbl.text = postObj[indexPath.row].value(forKey: "uuid") as? String
        cell.titleLbl.text = postObj[indexPath.row].value(forKey: "title") as? String
        cell.titleLbl.sizeToFit()
        
        // place profile picture
        if let avafile = (postObj[indexPath.row].value(forKey: "user") as! PFUser).value(forKey: "ava") as? PFFile {
            avafile.getDataInBackground { (data, error) in
                if error == nil {
                    if let picdata = data {
                        cell.avaImg.image = UIImage(data: picdata)
                    }
                }
            }
        }
        
        // place post picture
        (postObj[indexPath.row].value(forKey: "pic") as! PFFile).getDataInBackground { (data, error) in
            if error == nil {
                if let picdata = data {
                    cell.picImg.image = UIImage(data: picdata)
                }
            }
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
        
        // Manipulate like button depending on did user like it or not
        cell.likeBtn.layer.setValue(true, forKey: "renew")
        checkLiked(postuuid: cell.uuidLbl.text!) {
            (findflag) in
            // Renew or not
            if cell.likeBtn.layer.value(forKey: "renew") as! Bool == true {
                if findflag == true {
                    cell.likeBtn.setTitle("like", for: .normal)
                    cell.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: .normal)

                } else {
                    cell.likeBtn.setTitle("unlike", for: .normal)
                    cell.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: .normal)

                }
            }
        }
        
        // Count total likes of the post
        if let likecnt = postObj[indexPath.row].value(forKey: "lkcnt") as? Int {
            cell.likeLbl.text = String(likecnt)
        }

        // asign index
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
    

    // clicked username button
    @IBAction func usernameBtn_click(_ sender: AnyObject) {
        
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
    
    // clicked locationname button
    @IBAction func locationnameBtn_click(_ sender: AnyObject) {
        
        // Go to locationmapVC to show location on map
        let mapvc = self.storyboard?.instantiateViewController(withIdentifier: "locationmapVC") as! locationmapVC
        let indexPath = (sender as AnyObject).layer?.value(forKey: "index") as! IndexPath
        let locationData = LocationData()
        locationData.location = postObj[indexPath.row].value(forKey: "location") as? PFGeoPoint
        locationData.name = postObj[indexPath.row].value(forKey: "restname") as? String
        mapvc.selectedLocation = locationData
        self.navigationController?.pushViewController(mapvc, animated: true)
    }
    
    // clicked comment button
    @IBAction func commentBtn_click(_ sender: AnyObject) {
        
        // Take indexPath from button object
        let indexPath = (sender as! UIButton).layer.value(forKey: "index") as! IndexPath
        // Go to comments. present vc
        let comment = self.storyboard?.instantiateViewController(withIdentifier: "commentVC") as! commentVC
        // Data succession
        comment.postObj.append(postObj[indexPath.row])
        // Execute
        self.navigationController?.pushViewController(comment, animated: true)
    }

    // clicked more button
    @IBAction func moreBtn_click(_ sender: AnyObject) {
        
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
    
    // alert action
    func alert (title: String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
}
