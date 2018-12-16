//
//  photonavVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/8/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit

class photonavVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Color of title at the top
        self.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.flatWhite()]
        // Color of buttons in nav controller
        self.navigationBar.tintColor = UIColor.flatWhite()
        // Color of background of nav controller
        self.navigationBar.barTintColor = UIColor.flatYellow()
//        // Unable translucent
//        self.navigationBar.isTranslucent = false

    }

    // White status bar function
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

}
