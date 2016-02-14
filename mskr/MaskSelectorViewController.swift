//
//  MaskSelectorViewController.swift
//  mskr
//
//  Created by Blake Barrett on 2/13/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class MaskSelectorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let masks = ["sqrmsk", "crclmsk", "trnglmsk", "powmsk", "plrdmsk", "xmsk", "eqltymsk", "hrtmsk", "dmndmsk"]
    
    var selectedMask: String?
    
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
        cell.backgroundColor = UIColor.whiteColor()
        cell.imageView.image = mask
 
        return cell
    }
    
    // MARK: Collection View DELEGATE
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedMask = self.imageNameForIndexPath(indexPath)
    }
    
    // MARK: Button Click Handlers
    @IBAction func onButtonItemClick(sender: UIBarButtonItem) {
        
        switch (sender.tag) {
        case 1: // done
            self.selectedMask = ""
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
            let destination = segue.destinationViewController as! MaskReceiver
            destination.setSelectedMask(mask)
        }
    }
    
}