//
//  homeVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 2/28/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD


class homeVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // refresher variable
    var refresher : UIRefreshControl!
    
    // loading size of page
    let page : Int = 20
    var readPage = 0
    
    var uuidArray = [String]()
    var picArray = [PFFile]()
    
    // Storage for avator image
    var avatorImage : UIImage?
    
    // Read header or not
//    var readheader = false
    
    // default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // always vertical scroll
        collectionView?.alwaysBounceVertical = true
        
        // background color
        collectionView?.backgroundColor = UIColor.white
        
        // title at the top
        navigationItem.title = PFUser.current()?.username
        
        // pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        collectionView?.addSubview(refresher)
        
        // Receive notification from editVC
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: "reload"), object: nil)
        
        // Receive notification from upload VC
        NotificationCenter.default.addObserver(self, selector: #selector(uploaded), name: NSNotification.Name(rawValue: "uploaded"), object: nil)

        // loading
        SVProgressHUD.show()

        // load post func
        loadPosts()
    }

    // MARK: Implemented actions
    // Reloading func
    @objc func reload() {
        // Only header data will be read again
        collectionView?.reloadData()
    }
    // refreshing function
    @objc func refresh() {
        // reload data information
        loadPosts()
    }
    // Photo upload function
    @objc func uploaded() {
        loadPosts()
    }
    
    // Detect if Back button on Navigation Controller pressed
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParentViewController {
            if let follow = self.getPreviousViewController() as? followersVC {
                follow.reloadAll()
            } /*else if let comment = self.getPreviousViewController() as? commentVC {
                comment.tabBarController?.tabBar.isHidden = true
                self.hidesBottomBarWhenPushed = true
            }*/
        }
    }
    
    // MARK: Data loading functions
    // load posts func
    func loadPosts(){
        
        // clean up
        self.uuidArray.removeAll(keepingCapacity: false)
        self.picArray.removeAll(keepingCapacity: false)
        
        let query = PFQuery(className: "posts")
        query.whereKey("user", equalTo: PFUser.current()!)
        query.limit = page
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects, error) in
            if error == nil {
                // Maximum read num
                self.readPage = self.page
                for object in objects! {
                    
                    // add found data to arrays
                    self.uuidArray.append(object.value(forKey: "uuid") as! String)
                    self.picArray.append(object.value(forKey: "pic") as! PFFile)
                    
                }
                
                // Reload and stop refresher
                self.collectionView?.reloadData()
                self.refresher.endRefreshing()
                
                // loading end
                SVProgressHUD.dismiss()

                
            } else {
                print(error!.localizedDescription)
                self.refresher.endRefreshing()
                // loading end
                SVProgressHUD.dismiss()
            }
        }
    }
    
    // Load more while scrolling down
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height - 80 {

            // load more
            loadMore()
        }
    }
    
    
    // Paging
    func loadMore() {
        
       // If there is more objects
        if readPage <= picArray.count {

            // Count up maximum read
            readPage += page
            // Load more posts
            let query = PFQuery(className: "posts")
            query.whereKey("user", equalTo: PFUser.current()!)
            query.limit = page
            query.skip = picArray.count
            query.addDescendingOrder("createdAt")
            query.findObjectsInBackground {
                (objects, error) in
                if error == nil {
                    
                    self.collectionView?.performBatchUpdates({
                        // Find related objects
                        for object in objects! {
                            
                            self.uuidArray.append(object.value(forKey: "uuid") as! String)
                            self.picArray.append(object.value(forKey: "pic") as! PFFile)
                            
                            let insertIndexPath = IndexPath(item: self.uuidArray.count - 1, section: 0)
                            self.collectionView?.insertItems(at: [insertIndexPath])
                            
                        }
                    }, completion: nil)

                } else {
                    print(error!.localizedDescription)
                }
            }
        }
    }
    
    
    // MARK: Configure Picture Cell
    // adjust cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width : CGFloat = (self.view.frame.size.width - 3) / 4
        let height = width
        return CGSize(width: width, height: height)
    }
    // cell number
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uuidArray.count
    }
    // cell config - (this func called by reloadData()?) * cell number
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // define cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! pictureCell
        
        if uuidArray.count == 0 {
            return cell
        }
       
        // get picture from picArray
        picArray[indexPath.row].getDataInBackground {
            (data: Data?, error: Error?) in
            if error == nil {
                cell.picImg.image = UIImage(data: data!)
                
            } else {
                print(error!.localizedDescription)
            }
        }
        return cell
    }
    
    
    // MARK: Configure Header Data
    // Header config
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // define header
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! headerView
        
        // STEP 1. Get User Data
        // get user data with connections to collumns of PFUser class
        header.bioLbl.text = PFUser.current()?.object(forKey: "bio") as? String
        header.bioLbl.sizeToFit()
        
        let avaQuery = PFUser.current()?.object(forKey: "ava") as! PFFile
        avaQuery.getDataInBackground {
            (data, error) in
            header.avaImg.image = UIImage(data: data!)
            // Round ava
            header.avaImg.layer.cornerRadius = header.avaImg.frame.size.width / 2
            header.avaImg.clipsToBounds = true
            // Preserve Avator image
            self.avatorImage = UIImage(data: data!)
        }
        header.button.setTitle("Edit Profile", for: UIControlState.normal)
        
        // STEP 2. Count Statistics
        // Count total posts
        let posts = PFQuery(className: "posts")
        posts.whereKey("user", equalTo: PFUser.current()!)
        posts.countObjectsInBackground {
            (count: Int32, error: Error?) in
            if error == nil {
                header.posts.text = "\(count)"
            } else {
                print(error!.localizedDescription)
            }
        }
        // count total followings - follower is current user
        let followers = PFQuery(className: "follow")
        followers.whereKey("followerpt", equalTo: PFUser.current()!)
        followers.countObjectsInBackground { (count: Int32, error: Error?)
            in
            if error == nil {
                header.followings.text = "\(count)"
            } else {
                print(error!.localizedDescription)
            }
        }
        // count total followers - someone who follows current user
        let followings = PFQuery(className: "follow")
        followings.whereKey("followingpt", equalTo: PFUser.current()!)
        followings.countObjectsInBackground { (count: Int32, error: Error?)
            in
            if error == nil {
                header.followers.text = "\(count)"
            } else {
                print(error!.localizedDescription)
            }
        }
        
        // STEP 3. Implement tap gestures
        let postsTap =  UITapGestureRecognizer(target: self, action: #selector(dispPostsTap))
        postsTap.numberOfTapsRequired = 1
        header.posts.isUserInteractionEnabled = true
        header.posts.addGestureRecognizer(postsTap)
        
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(dispFollowersTap))
        followersTap.numberOfTapsRequired = 1
        header.followers.isUserInteractionEnabled = true
        header.followers.addGestureRecognizer(followersTap)

        let followingsTap = UITapGestureRecognizer(target: self, action: #selector(dispFollowingsTap))
        followingsTap.numberOfTapsRequired = 1
        header.followings.isUserInteractionEnabled = true
        header.followings.addGestureRecognizer(followingsTap)
        

        return header
    }
    
    // dynamic header height..
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

