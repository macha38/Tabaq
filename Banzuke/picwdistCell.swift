//
//  picwdistCell.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 11/27/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit

class picwdistCell: UICollectionViewCell {

    @IBOutlet weak var picImg: UIImageView!
    @IBOutlet weak var distanceLbl: UILabel!
    
    // default func
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // alignment
        let width = UIScreen.main.bounds.width
        let cellwidth = (width - 3) / 4
        picImg.frame = CGRect(x: 0, y: 0, width: cellwidth, height: cellwidth)
        
        distanceLbl.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:[distance]-2-|",
            options: [], metrics: nil, views: ["distance":distanceLbl]))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-2-[distance]",
            options: [], metrics: nil, views: ["distance":distanceLbl]))
        
    }
    
}
