//
//  filterVC.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 10/28/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit
import Parse

class filterVC: UIViewController {

    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var clockImg: UIImageView!
    @IBOutlet weak var hoursBtn: UIButton!
    @IBOutlet weak var daysBtn: UIButton!
    @IBOutlet weak var weekBtn: UIButton!
    @IBOutlet weak var monthBtn: UIButton!
    @IBOutlet weak var allBtn: UIButton!
    
    // Delegate
    var searchDelegate: searchVCDelegate?
    
    // filter id
    var conditionId: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // alignment
        alignment()
        
        // Declare hide keyboard tap
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissViewTap))
        dismissTap.numberOfTapsRequired = 1
        dismissTap.cancelsTouchesInView = true
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(dismissTap)

    }
    
    // Alignment function
    func alignment() {
        
        conditionId = UserDefaults.standard.integer(forKey: "searchfilter")
        
        let width = view.frame.width
        let height = view.frame.height

        // translucent backgroundColor
        view.backgroundColor = UIColor(white: 1, alpha: 0.4)
        filterView.frame = CGRect(x: 0, y: 0, width: width / 4, height: height)
        filterView.backgroundColor = UIColor(white: 1, alpha: 1)
        
        let filtWidth = filterView.frame.width
        
        clockImg.frame = CGRect(x: 5, y: 50, width: 34, height: 34)
        
        hoursBtn.frame = CGRect(x: 5, y: clockImg.frame.origin.y + 65, width: filtWidth - 10, height: 25)
        hoursBtn.layer.cornerRadius = hoursBtn.frame.size.width / 20
        hoursBtn.layer.borderWidth = 0.4
        hoursBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
        hoursBtn.backgroundColor = UIColor.flatWhite()
        hoursBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor

        daysBtn.frame = CGRect(x: 5, y: hoursBtn.frame.origin.y + 50, width: filtWidth - 10, height: 25)
        daysBtn.layer.cornerRadius = daysBtn.frame.size.width / 20
        daysBtn.layer.borderWidth = 0.4
        daysBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
        daysBtn.backgroundColor = UIColor.flatWhite()
        daysBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor

        weekBtn.frame = CGRect(x: 5, y: daysBtn.frame.origin.y + 50, width: filtWidth - 10, height: 25)
        weekBtn.layer.cornerRadius = weekBtn.frame.size.width / 20
        weekBtn.layer.borderWidth = 0.4
        weekBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
        weekBtn.backgroundColor = UIColor.flatWhite()
        weekBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor

        monthBtn.frame = CGRect(x: 5, y: weekBtn.frame.origin.y + 50, width: filtWidth - 10, height: 25)
        monthBtn.layer.cornerRadius = monthBtn.frame.size.width / 20
        monthBtn.layer.borderWidth = 0.4
        monthBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
        monthBtn.backgroundColor = UIColor.flatWhite()
        monthBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor

        allBtn.frame = CGRect(x: 5, y: monthBtn.frame.origin.y + 50, width: filtWidth - 10, height: 25)
        allBtn.layer.cornerRadius = allBtn.frame.size.width / 20
        allBtn.layer.borderWidth = 0.4
        allBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
        allBtn.backgroundColor = UIColor.flatWhite()
        allBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor

        switch conditionId {
        case 1:
            hoursBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
            hoursBtn.backgroundColor = UIColor.flatYellow()
            hoursBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
        case 2:
            daysBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
            daysBtn.backgroundColor = UIColor.flatYellow()
            daysBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
        case 3:
            weekBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
            weekBtn.backgroundColor = UIColor.flatYellow()
            weekBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
        case 4:
            monthBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
            monthBtn.backgroundColor = UIColor.flatYellow()
            monthBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
        default:
            allBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
            allBtn.backgroundColor = UIColor.flatYellow()
            allBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor
        }

    }
    
    
    // change back button
    func resetButton(_ id: Int) {
        
        switch id {
        case 1:
            hoursBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
            hoursBtn.backgroundColor = UIColor.flatWhite()
            hoursBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
        case 2:
            daysBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
            daysBtn.backgroundColor = UIColor.flatWhite()
            daysBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
        case 3:
            weekBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
            weekBtn.backgroundColor = UIColor.flatWhite()
            weekBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
        case 4:
            monthBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
            monthBtn.backgroundColor = UIColor.flatWhite()
            monthBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
        default:
            allBtn.setTitleColor(UIColor.flatBlack(), for: UIControlState.normal)
            allBtn.backgroundColor = UIColor.flatWhite()
            allBtn.layer.borderColor = UIColor.flatWhiteColorDark().cgColor
        }
    }

    
    // click button
    @IBAction func hourBtn_click(_ sender: Any) {
        resetButton(conditionId)
        conditionId = 1
        hoursBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
        hoursBtn.backgroundColor = UIColor.flatYellow()
        hoursBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor

        searchDelegate?.getConditionFromFilterVC(conditionId: conditionId)
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func threedaysBtn_click(_ sender: Any) {
        resetButton(conditionId)
        conditionId = 2
        daysBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
        daysBtn.backgroundColor = UIColor.flatYellow()
        daysBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor

        searchDelegate?.getConditionFromFilterVC(conditionId: conditionId)
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func weekBtn_click(_ sender: Any) {
        resetButton(conditionId)
        conditionId = 3
        weekBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
        weekBtn.backgroundColor = UIColor.flatYellow()
        weekBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor

        searchDelegate?.getConditionFromFilterVC(conditionId: conditionId)
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func monthBtn_click(_ sender: Any) {
        resetButton(conditionId)
        conditionId = 4
        monthBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
        monthBtn.backgroundColor = UIColor.flatYellow()
        monthBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor

        searchDelegate?.getConditionFromFilterVC(conditionId: conditionId)
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func allBtn_click(_ sender: Any) {
        resetButton(conditionId)
        conditionId = 5
        allBtn.setTitleColor(UIColor.flatWhite(), for: UIControlState.normal)
        allBtn.backgroundColor = UIColor.flatYellow()
        allBtn.layer.borderColor = UIColor.flatYellowColorDark().cgColor

        searchDelegate?.getConditionFromFilterVC(conditionId: conditionId)
        self.dismiss(animated: false, completion: nil)
    }

    
    // tap to cancel filter
    @objc func dismissViewTap(recognizer: UITapGestureRecognizer) {
        
        self.dismiss(animated: false, completion: nil)
    }


}
