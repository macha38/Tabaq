//
//  pictureCell.swift
//  Banzuke
//
//  Created by Masayuki Sakai on 2/28/18.
//  Copyright © 2018 Masayuki Sakai. All rights reserved.
//

import UIKit

class pictureCell: UICollectionViewCell {
    
    @IBOutlet weak var picImg: UIImageView!

    // default func
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // alignment
        let width = UIScreen.main.bounds.width
        let cellwidth = (width - 3) / 4
        picImg.frame = CGRect(x: 0, y: 0, width: cellwidth, height: cellwidth)
        
    }

}
