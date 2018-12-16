//
//  phototabbarVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/8/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse
import Photos

class phototabbarVC: UITabBarController/*, UIImagePickerControllerDelegate, UINavigationControllerDelegate*/{

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setting tab bar color
        self.tabBar.tintColor = UIColor.flatYellow()
        self.tabBar.barTintColor = UIColor.flatWhite()
        
        // chenge title size
        UITabBarItem.appearance(whenContainedInInstancesOf: [phototabbarVC.self]).setTitleTextAttributes([
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)
            ], for: .normal);
        UITabBarItem.appearance().titlePositionAdjustment = UIOffsetMake(0, -12)

//        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Medium", size: 16)!], for: .normal)
//        UITabBarItem.appearance().titlePositionAdjustment = UIOffsetMake(0, -15)

        // Disable translucent
//        self.tabBar.isTranslucent = true

    }

}
