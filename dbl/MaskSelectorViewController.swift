//
//  MaskSelectorViewController.swift
//  mskr
//
//  Created by Blake Barrett on 2/13/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MaskSelectorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    static let masks = ["sqrmsk", "crclmsk", "trnglmsk", "powmsk", "plrdmsk", "xmsk", "eqltymsk", "hrtmsk", "dmndmsk"]
    
    static var size: CGSize = CGSize(width: 0, height: 0)
    
    var image: UIImage?
    var selectedMask: String?
    var delegate: MaskReceiver?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        MaskSelectorViewController.precacheMasks()
    }
    
    func imageNameForIndexPath(_ index:IndexPath) -> String {
        let maskIndex = index.row - 1
        return MaskSelectorViewController.masks[maskIndex]
    }
    
    func imageForIndexPath(_ index: IndexPath) -> UIImage {
        let name = imageNameForIndexPath(index)
        guard let image = UIImage(named: name) else {
            return UIImage()
        }
        return image
    }
    
    // MARK: Collection View FLOW LAYOUT
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 175, height: 175)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,insetForSectionAt section: Int) -> UIEdgeInsets {
        let edgeInsets = UIEdgeInsetsMake(1, 1, 1, 1)
        return edgeInsets
    }
    
    // MARK: Collection View DATA_SOURCE
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MaskSelectorViewController.masks.count + 1
    }
    
    static func precacheMasks() {
        if (MaskSelectorViewController.size.width == 0 &&
            MaskSelectorViewController.size.height == 0) {
            return
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            for i in 0 ..< MaskSelectorViewController.masks.count {
                if (MaskSelectorViewController.maskCache[i] != nil) { continue }
                let maskName = MaskSelectorViewController.masks[i]
                let mask = UIImage(named: maskName)
                let resizedMask = ImageMaskingUtils.fit(mask!, inSize: MaskSelectorViewController.size)
                MaskSelectorViewController.maskCache[i] = resizedMask
            }
        }
    }
    
    static func applyMaskToImage(_ image: UIImage, mask: UIImage) -> UIImage {
        let masked: UIImage? = ImageMaskingUtils.maskImage(image, maskImage: mask)
        let background: UIImage? = ImageMaskingUtils.image(image, withAlpha: 0.5)
        return ImageMaskingUtils.mergeImages(masked!, second: background!)
    }
    
    static var maskCache = [Int: UIImage]()
    
    let reuseIdentifier = "maskCellIdentifier"
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 && indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "importCellIdentifier", for: indexPath) as! PresentImagePickerCollectionViewCell
            cell.backgroundColor = UIColor.white
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MaskCollectionViewCell
        cell.imageView.contentMode = .scaleAspectFit
        
        MaskSelectorViewController.size = cell.frame.size
        
        guard let _ = self.image else { return cell }
        
        // just to show _something_ while everything else is going on backstage
        cell.imageView.image = self.image
        
        // Background thread!
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let ordinalIndex = indexPath.row - 1
            
            // Resize the image, but only once.
            var imageSize = self.image?.size
            if imageSize?.width > cell.frame.size.width ||
                imageSize?.height > cell.frame.size.height {
                self.image = ImageMaskingUtils.fit(self.image!, inSize: cell.frame.size)
                imageSize = self.image?.size
            }
            
            var mask: UIImage?
            // Is the mask image already cached?
            if MaskSelectorViewController.maskCache[ordinalIndex] == nil {
                // resize the mask to fit the cell's frame
                mask = ImageMaskingUtils.fit(self.imageForIndexPath(indexPath), inSize: imageSize!)
                // cache resized mask
                MaskSelectorViewController.maskCache[ordinalIndex] = mask
            } else {
                mask = MaskSelectorViewController.maskCache[ordinalIndex]
            }
            
            var merged: UIImage? = MaskSelectorViewController.applyMaskToImage(self.image!, mask: mask!)
            DispatchQueue.main.async(execute: {
                cell.imageView.image = merged
                merged = nil
            })
        }
        return cell
    }
    
    // MARK: Collection View DELEGATE
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedMask = self.imageNameForIndexPath(indexPath)
        delegate?.setSelectedMask(self.selectedMask!)
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Button Click Handlers
    @IBAction func onButtonItemClick(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true) { () -> Void in
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mask = self.selectedMask {
            delegate?.setSelectedMask(mask)
        }
    }
    
    @IBAction func onBrowseItemClick(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true) { 
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
