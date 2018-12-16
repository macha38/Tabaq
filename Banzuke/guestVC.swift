//
//  guestVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 3/12/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework

// Delegation for refreshing view
protocol GuestVCDelegate {
    func reload()
}

var guestptArray = [PFUser]()

class guestVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, GuestVCDelegate {

    // UI objects
    var refresher : UIRefreshControl!
    let page : Int = 20
    var readPage = 0

    // Arrays to hold data from server
    var uuidArray = [String]()
    var picArray = [PFFile]()
    
    // Read header or not
    var readheader = false
    
    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow vertical scoll
        self.collectionView?.alwaysBounceVertical = true
        // Background collor
        self.collectionView?.backgroundColor = .white
        // Top title
        self.navigationItem.title = guestptArray.last?.username
        // New back button
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = backBtn
        // Swipe to go back
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        // Pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        collectionView?.addSubview(refresher)
        
        // Call load function
        loadPosts()
    }
    
    // Back function
    @objc func back(sender: UIBarButtonItem){
        // Push Back (go back to previous view under navigation view)
        self.navigationController?.popViewController(animated: true)
        // Clean guest username or deduct the last guest username from gurestname array
        if !guestptArray.isEmpty {
            guestptArray.removeLast()
        }
    }
    
    // Only header data will be read again
    func reload() {
        readheader = false
        collectionView?.reloadData()
    }
    
    // Refresh function
    @objc func refresh(){
        readheader = false
        loadPosts()
    }
    
    // Detect if Back button on Navigation Controller pressed
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParentViewController {
            if let follow = self.getPreviousViewController() as? followersVC {
                follow.reloadAll()
            }
        }
    }
    
    // Posts loading function
    func loadPosts() {
        
        // Clean Up
        self.uuidArray.removeAll(keepingCapacity: false)
        self.picArray.removeAll(keepingCapacity: false)
        
        // Load posts
        let query = PFQuery(className: "posts")
        query.whereKey("user", equalTo: guestptArray.last! )
        query.limit = page
        query.addDescendingOrder("createdAt")
       query.findObjectsInBackground {
            (objects, error) in
            if error == nil {
                
                // Maximum read num
                self.readPage = self.page
                // Find related objects
                for object in objects! {
                    
                    // Hold found information in arrays
                    self.uuidArray.append(object.value(forKey: "uuid") as! String)
                    self.picArray.append(object.value(forKey: "pic") as! PFFile)
                }
                // Reload and stop refresher
                self.collectionView?.reloadData()
                self.refresher.endRefreshing()
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    // Load more while scrolling down
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height - 80 {
            self.loadMore()
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
            query.whereKey("user", equalTo: guestptArray.last!)
            query.limit = page  // Read only 15
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
    // TODO: 1.adjust cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width : CGFloat = (self.view.frame.size.width - 3) / 4
        let height = width
        return CGSize(width: width, height: height)
    }

    // TODO: 2.Cell numb
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uuidArray.count
    }
    
    // TODO: 3.Cell config
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // define cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! pictureCell
        
        if picArray.count == 0 {
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
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // TODO: 1.Define Header
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! headerView
        
        // Check if already read or not
        if readheader == true {
            return header
        }
        
        // TODO: 1.5 Pass Delegate
        header.guestDelegate = self
        
        // TODO: 2.Get guestuser Data
        header.bioLbl.text = guestptArray.last?.object(forKey: "bio") as? String
        header.bioLbl.sizeToFit()
        let avaFile = guestptArray.last?.object(forKey: "ava") as? PFFile
        avaFile?.getDataInBackground {
            (data, error) in
            header.avaImg.image = UIImage(data: data!)
            // Round ava
            header.avaImg.layer.cornerRadius = header.avaImg.frame.size.width / 2
            header.avaImg.clipsToBounds = true
        }

        // TODO: 3.Show if current user follow guest or not
        let followQuery = PFQuery(className: "follow")
        followQuery.whereKey("followerpt", equalTo: PFUser.current()!)
        followQuery.whereKey("followingpt", equalTo: guestptArray.last!)
        followQuery.countObjectsInBackground {
            (count, error) in
            if error == nil{
                if count == 0 {
                    header.button.setTitle("Follow", for: .normal)
                    header.button.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
                    header.button.backgroundColor = UIColor.flatYellow()
                    header.button.layer.borderColor = UIColor.flatYellowColorDark().cgColor
                    header.button.layer.borderWidth = 1.0
                    header.button.layer.cornerRadius = header.button.frame.size.width / 20
                } else {
                    
                    // current user follows
                    header.button.setTitle("Following", for: .normal)
                    header.button.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
                    header.button.backgroundColor = UIColor.flatWhite()
                    header.button.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
                    header.button.layer.borderWidth = 1.0
                    header.button.layer.cornerRadius = header.button.frame.size.width / 20
               }
            } else {
                print(error!.localizedDescription)
            }
        }
        
        // TODO: 4.Count statistics
        // Count posts
        let posts = PFQuery(className: "posts")
        posts.whereKey("user", equalTo: guestptArray.last!)
        posts.countObjectsInBackground { (count: Int32, error: Error?)
            in
            if error == nil {
                header.posts.text = "\(count)"
            } else {
                print(error!.localizedDescription)
            }
        }
        // Count total followings - follower is current user
        let followers = PFQuery(className: "follow")
        followers.whereKey("followerpt", equalTo: guestptArray.last!)
        followers.countObjectsInBackground { (count: Int32, error: Error?)
            in
            if error == nil {
                header.followings.text = "\(count)"
            } else {
                print(error!.localizedDescription)
            }
        }
        // Count total followers - someone who follows current user
        let followings = PFQuery(className: "follow")
        followings.whereKey("followingpt", equalTo: guestptArray.last!)
        followings.countObjectsInBackground { (count: Int32, error: Error?)
            in
            if error == nil {
                header.followers.text = "\(count)"
            } else {
                print(error!.localizedDescription)
            }
        }

        // TODO: 5.Implement tap gestures
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
        
        // Finish read header
        readheader = true

        return header
    }
    
    // MARK: Tap gesture functions
    // tapped post label
    @objc func dispPostsTap(recognizer: UITapGestureRecognizer) {
        
        if !picArray.isEmpty {
            
            let index = IndexPath(item: 0, section: 0)
            self.collectionView?.scrollToItem(at: index, at: UICollectionViewScrollPosition.top, animated: true)
        }
    }
    
    // tapped follwers label
    @objc func dispFollowersTap(recognizer: UITapGestureRecognizer) {
        
        dispUser = guestptArray.last!
        disptrg = "Followers"
        
        // make references to followersVC
        let followers = self.storyboard?.instantiateViewController(withIdentifier: "followersVC") as! followersVC
        // present
        self.navigationController?.pushViewController(followers, animated: true)
    }
    
    // tapped followings label
    @objc func dispFollowingsTap(recognizer: UITapGestureRecognizer) {
        
        dispUser = guestptArray.last!
        disptrg = "Followings"
        
        // make references to followersVC
        let followings = self.storyboard?.instantiateViewController(withIdentifier: "followersVC") as! followersVC
        // present
        self.navigationController?.pushViewController(followings, animated: true)
    }
    
    // Go post
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Navigate to post view controller
        let post = self.storyboard?.instantiateViewController(withIdentifier: "postVC") as! postVC
        // Send post uuid to "postuuid" variable
        post.postuuid.append(uuidArray[indexPath.row])
        self.navigationController?.pushViewController(post, animated: true)
    }

}


