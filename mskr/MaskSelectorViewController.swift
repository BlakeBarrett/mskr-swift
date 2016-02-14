//
//  MaskSelectorViewController.swift
//  mskr
//
//  Created by Blake Barrett on 2/13/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class MaskSelectorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let masks = ["sqrmsk", "crclmsk", "trnglmsk", "powmsk", "plrdmsk", "xmsk", "eqltymsk", "hrtmsk", "dmndmsk"]
    
    var image: UIImage?
    var selectedMask: String?
    var delegate: MaskReceiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func imageNameForIndexPath(index:NSIndexPath) -> String {
        return masks[index.indexAtPosition(1)]
    }
    
    func imageForIndexPath(index: NSIndexPath) -> UIImage {
        let name = imageNameForIndexPath(index)
        guard let image = UIImage(named: name) else {
            return UIImage()
        }
        return image
    }
    
    
    // MARK: Collection View FLOW LAYOUT
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            return CGSize(width: 100, height: 100)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        return edgeInsets
    }
    
    // MARK: Collection View DATA_SOURCE
    @IBOutlet weak var collectionView: UICollectionView!
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return masks.count
    }
    
    let reuseIdentifier = "maskCellIdentifier"
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! MaskCollectionViewCell

        let mask = imageForIndexPath(indexPath)
        cell.backgroundColor = UIColor.grayColor()
        cell.imageView.image = mask

//        dispatch_async(dispatch_get_main_queue(), {
//            let masked: UIImage! = ImageMaskingUtils.maskImage(self.image, maskImage: mask)
//            let background = ImageMaskingUtils.image(self.image!, withAlpha: 0.5)
//            let merged = ImageMaskingUtils.mergeImages(masked, second: background)
//            
//            cell.imageView.image = merged
//        })

        return cell
    }
    
    // MARK: Collection View DELEGATE
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedMask = self.imageNameForIndexPath(indexPath)
        delegate?.setSelectedMask(self.selectedMask!)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Button Click Handlers
    @IBAction func onButtonItemClick(sender: UIBarButtonItem) {
        
        switch (sender.tag) {
        case 1: // done
            delegate?.setSelectedMask(self.selectedMask!)
            break
        case 2: // cancel
            self.selectedMask = nil
            break
        default: break
        }
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            // no-op
        }
    }
    
    // MARK: Prepare For Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let mask = self.selectedMask {
            delegate?.setSelectedMask(mask)
        }
    }
}


class MaskCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}