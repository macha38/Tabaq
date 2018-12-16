//
//  commentVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 5/15/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import ChameleonFramework

extension UITextView {
    
    func centerText() {
//        self.textAlignment = .center
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
}

class commentVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {

    // UI objects
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTxt: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    
    // Display data which is succeeded from postVC
    var postObj = [PFObject]()

    // Refresh controller
    var refresher = UIRefreshControl()
    
    // Values for reseting UI to default
    var tableViewHeight : CGFloat = 0
    var commentY : CGFloat = 0
    var commentHeight : CGFloat = 0
    var keyboardHeight : CGFloat = 0
    var tabBarHeight : CGFloat = 0
    
    // Arrays to hold comments class
    var commentuuidArray = [String]()
    var userArray = [PFUser]()
    var commentArray = [String]()
    var dateArray = [Date?]()
    
    // Mentioned user
    var mentionedUser = PFUser()
    
    // Variable to hold keyboard frame
    var keyboard = CGRect()
    
    // Page size
    var page : Int32 = 15
    
    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Background color
        tableView.backgroundColor = UIColor.flatWhite()
        
        // Title at the top
        self.navigationItem.title = "Comments"
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = backBtn

        // Swipe to go back
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        self.view.addGestureRecognizer(backSwipe)
        
        // Catch notification if the keyboard is shown or hidden
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
 
        // Declare hide keyboard tap
//        let hideTap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
//        hideTap.numberOfTapsRequired = 1
////        hideTap.cancelsTouchesInView = false  /* When active: @#link works, but "Send" button action becomes weird */
//        self.view.isUserInteractionEnabled = true
//        self.view.addGestureRecognizer(hideTap)
        
        // Hide keyboard by swipe
        tableView.keyboardDismissMode = .interactive
        
        // Disable button
        sendBtn.isEnabled = false
        
        // Call function
        alignment()
        
        // Delegates
        commentTxt.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        // Assign reseting values
        tableViewHeight = tableView.frame.size.height
        commentHeight = commentTxt.frame.size.height
        commentY = commentTxt.frame.origin.y
        tabBarHeight = tabBarController!.tabBar.frame.size.height

        // Load data
        loadComments()
    }