////        let views = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader) as? [headerView]
////        for view in views! {
////            let text = view.bioLbl.text
////        }
        
        
//        return CGSize(width: collectionView.frame.width, height: 205)
//    }
    
    

    // MARK: Tap and select actions
    // TODO: tapped post label
    @objc func dispPostsTap(recognizer: UITapGestureRecognizer) {
        
        if !picArray.isEmpty {
            
            let index = IndexPath(item: 0, section: 0)
            self.collectionView?.scrollToItem(at: index, at: UICollectionViewScrollPosition.top, animated: true)
        }
    }
    // TODO: Tapped follwers label
    @objc func dispFollowersTap(recognizer: UITapGestureRecognizer) {
        dispUser = PFUser.current()!
        disptrg = "Followers"
        // make references to followersVC
        let followers = self.storyboard?.instantiateViewController(withIdentifier: "followersVC") as! followersVC
        self.navigationController?.pushViewController(followers, animated: true)
    }
    // TODO: Tapped followings label
    @objc func dispFollowingsTap(recognizer: UITapGestureRecognizer) {
        
        dispUser = PFUser.current()!
        disptrg = "Followings"
        // make references to followersVC
        let followings = self.storyboard?.instantiateViewController(withIdentifier: "followersVC") as! followersVC
        self.navigationController?.pushViewController(followings, animated: true)
    }
    // TODO: Go post
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Navigate to post view controller
        let post = self.storyboard?.instantiateViewController(withIdentifier: "postVC") as! postVC
        // Send post uuid to "postuuid" variable
        post.postuuid.append(uuidArray[indexPath.row])
        self.navigationController?.pushViewController(post, animated: true)
    }
    // TODO: Clicked LogOut
    @IBAction func logOut_click(_ sender: Any) {
        PFUser.logOutInBackground {
            (error) in
            if error == nil {

                // Remove logged in user from App memory
                UserDefaults.standard.removeObject(forKey: "username")
                UserDefaults.standard.removeObject(forKey: "userid")
                UserDefaults.standard.synchronize()

                let signin = self.storyboard?.instantiateViewController(withIdentifier: "signInVC") as! signinVC
                let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = signin

            }
        }
    }
    
}
