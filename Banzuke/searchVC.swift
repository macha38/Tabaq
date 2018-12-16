//
//  searchVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/2/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD


// delegation for reflect feedbacks from filterVC
protocol searchVCDelegate {
    func getConditionFromFilterVC(conditionId: Int)
}

class searchVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, searchVCDelegate {

    // GeoPoint setting
    let manager = CLLocationManager()
    
    // Declare search bar
    var searchBar = UISearchBar()
    
    // refresher variable
    var refresher : UIRefreshControl!
    
    // UI objects
    let page : Int = 100
    let searchpage : Int = 300
    var readPage = 0
    
    // Arrays to hold data from server
    var postsptArray = [PFObject?]()
    
    // serch uuid
    var ordersetuuid = [String]()
    
    // Search location
    var searchlocation : PFGeoPoint!
    
    // date
    var filterDate : Date!
    
    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CLLocation Delegate
        manager.delegate = self
        
        // Be able to pull down even if a few post
        self.collectionView?.alwaysBounceVertical = true

        // Implement search bar to navigation bar
        searchBar.delegate = self
        searchBar.placeholder = "#hashtag"
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): UIColor.white], for: .normal)
        searchBar.sizeToFit()
        searchBar.tintColor = UIColor.flatGray()
        searchBar.autocapitalizationType = .none
        searchBar.frame.size.width = self.view.frame.size.width - 75
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = searchItem
        
        // leftbar button
        self.navigationItem.hidesBackButton = true
        let filterBtn = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        self.navigationItem.leftBarButtonItem = filterBtn
        
        // Confirm location authorize setting
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            manager.requestWhenInUseAuthorization()
        }
        
        // pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        collectionView?.addSubview(refresher)
        
        // get filter condition
        let conditionId : Int? = UserDefaults.standard.integer(forKey: "searchfilter")
        filterDate = conditionIdtoDate(conditionId: conditionId!)

        // loading
        SVProgressHUD.show()

        // Get current location
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            if error == nil {
                // Display nearby food photo
                self.searchlocation = geopoint!
                self.loadPosts()
            } else {
                // Handle with the error
                print("Geo Error")
            }
        }
    }
    
    // White status bar function
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    // Request current location when authorize status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    // Get current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locations : \(locations)")
    }
    
    // Fail getting current location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error = \(error)")
    }

    
    // refreshing function
    @objc func refresh() {
        if searchBar.text?.isEmpty == true {
            loadPosts()
        } else {
            loadPostsWithHashtag()
        }
    }

    
    // Load posts function
    func loadPosts() {
        
        // get current location
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            
            if error == nil {
                
                // Display nearby food photo
                self.searchlocation = geopoint!
                
                // Clean Up
                self.postsptArray.removeAll(keepingCapacity: false)
                
                // Load posts
                let query = PFQuery(className: "posts")
                if let filtdt = self.filterDate {
                    query.whereKey("createdAt", greaterThanOrEqualTo: filtdt)
                }
                query.whereKey("location", nearGeoPoint: self.searchlocation)
                query.limit = self.page
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

                        // loading
                        SVProgressHUD.dismiss()
                        self.refresher.endRefreshing()
                        self.collectionView?.reloadData()

                        
                    } else {
                        print(error!.localizedDescription)
                    }
                }
            } else {
                // Handle with the error
                print("Geo Error")
            }
        }
    }

    
    // Load more while scrolling down
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height - 50 {
            if searchBar.text?.isEmpty == true {
                self.loadMore()
            } else {
                self.loadMoreWithHashtag()
            }
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
            if let filtdt = filterDate {
                query.whereKey("createdAt", greaterThanOrEqualTo: filtdt)
            }
            query.whereKey("location", nearGeoPoint: searchlocation)
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
 
    
    // MARK: Start searching
    // Clicked search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        // Container for searching word
        var searchwords = [String]()

        // dismiss keyboard
        searchBar.resignFirstResponder()

        // hide cancel button
        searchBar.showsCancelButton = false

        // Extract search word
        let words:[String] = searchBar.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Define word
        for var word in words {
            // Save #hashtag in server
            if word.hasPrefix("#") {
                // Cut symbol
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
            }
            searchwords.append(word.lowercased())
        }
        
        // loading
        SVProgressHUD.show()

        // TODO: 1.Load posts from hashtag class
        let hashquery = PFQuery(className: "hashtags")
        hashquery.whereKey("hashtag", containedIn: searchwords)
//        hashquery.includeKey("postspt")
        hashquery.addDescendingOrder("postuuid")
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
                
                self.loadPostsWithHashtag()
                
                
            } else {
                // loading end
                SVProgressHUD.dismiss()

                print(hasherror!.localizedDescription)
            }
        }
    }
    
    
    // load post from hashtag
    func loadPostsWithHashtag() {

        // get current location
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            
            if error == nil {
                
                // Display nearby food photo
                self.searchlocation = geopoint!
                // Clean Up
                self.postsptArray.removeAll(keepingCapacity: false)
                
                // TODO: 2.Search posts from posts class
                let postquery = PFQuery(className: "posts")
                postquery.whereKey("uuid", containedIn: self.ordersetuuid)
                if let filtdt = self.filterDate {
                    postquery.whereKey("createdAt", greaterThanOrEqualTo: filtdt)
                }
                postquery.whereKey("location", nearGeoPoint: self.searchlocation)
                postquery.limit = self.searchpage
                postquery.findObjectsInBackground {
                    
                    (postobjects, posterror) in
                    if posterror == nil {
                        
                        // Find related objects
                        for object in postobjects! {
                            
                            // Hold found information in arrays
                            self.postsptArray.append(object)
                        }
                        
                        // reload data
                        self.refresher.endRefreshing()
                        self.collectionView?.reloadData()
                        // loading end
                        SVProgressHUD.dismiss()

                        
                    } else {
                        print(posterror!.localizedDescription)
                        // loading end
                        SVProgressHUD.dismiss()

                    }
                }
            } else {
                
                // loading end
                SVProgressHUD.dismiss()

                // Handle with the error
                print("Geo Error")
            }
        }
    }
    
    
    // paging
    func loadMoreWithHashtag() {
        
        // If there is more objects
        if readPage <= postsptArray.count {
            
            // Count up maximum read
            readPage += page
            // Load more posts
            let query = PFQuery(className: "posts")
            query.whereKey("uuid", containedIn: ordersetuuid)
            if let filtdt = filterDate {
                query.whereKey("createdAt", greaterThanOrEqualTo: filtdt)
            }
            query.whereKey("location", nearGeoPoint: searchlocation)
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



    // tapped on the searchBar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        // show cancel button
        searchBar.showsCancelButton = true
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): UIColor.white], for: .normal)
    }
    
    
    // clicked cancel button
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        // dismiss keyboard
        searchBar.resignFirstResponder()
        
        // hide cancel button
        searchBar.showsCancelButton = false
        
        // reset text
        searchBar.text = ""
    }
    
    
    // display all when searchbar is empty
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.isEmpty {
                loadPosts()
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
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! picwdistCell
        
        // provisional mesures to this method called before reading data when refreshing
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
        
        // distance
        let geo = postsptArray[indexPath.row]?.value(forKey: "location") as! PFGeoPoint
        let distance = searchlocation.distanceInKilometers(to: geo)
        if distance < 10.0 {
            cell.distanceLbl.text = "\(String(format: "%.2f", distance)) km"
        } else {
            cell.distanceLbl.text = "\(String(format: "%.0f", distance)) km"
        }
        cell.distanceLbl.textAlignment = .right
        
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
    
    
    // filter function
    @objc func filter() {
        let filter = self.storyboard?.instantiateViewController(withIdentifier: "filterVC") as! filterVC
        filter.searchDelegate = self
        present(filter, animated: false, completion: nil)
    }
    
    
    // filter the search result
    func getConditionFromFilterVC(conditionId: Int) {

        // keep condition
        UserDefaults.standard.set(conditionId, forKey: "searchfilter")
        UserDefaults.standard.synchronize()

        // calc past date
        filterDate = conditionIdtoDate(conditionId: conditionId)

        if searchBar.text?.isEmpty == true {
            loadPosts()
        } else {
            loadPostsWithHashtag()
        }
        
        // reload data
        collectionView?.reloadData()
    }

    
    // conditionId to Date
    func conditionIdtoDate(conditionId: Int) -> Date? {
        
        // components for past date
        var components = DateComponents()
        var retDate: Date?
        
        // appoint date
        switch conditionId {
            
        // last 24 hours
        case 1:
            components.hour = 24 * (-1)
            // calc past date
            retDate = Calendar.current.date(byAdding: components, to: Date())
            
        // last 3 days
        case 2:
            components.day = 3 * (-1)
            // calc past date
            retDate = Calendar.current.date(byAdding: components, to: Date())
            
        // last 7 days
        case 3:
            components.day = 7 * (-1)
            // calc past date
            retDate = Calendar.current.date(byAdding: components, to: Date())
            
        // last 1 months
        case 4:
            components.month = 1 * (-1)
            // calc past date
            retDate = Calendar.current.date(byAdding: components, to: Date())

        // all
        default:
            break
        }

        return retDate
    }

}