    // MARK: Extra view function
    // Preload func
    override func viewWillAppear(_ animated: Bool) {
        // Hide tab bar
        self.tabBarController?.tabBar.isHidden = true
        // Call keyboard
        commentTxt.becomeFirstResponder()
    }
    // Postload func
    override func viewWillDisappear(_ animated: Bool) {
        
        // Refresh postVC
        if self.isMovingFromParentViewController {
            if let post = self.getPreviousViewController() as? postVC {
                post.refresh()
            }
        }
        // Show tab bar
        self.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: Alignment function
    func alignment() {
        
        // Alignment
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        tableView.frame = CGRect(x: 0, y: 0, width: width, height: height / 1.085/*1.096*/ - self.navigationController!.navigationBar.frame.size.height - UIApplication.shared.statusBarFrame.height)
        tableView.estimatedRowHeight = width / 5.333
        tableView.rowHeight = UITableViewAutomaticDimension

        commentTxt.frame = CGRect(x: 10, y: tableView.frame.size.height + height / 56.8, width: width / 1.306, height: 33)
        commentTxt.layer.cornerRadius = commentTxt.frame.size.width / 50
        
        sendBtn.frame = CGRect(x: commentTxt.frame.origin.x + commentTxt.frame.size.width + width / 32, y: commentTxt.frame.origin.y, width: width - (commentTxt.frame.origin.x + commentTxt.frame.size.width) - (width / 32) * 2, height: commentTxt.frame.size.height)
        
    }

    // MARK: Data loading
    // Load comments function
    func loadComments() {
        
        // TODO: STEP 1. Count total comments in order to skip all except (page size)
        let countQuery = PFQuery(className: "comments")
        countQuery.whereKey("postuuid", equalTo: self.postObj.last!.value(forKey: "uuid") as! String)
        countQuery.countObjectsInBackground {
            (count, error) in
            
            // If comments on the server for current post are more than (page: 15), imprement pull to refresh func
            if self.page < count {
                self.refresher.addTarget(self, action: #selector(self.loadMore), for: .valueChanged)
                self.tableView.addSubview(self.refresher)
            }
            
            // TODO: STEP 2. Request last (page size 15) comments
            let query = PFQuery(className: "comments")
            query.whereKey("postuuid", equalTo: self.postObj.last!.value(forKey: "uuid") as! String)

            query.limit = Int(self.page) // Read max 15 at first
            if count > self.page {
                query.skip = Int(count - self.page)
            }
            query.addAscendingOrder("createdAt")
            query.includeKey("userpt")
            
            query.findObjectsInBackground{
                (objects, error) in
                
                if error == nil {
                    // Clean up
                    self.commentuuidArray.removeAll(keepingCapacity: false)
                    self.userArray.removeAll(keepingCapacity: false)
                    self.commentArray.removeAll(keepingCapacity: false)
                    self.dateArray.removeAll(keepingCapacity: false)
                    
                    // Find related objects
                    for object in objects! {
                        self.commentuuidArray.append(object.object(forKey: "commentuuid") as! String)
                        self.userArray.append(object.object(forKey: "userpt") as! PFUser)
                        self.commentArray.append(object.object(forKey: "comment") as! String)
                        self.dateArray.append(object.createdAt)
                    }
                    
                    // Display data
                    self.tableView.reloadData()
                    // Scroll to bottom
                    if self.commentArray.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: self.commentArray.count - 1, section: 0), at: .bottom, animated: false)
                    }
                    
                } else {
                    print(error!.localizedDescription)
                }
            }
        }
    }
    
    // Pagination
    @objc func loadMore() {
        
        // TODO: STEP 1. Count total comments in order to skip all except (page size = 15)
        let countQuery = PFQuery(className: "comments")
        countQuery.whereKey("postuuid", equalTo: self.postObj.last!.value(forKey: "uuid") as! String)
        countQuery.countObjectsInBackground { (count, error) in
            
            // Self refresher
            self.refresher.endRefreshing()
            
            // Remove refresher if loaded all comments
            if self.page >= count {
                self.refresher.removeFromSuperview()
            }
            
            // TODO: STEP 2. Load more comments
            if self.page < count {
                
                // Increase page to load 30 as first paging
                self.page = self.page + 15
                
                // Request existing comments from the server
                let query = PFQuery(className: "comments")
                query.whereKey("postuuid", equalTo: self.postObj.last!.value(forKey: "uuid") as! String)
                if count > self.page {
                    query.skip = Int(count - self.page)
                }
                query.limit = Int(self.page)
                query.addAscendingOrder("createdAt")
                query.includeKey("userpt")
                query.findObjectsInBackground { (objects, error) in
                    if error == nil {
                        
                        // Clean up
                        self.commentuuidArray.removeAll(keepingCapacity: false)
                        self.userArray.removeAll(keepingCapacity: false)
                        self.commentArray.removeAll(keepingCapacity: false)
                        self.dateArray.removeAll(keepingCapacity: false)
                        
                        // Find related objects
                        for object in objects! {
                            self.commentuuidArray.append(object.object(forKey: "commentuuid") as! String)
                            self.userArray.append(object.object(forKey: "userpt") as! PFUser)
                            self.commentArray.append(object.object(forKey: "comment") as! String)
                            self.dateArray.append(object.createdAt)
                        }
                        // Display data
                        self.tableView.reloadData()
                    } else {
                        print(error!.localizedDescription)
                    }
                }
            }
        }
    }
    
    // MARK: TableView
    // Cell number
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentArray.count
    }
    // Cell height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    // Cell config
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Declare cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! commentCell
        
        cell.usernameBtn.setTitle(userArray[indexPath.row].username, for: .normal)
        cell.usernameBtn.sizeToFit()
        cell.commentLbl.text = commentArray[indexPath.row]
        if let ava = userArray[indexPath.row].object(forKey: "ava") as? PFFile {
            ava.getDataInBackground {
                (data, error) in
                cell.avaImg.image = UIImage(data: data!)
            }
        }
        
        // Calculate post date
        let from = dateArray[indexPath.row]
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

        // @mention is tapped
        cell.commentLbl.userHandleLinkTapHandler = { label, handle, rang in
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
        cell.commentLbl.hashtagLinkTapHandler = { rabel, handle, range in
            
            var mention = handle
            mention = String(mention.dropFirst())
            let hashvc = self.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! hashtagsVC
            hashvc.hashtag.append(mention)
            self.navigationController?.pushViewController(hashvc, animated: true)
        }

        // Assign index
        cell.usernameBtn.layer.setValue(userArray[indexPath.row], forKey: "user")

        return cell
    }
    // Enable cell editting
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: Swipe cell for actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // Call cell for calling further cell data
        let cell = tableView.cellForRow(at: indexPath) as! commentCell
        
        // TODO: Action 1: Delete
        let delete = UITableViewRowAction(style: .normal, title: "    ") {
            (action: UITableViewRowAction, indexPath: IndexPath) in
            // Step 1: Delete comment from server
            let commentQuery = PFQuery(className: "comments")
            commentQuery.whereKey("commentuuid", equalTo: self.commentuuidArray[indexPath.row])
            commentQuery.findObjectsInBackground {
                (objects, error) in
                if error == nil {
                    // Find related objects
                    for object in objects! {
                        object.deleteEventually()
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
            
            // Step 2: Delete #hashtag from server
            let hashtagQuery = PFQuery(className: "hashtags")
            hashtagQuery.whereKey("commentuuid", equalTo: self.commentuuidArray[indexPath.row])
            hashtagQuery.findObjectsInBackground{
                (objects, error) in
                if error == nil {
                    // Fined related objects
                    for object in objects! {
                        object.deleteEventually()
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
            
            
            // STEP 3. delete notification: mention comment
            let newsQuery = PFQuery(className: "news")
            newsQuery.whereKey("commentuuid", equalTo: self.commentuuidArray[indexPath.row])
            newsQuery.findObjectsInBackground{ (objects, error) in
                if error == nil {
                    for object in objects! {
                        object.deleteEventually()
                    }
                }
            }

            
            // Close cell
            tableView.setEditing(false, animated: true)
            
            // Step 3: Delete comment row from tableView and Array
            self.commentArray.remove(at: indexPath.row)
            self.dateArray.remove(at: indexPath.row)
            self.commentuuidArray.remove(at: indexPath.row)
            self.userArray.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        // TODO: Action 2: Mention or address message to someone
        let address = UITableViewRowAction(style: .normal, title: "    ") { (action: UITableViewRowAction, indexPath: IndexPath) in
            
            // Include username in textView
            self.commentTxt.text = "\(self.commentTxt.text + "@" + self.userArray[indexPath.row].username! + " ")"
            
            // Enable button
            self.sendBtn.isEnabled = true
            
            // Close cell
            tableView.setEditing(false, animated: true)
            
        }
        
        // TODO: Action 3: Complain
        let complain = UITableViewRowAction(style: .normal, title: "    ") { (action: UITableViewRowAction, indexPath: IndexPath) in
            
            // Send complatin to server regarding selected comment
            let complainObj = PFObject(className: "complain")
            complainObj["by"] = PFUser.current()!
            complainObj["postuuid"] = self.postObj[indexPath.row].value(forKey: "uuid") as! String
            complainObj["post"] = self.postObj[indexPath.row].value(forKey: "post") as! PFObject
            complainObj["owner"] = self.postObj[indexPath.row].value(forKey: "user") as! PFUser
            complainObj.saveInBackground {
                (success, error) in
                if success {
                    self.alert(title: "Complain has been made successfully", message: "Thank you! We will consider your complain")
                } else {
                    self.alert(title: "ERROR", message: error!.localizedDescription)
                }
            }
            // Close cell
            tableView.setEditing(false, animated: true)
        }
        
        // Buttons background
        delete.backgroundColor = UIColor(patternImage: UIImage(named: "delbutton.png")!)
        address.backgroundColor = UIColor(patternImage: UIImage(named: "address.png")!)
        complain.backgroundColor = UIColor(patternImage: UIImage(named: "complain.png")!)
        
        // Comment belongs to user
        if (cell.usernameBtn.layer.value(forKey: "user") as! PFUser).objectId == PFUser.current()?.objectId {
            return [delete, address]
        }
        // Post belongs to user
        else if postObj.last?.value(forKey: "objectId") as? String == PFUser.current()?.objectId {
            return [delete, address, complain]
        }
        // Post belong to another user
        else {
            return [address, complain]
        }
    }
 
    // Alert action
    func alert (title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Keyboard action
    // Show keyboard
    @objc func keyboardWillShow(notification: NSNotification){
        
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
        // difine keyboard size
        keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue)!
        // move up UI
        UIView.animate(withDuration: 0.1) {
            self.tableView.frame.size.height = self.tableViewHeight - self.keyboard.height
            self.commentTxt.frame.origin.y = self.commentY - self.keyboard.height
            self.sendBtn.frame.origin.y = self.commentY - self.keyboard.height
        }
    }
    
    // Hide keyboard func
    @objc func keyboardWillHide(notification: NSNotification) {
        // move down UI
        UIView.animate(withDuration: 0.4) {
            self.tableView.frame.size.height = self.tableViewHeight + self.keyboardHeight - self.tabBarHeight
            self.commentTxt.frame.origin.y = self.commentY + self.keyboardHeight - self.tabBarHeight
            self.sendBtn.frame.origin.y = self.commentTxt.frame.origin.y
        }
        // Show tab bar
        self.tabBarController?.tabBar.isHidden = false
        // Reset keyboard height
        self.keyboardHeight = 0
    }
    
    // Hide keyboard if tapped
    @objc func hideKeyboardTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // While writing something
    func textViewDidChange(_ textView: UITextView) {
        
        // Disable button if entered no text
        let spacing = CharacterSet.whitespacesAndNewlines
        
        if commentTxt.text.trimmingCharacters(in: spacing).isEmpty {
            sendBtn.isEnabled = false
        } else {
            sendBtn.isEnabled = true
        }
        
        // + paragraph
        if textView.contentSize.height > textView.frame.size.height && textView.contentSize.height < 130 {
            
            // Find difference to add
            let difference = textView.contentSize.height - textView.frame.size.height
            // Redefine frame of commenTxt
            textView.frame.origin.y = textView.frame.origin.y - difference
            textView.frame.size.height = textView.contentSize.height
            
            // Move up tableView
            if textView.contentSize.height + keyboard.height + commentY >= tableView.frame.size.height {
                tableView.frame.size.height = tableView.frame.size.height - difference
            }
            // Make text center horizontally
            commentTxt.centerText()
        }
            // - paragraph
        else if textView.contentSize.height < textView.frame.size.height {
            
            // Find difference to duduct
            let difference = textView.frame.size.height - textView.contentSize.height
            // Redefine frame of commentTxt
            textView.frame.origin.y = textView.frame.origin.y + difference
            textView.frame.size.height = textView.contentSize.height
            
            // Move down tableView
            if textView.contentSize.height + keyboard.height + commentY > tableView.frame.size.height {
                tableView.frame.size.height = tableView.frame.size.height + difference
            }
            // Make text center horizontally
            commentTxt.centerText()
        }
    }
    
    // MARK: Button action
    // Clicked username button -> jump to homeVC or guestVC
    @IBAction func usernameBtn_click(_ sender: Any) {
        
        // Get user data from button layer
        let commentUser = (sender as! UIButton).layer.value(forKey: "user") as! PFUser
        
        // If user tapped on themself go homeVC, else go guestVC
        if commentUser.objectId == PFUser.current()!.objectId {
            // Show tab bar at next page
            let home = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! homeVC
            self.navigationController?.pushViewController(home, animated: true)
        } else {
            // Get PFUser data as guestpt
            guestptArray.append(commentUser)
            // Show tab bar at next page
            let guest = self.storyboard?.instantiateViewController(withIdentifier: "guestVC") as! guestVC
            self.navigationController?.pushViewController(guest, animated: true)
        }
    }
    
    // Clicked send button
    @IBAction func sendBtn_click(_ sender: Any) {
        
        // STEP 1. Add row in tableView
        userArray.append(PFUser.current()!)
        dateArray.append(Date())
        commentArray.append(commentTxt.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        tableView.reloadData()
        
        let commentUuid = "\(PFUser.current()!.objectId!)\(NSUUID().uuidString)"
        commentuuidArray.append(commentUuid)
        
        // STEP 2. Send comment to server
        let commentObj = PFObject(className: "comments")
        commentObj["postuuid"] = postObj.last?.value(forKey: "uuid") as! String
        commentObj["userpt"] = userArray.last
        commentObj["comment"] = commentArray.last
        commentObj["commentuuid"] = commentUuid
        commentObj.saveEventually()
        
        // STEP 3. Send #hashtag to server
        let words:[String] = commentTxt.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Define tagged word
        for var word in words {
            // Save #hashtag in server
            if word.hasPrefix("#") {
                // Cut symbol
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                let hashtagObj = PFObject(className: "hashtags")
                hashtagObj["postuuid"] = postObj.last?.value(forKey: "uuid") as! String
                hashtagObj["by"] = PFUser.current()
                hashtagObj["commentuuid"] = commentUuid
                hashtagObj["hashtag"] = word.lowercased()
                hashtagObj["postspt"] = postObj.last
                hashtagObj.saveInBackground{
                    (success, error) in
                    if success {
                        print("hashtag \(word) is created")
                    } else {
                        print(error!.localizedDescription)
                    }
                }
            }
        }
        
        // STEP 4. Send notification as @mention
        var mentionCreated = Bool()
        
        for var word in words {
            
            // check @mentions for user
            if word.hasPrefix("@") {
                
                // cut symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // check if mentioned user exists
                let userquery = PFUser.query()
                userquery?.whereKey("username", equalTo: word)
                
                do {  let objects: [PFObject] = try userquery!.findObjects()
                    if objects.count != 0 {

                        let newsObj = PFObject(className: "news")
                        newsObj["by"] = PFUser.current()
                        newsObj["to_userid"] = objects.last?.objectId!
                        newsObj["postuuid"] = self.postObj.last?.value(forKey: "uuid")
                        newsObj["commentuuid"] = commentUuid
                        newsObj["type"] = "mention"
                        newsObj["checked"] = "no"
                        newsObj.saveEventually()
                        mentionCreated = true

                    }
                } catch {
                    print("error: reading user class")
                }
                
            }
        }
        
        // STEP 5. Send notification as comment
        if (postObj.last?.value(forKey: "user") as! PFUser).objectId != PFUser.current()?.objectId && mentionCreated == false {
            let newsObj = PFObject(className: "news")
            newsObj["by"] = PFUser.current()
            newsObj["to_userid"] = (postObj.last?.value(forKey: "user") as! PFUser).objectId!
            newsObj["postuuid"] = self.postObj.last?.value(forKey: "uuid")
            newsObj["commentuuid"] = commentUuid
            newsObj["type"] = "comment"
            newsObj["checked"] = "no"
            newsObj.saveEventually()
        }

        // STEP 6. Reset UI
        sendBtn.isEnabled = false
        commentTxt.text = ""
        commentTxt.frame.size.height = commentHeight
        commentTxt.frame.origin.y = sendBtn.frame.origin.y
        tableView.frame.size.height = self.tableViewHeight - self.keyboard.height - self.commentTxt.frame.size.height + self.commentHeight
        
        // STEP 7. scroll to bottom
        self.tableView.scrollToRow(at: IndexPath(item: commentArray.count - 1, section: 0), at: .bottom, animated: false)
    }
    
    // MARK: Go back function
    @objc func back(sender: UIBarButtonItem) {
        // Push back
        self.navigationController?.popViewController(animated: true)
    }

}
