//
//  hashtagsVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 8/2/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse


class hashtagsVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // For data succession
    var hashtag = [String]()
    // UI objects
    var refresher : UIRefreshControl!
    let page : Int = 100
    var readPage = 0
    
    // serch uuid
    var ordersetuuid = [String]()

    // Arrays to hold data from server
    var postsptArray = [PFObject?]()

    // Default function
    override func viewDidLoad() {
        super.viewDidLoad()

        // Be able to pull down even if a few post
        self.collectionView?.alwaysBounceVertical = true
        
        // Title at the top
        self.navigationItem.title = "#" + "\(hashtag.last!)"
        
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

        // Call function of loading hashtags
        loadHashtags()
    }

    // Back function
    @objc func back(sender: UIBarButtonItem){
        // Push Back (go back to previous view under navigation view)
        self.navigationController?.popViewController(animated: true)
        // Clean hashtag from hashtag array
        if !hashtag.isEmpty {
            hashtag.removeLast()
        }
    }
    // Refresh function
    @objc func refresh(){
        // Call refresh
        loadHashtags()
    }
    
    // Load hashtags function
    func loadHashtags() {
        
        // TODO: 1.Load posts from hashtag class
        let hashquery = PFQuery(className: "hashtags")
        hashquery.whereKey("hashtag", equalTo: hashtag.last!.lowercased() )
        hashquery.addDescendingOrder("createdAt")
        hashquery.findObjectsInBackground {
            
            (hashobjects, hasherror) in
            if hasherror == nil {
                
                var searchuuid = [String]()
                
                // Find related objects
                for object in hashobjects! {
                    
                    searchuuid.append(object.value(forKey: "postuuid") as! String)
                }
                
                // Remove duplication
                self.ordersetuuid.removeAll(keepingCapacity: false)
                self.ordersetuuid = NSOrderedSet(array: searchuuid).array as! [String]
                
                self.loadPostsFromHashtags()
                
                
            } else {
                print(hasherror!.localizedDescription)
            }
        }
    }
    
    
    // Load posts
    func loadPostsFromHashtags() {


        // Clean Up
        self.postsptArray.removeAll(keepingCapacity: false)

        // Load posts
        let query = PFQuery(className: "posts")
        query.whereKey("uuid", containedIn: self.ordersetuuid)
        query.addDescendingOrder("createdAt")
        query.limit = page
        query.findObjectsInBackground {
            
            (objects, error) in
            if error == nil {

                // Maximum read num
                self.readPage = self.page
                // Find related objects
                for object in objects! {
                    // Hold found information in arrays
                    self.postsptArray.append(object)
                }
                self.refresher.endRefreshing()
                self.collectionView?.reloadData()
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    // Load more while scrolling down
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height - 50 {
            self.loadMore()
        }
    }
    
    // Paging
    func loadMore() {
        
        // If there is more objects
        if readPage <= postsptArray.count {
            
            // Count up maximum read
            readPage += page
            // Load more posts
            let query = PFQuery(className: "posts")
            query.whereKey("uuid", containedIn: self.ordersetuuid)
            query.addDescendingOrder("createdAt")
            query.limit = page
            query.skip = postsptArray.count
            
            query.findObjectsInBackground {
                (objects, error) in
                if error == nil {
                    
                    self.collectionView?.performBatchUpdates({
                        // Find related objects
                        for object in objects! {
                            // Hold found information in arrays
                            self.postsptArray.append(object)
                            let insertIndexPath = IndexPath(item: self.postsptArray.count - 1, section: 0)
                            self.collectionView?.insertItems(at: [insertIndexPath])
                        }
                    }, completion: nil)

                } else {
                    print(error!.localizedDescription)
                }
            }
        }
    }

    // MARK: Cell
    // TODO: Cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width : CGFloat = (self.view.frame.size.width - 3) / 4
        let height = width
        return CGSize(width: width, height: height)
    }
    
    // TODO: Cell Number
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postsptArray.count
    }
    
    // TODO: Cell Config
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! pictureCell
        
        if postsptArray.count == 0 {
            return cell
        }
    
        // Configure the cell
        if let postpointer = postsptArray[indexPath.row]?.value(forKey: "pic") as? PFFile {
            postpointer.getDataInBackground {
                (data: Data?, error: Error?) in
                if error == nil {
                    cell.picImg.image = UIImage(data: data!)
                    
                } else {
                    print(error!.localizedDescription)
                }
            }
        }
        
        return cell
    }

    // MARK: Tap gesture functions
    // TODO: Go Post
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Navigate to post view controller
        let post = self.storyboard?.instantiateViewController(withIdentifier: "postVC") as! postVC
        // Send post uuid to "postuuid" variable
        post.postuuid.append(postsptArray[indexPath.row]?.value(forKey: "uuid") as! String)
        self.navigationController?.pushViewController(post, animated: true)
    }

}
