//
//  AppDelegate.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 2/14/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configuration of using Parse code in Heroku
        let parseConfig = ParseClientConfiguration {
            (ParseMutableClienConfiguration) in
            
            // Accessing Back4App server via id & key
            ParseMutableClienConfiguration.applicationId = logInInfo["appid"]
            ParseMutableClienConfiguration.clientKey = logInInfo["clientkey"]
            ParseMutableClienConfiguration.server = logInInfo["server"]!
        }
        
        Parse.initialize(with: parseConfig)
        
        // call login function
        login()
        
        // Color of window
        window?.backgroundColor = .white
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func login() {
        
        // remember user's login
        let username : String? = UserDefaults.standard.string(forKey: "username")
        
        // if loged in
        if username != nil {
            
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let myTabBar = storyboard.instantiateViewController(withIdentifier: "tabBar") as! UITabBarController
            window?.rootViewController = myTabBar
        }
        
    }


}

