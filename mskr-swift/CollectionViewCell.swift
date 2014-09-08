//
//  CollectionViewCell.swift
//  mskr
//
//  Created by Blake Barrett on 9/7/14.
//  Copyright (c) 2014 Blake Barrett. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}