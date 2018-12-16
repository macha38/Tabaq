//
//  tabbarVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 5/6/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import ChameleonFramework
import Parse

// global variables of icons
var icons = UIScrollView()
var corner = UIImageView()
var dot = UIView()


class tabbarVC: UITabBarController {
    
    // Set up motal button in the middle of tabbar
    let menuButton = UIButton(frame: CGRect.zero)

    // Default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting tab bar color
        self.tabBar.tintColor = UIColor.flatYellow()
        self.tabBar.barTintColor = UIColor.flatWhite()
        // Disable translucent
        self.tabBar.isTranslucent = false
        
        // Set up motal button in the middle of tabbar
         setupMiddleButton()
        
        // create total icons
        icons.frame = CGRect(x: self.view.frame.size.width / 5 * 3 + 10, y: self.view.frame.size.height - self.tabBar.frame.size.height * 2 - 3, width: 50, height: 35)
        self.view.addSubview(icons)
        
        // create corner
        corner.frame = CGRect(x: icons.frame.origin.x, y: icons.frame.origin.y + icons.frame.size.height, width: 20, height: 10)
        corner.center.x = icons.center.x
        corner.image = UIImage(named: "corner.png")
        corner.isHidden = true
        self.view.addSubview(corner)
        
        // create dot
        dot.frame = CGRect(x: self.view.frame.size.width / 5 * 3, y: self.view.frame.size.height - 5, width: 7, height: 7)
        dot.center.x = self.view.frame.size.width / 5 * 3 + (self.view.frame.size.width / 5) / 2
        dot.backgroundColor = UIColor(red: 255/255, green: 166/255, blue: 19/255, alpha: 1)
        dot.layer.cornerRadius = dot.frame.size.width / 2
        dot.isHidden = true
        self.view.addSubview(dot)

        
        // call function of all type of notifications
        query(["like"], image: UIImage(named: "likeicon.png")!)
        query(["follow"], image: UIImage(named: "followicon.png")!)
        query(["mention", "comment"], image: UIImage(named: "commenticon.png")!)


        // hide icons objects
        UIView.animate(withDuration: 1, delay: 8, options: [], animations: { () -> Void in
            icons.alpha = 0
            corner.alpha = 0
            dot.alpha = 0
        }, completion: nil)

    }

    
    // Set up motal button in the middle of tabbar
    func setupMiddleButton() {
        
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: tabBar.frame.width / (numberOfItems + 1), height: tabBar.frame.height)
        
        menuButton.frame = CGRect(x: 0, y: 0, width: tabBarItemSize.width, height: tabBar.frame.size.height)
        var menuButtonFrame = menuButton.frame
        menuButtonFrame.origin.y = self.view.bounds.height - menuButtonFrame.height - self.view.safeAreaInsets.bottom
        menuButtonFrame.origin.x = self.view.bounds.width/2 - menuButtonFrame.size.width/2
        menuButton.frame = menuButtonFrame
        menuButton.backgroundColor = UIColor.flatWhite()
        menuButton.setImage(UIImage(named: "upload.png"), for: .normal)
        menuButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        self.view.insertSubview(menuButton, at: 2)
        
        // Move tab button aside to make space for middle button
        tabBar.items![0].titlePositionAdjustment = UIOffset(horizontal: (-1) * tabBar.frame.width * 0.025, vertical: 0)
        tabBar.items![1].titlePositionAdjustment = UIOffset(horizontal: (-1) * tabBar.frame.width * 0.075, vertical: 0)
        tabBar.items![2].titlePositionAdjustment = UIOffset(horizontal: tabBar.frame.width * 0.075, vertical: 0)
        tabBar.items![3].titlePositionAdjustment = UIOffset(horizontal: tabBar.frame.width * 0.025, vertical: 0)

        self.view.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        menuButton.frame.origin.y = self.view.bounds.height - menuButton.frame.height - self.view.safeAreaInsets.bottom
    }
    
    // Tap action
    @objc func tapped(){
        let upload = self.storyboard?.instantiateViewController(withIdentifier: "phototabbarVC") as! phototabbarVC
        present(upload, animated: true, completion: nil)
    }
    
    // multiple query
    func query (_ type:[String], image:UIImage) {
        
        let query = PFQuery(className: "news")
        query.whereKey("to_userid", equalTo: PFUser.current()!.objectId!)
        query.whereKey("checked", equalTo: "no")
        query.whereKey("type", containedIn: type)
        query.countObjectsInBackground { (count, error) in
            if error == nil {
                if count > 0 {
                    self.placeIcon(image, text: "\(count)")
                }
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    
    // multiple icons
    func placeIcon (_ image:UIImage, text:String) {
        
        // create separate icon
        let view = UIImageView(frame: CGRect(x: icons.contentSize.width, y: 0, width: 50, height: 35))
        view.image = image
        icons.addSubview(view)
        
        // create label
        let label = UILabel(frame: CGRect(x: view.frame.size.width / 2, y: 0, width: view.frame.size.width / 2, height: view.frame.size.height))
        label.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        label.text = text
        label.textAlignment = .center
        label.textColor = .white
        view.addSubview(label)
        
        // update icons view frame
        icons.frame.size.width = icons.frame.size.width + view.frame.size.width - 4
        icons.contentSize.width = icons.contentSize.width + view.frame.size.width - 4
        icons.center.x = self.view.frame.size.width / 5 * 4 - (self.view.frame.size.width / 5) / 4
        
        // unhide elements
        corner.isHidden = false
        dot.isHidden = false
    }


}
