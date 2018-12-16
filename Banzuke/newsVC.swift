//
//  newsVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 11/22/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse

class newsVC: UITableViewController {
    
    
    // arrays to hold data from server
    var newsArray = [PFObject]()

    // refresher variable
    var refresher : UIRefreshControl!
    
    // UI objects
    let page : Int = 100
    

    // defualt func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // dynamic tableView height - dynamic cell
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70
        
        // title at the top
        self.navigationItem.title = "Notifications"
        
        // pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresher)
        
        // load news class
        loadNews()
    }

    // load news class
    func loadNews() {
        
        // request notifications
        let query = PFQuery(className: "news")
        query.whereKey("to_userid", equalTo: PFUser.current()!.objectId!)
        query.addDescendingOrder("createdAt")
        query.includeKey("by")
        query.limit = page
        query.findObjectsInBackground { (objects, error) in
            if error == nil {
                
                // clean up
                self.newsArray.removeAll(keepingCapacity: false)
                
                // found related objects
                for object in objects! {
                    self.newsArray.append(object)
                    
                    // save notifications as checked
                    object["checked"] = "yes"
                    object.saveEventually()
                }
                
                // reload tableView to show received data
                self.tableView.reloadData()
            }
            self.refresher.endRefreshing()
        }
    }
    
    // refreshing function
    @objc func refresh() {
        // reload data
        loadNews()
    }

    
    // cell numb
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsArray.count
    }

    // cell config
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // declare cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! newsCell
        
        // connect cell objects with received data from server
        cell.usernameBtn.setTitle((newsArray[indexPath.row].value(forKey: "by") as! PFUser).username, for: UIControlState())
        if let avafile = (newsArray[indexPath.row].value(forKey: "by") as! PFUser).value(forKey: "ava") as? PFFile {
            avafile.getDataInBackground { (data, error) in
                if error == nil {
                    if let picdata = data {
                        cell.avaImg.image = UIImage(data: picdata)
                        cell.avaImg.layer.cornerRadius = cell.avaImg.frame.size.width / 2
                        cell.avaImg.clipsToBounds = true
                    }
                }
            }
        }

        
        // Calculate post date
        let from = newsArray[indexPath.row].value(forKey: "createdAt") as? Date
        let now = Date()
        let difference = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfMonth], from: from!, to: now)
        

        // define info text
        if newsArray[indexPath.row].value(forKey: "type") as! String == "mention" {
            cell.infoLbl.text = "has mentioned you."
            cell.infoLbl.layer.setValue(2, forKey: "value")
        }
        if newsArray[indexPath.row].value(forKey: "type") as! String  == "comment" {
            cell.infoLbl.text = "has commented on your post."
            cell.infoLbl.layer.setValue(2, forKey: "value")
        }
        if newsArray[indexPath.row].value(forKey: "type") as! String  == "follow" {
            cell.infoLbl.text = "now following you."
            cell.infoLbl.layer.setValue(1, forKey: "value")
        }
        if newsArray[indexPath.row].value(forKey: "type") as! String  == "like" {
            cell.infoLbl.text = "likes your post."
            cell.infoLbl.layer.setValue(3, forKey: "value")
        }

        // Logic what to show: seconds, minutes, hours, ...
        var text : String = ""
        if difference.second! <= 0 {
            text = "now"
        }
        var duration : String = ""
        if difference.second! > 0 && difference.minute! == 0 {
            switch difference.second! {
            case 1:
                duration = "second"
            default:
                duration = "seconds"
            }
            text = "\(difference.second!) \(duration)"
        }
        if difference.minute! > 0 && difference.hour! == 0 {
            switch difference.minute! {
            case 1:
                duration = "minute"
            default:
                duration = "minutes"
            }
            text = "\(difference.minute!) \(duration)"
        }
        if difference.hour! > 0 && difference.day! == 0 {
            switch difference.hour! {
            case 1:
                duration = "hour"
            default:
                duration = "hours"
            }
            text = "\(difference.hour!) \(duration)"
        }
        if difference.day! > 0 && difference.weekOfMonth! == 0 {
            switch difference.day! {
            case 1:
                duration = "day"
            default:
                duration = "days"
            }
            text = "\(difference.day!) \(duration)"
        }
        if difference.weekOfMonth! > 0 {
            switch difference.weekOfMonth! {
            case 1:
                duration = "week"
            default:
                duration = "weeks"
            }
            text = "\(difference.weekOfMonth!) \(duration)"
        }
        
        // combine text
        let lentext = cell.infoLbl.text!.count
        let lendttext = text.count
        cell.infoLbl.text?.append(contentsOf: " \(text)")
        
        // change font and size to date part by using attributedString
        let attrText = NSMutableAttributedString(string: cell.infoLbl.text!)
        
        // setting parameter
        attrText.addAttributes([
            .foregroundColor: UIColor.flatGray(),
            .font: UIFont.systemFont(ofSize: 13)
            ], range: NSMakeRange(lentext + 1, lendttext))
        
        // refleect UILabel
        cell.infoLbl.attributedText = attrText
        cell.infoLbl.sizeToFit()
        
        
        // asign index of button
        cell.usernameBtn.layer.setValue(indexPath, forKey: "index")
        cell.usernameBtn.layer.setValue(newsArray[indexPath.row].value(forKey: "by"), forKey: "userpt")
        cell.usernameBtn.layer.setValue(newsArray[indexPath.row].value(forKey: "postuuid"), forKey: "postuuid")

        return cell
    }
    
    
    // clicked username button
    @IBAction func usernameBtn_click(_ sender: AnyObject) {
        
        // call index of button
        let i = sender.layer.value(forKey: "index") as! IndexPath
        
        // call cell to call further cell data
        let cell = tableView.cellForRow(at: i) as! newsCell
        
        // if user tapped on himself go home, else go guest
        let userpt = (cell.usernameBtn.layer.value(forKey: "userpt") as? PFUser)
        if userpt?.objectId == PFUser.current()?.objectId {
            let home = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! homeVC
            self.navigationController?.pushViewController(home, animated: true)
        } else {
            guestptArray.append(userpt!)
            let guest = self.storyboard?.instantiateViewController(withIdentifier: "guestVC") as! guestVC
            self.navigationController?.pushViewController(guest, animated: true)
        }
    }
    
    
    // clicked cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // call cell for calling cell data
        let cell = tableView.cellForRow(at: indexPath) as! newsCell
        
        // going to @menionted comments or own comments
        if cell.infoLbl.layer.value(forKey: "value") as! Int == 2 {

            let query = PFQuery(className: "posts")
            query.whereKey("uuid", equalTo: cell.usernameBtn.layer.value(forKey: "postuuid")!)
            query.findObjectsInBackground { (objects, error) in
                if error == nil {
                    
                    for object in objects! {
                        // go comments
                        let comment = self.storyboard?.instantiateViewController(withIdentifier: "commentVC") as! commentVC
                        comment.postObj.append(object)
                        self.navigationController?.pushViewController(comment, animated: true)
                    }
                }
            }
        }
        
        
        // going to user followed current user
        if cell.infoLbl.layer.value(forKey: "value") as! Int == 1 {

            // take guestname
            let userpt = (cell.usernameBtn.layer.value(forKey: "userpt") as? PFUser)
            guestptArray.append(userpt!)
            let guest = self.storyboard?.instantiateViewController(withIdentifier: "guestVC") as! guestVC
            self.navigationController?.pushViewController(guest, animated: true)
        }
        
        
        // going to liked post
        if cell.infoLbl.layer.value(forKey: "value") as! Int == 3 {

            // go post
            let post = self.storyboard?.instantiateViewController(withIdentifier: "postVC") as! postVC
            post.postuuid.append(cell.usernameBtn.layer.value(forKey: "postuuid") as! String)
            self.navigationController?.pushViewController(post, animated: true)
        }
        
    }
    
}
