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
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func imageNameForIndexPath(index:NSIndexPath) -> String {
        return masks[index.indexAtPosition(1) - 1]
    }
    
    func imageForIndexPath(index: NSIndexPath) -> UIImage {
        let name = imageNameForIndexPath(index)
        guard let image = UIImage(named: name) else {
            return UIImage()
        }
        return image
    }
    
    func resizeImageToFrame(image:UIImage, frame:CGRect) -> UIImage {
//        return ImageMaskingUtils.image(image, withSize: CGSizeMake(frame.width, frame.height), andAlpha: 1.0)
        return ImageMaskingUtils.imagePreservingAspectRatio(image, withSize: CGSizeMake(frame.width, frame.height), andAlpha: 1)
    }
    
    // MARK: Collection View FLOW LAYOUT
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 175, height: 175)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let edgeInsets = UIEdgeInsetsMake(1, 1, 1, 1)
        return edgeInsets
    }
    
    // MARK: Collection View DATA_SOURCE
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return masks.count + 1
    }
    
    static var maskCache = [Int: UIImage]()
    
    let reuseIdentifier = "maskCellIdentifier"
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 && indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("importCellIdentifier", forIndexPath: indexPath) as! PresentImagePickerCollectionViewCell
            cell.backgroundColor = UIColor.whiteColor()
            return cell
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! MaskCollectionViewCell
        cell.imageView.contentMode = .ScaleAspectFit
        
        guard let _ = self.image else { return cell }
        
        // just to show _something_ while everything else is going on backstage
        cell.imageView.image = self.image
        
        // Background thread!
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let ordinalIndex = indexPath.indexAtPosition(1) - 1
            
            // Resize the image, but only once.
            let imageSize = self.image?.size
            if imageSize?.width > cell.frame.size.width ||
                imageSize?.height > cell.frame.size.height {
                self.image = self.resizeImageToFrame(self.image!, frame: cell.frame)
            }
            
            var mask: UIImage?
            // Is the mask image already cached?
            if MaskSelectorViewController.maskCache[ordinalIndex] == nil {
                // resize the mask to fit the cell's frame
                mask = self.resizeImageToFrame(self.imageForIndexPath(indexPath), frame: cell.frame)
                // cache resized mask
                MaskSelectorViewController.maskCache[ordinalIndex] = mask
            } else {
                mask = MaskSelectorViewController.maskCache[ordinalIndex]
            }
            
            var masked: UIImage? = ImageMaskingUtils.maskImage(self.image, maskImage: mask)
            var background: UIImage? = ImageMaskingUtils.image(self.image!, withAlpha: 0.5)
            var merged: UIImage? = ImageMaskingUtils.mergeImages(masked!, second: background!)
            masked = nil
            background = nil
            
            dispatch_async(dispatch_get_main_queue(), {
                cell.imageView.image = merged
                merged = nil
            })
        }
        
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
        self.dismissViewControllerAnimated(true) { () -> Void in
            switch (sender.tag) {
            case 1: // done
                self.delegate?.setSelectedMask(self.selectedMask!)
                break
            case 2: // cancel
                self.selectedMask = nil
                break
            default: break
            }
        }
    }
    
    // MARK: Prepare For Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let mask = self.selectedMask {
            delegate?.setSelectedMask(mask)
        }
    }
    
    @IBAction func onBrowseItemClick(sender: UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true) { 
            self.delegate?.openImagePicker()
        }
    }
}

class PresentImagePickerCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}

class MaskCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}