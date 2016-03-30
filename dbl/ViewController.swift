//
//  ViewController.swift
//  dbl
//
//  Created by Blake Barrett on 3/17/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /*
    TODO:
        1) Load image √
        2) Desaturate image √
        3) Apply desaturated image as alpha-mask √
        4) Merge with any previous images in stack √
        5) Save √
    */
    
    @IBOutlet weak var previewImage: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
    }
    
    // MARK: Button click handlers
    @IBAction func onAddButtonClick(sender: UIBarButtonItem) {
        presentViewController(imagePicker, animated: true) { () -> Void in
            // no-op
        }
    }
    
    @IBAction func onTrashButtonClicked(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let destroyAction = UIAlertAction(title: "Reset", style: .Destructive) { (action) in
            self.startOver()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // no-op
        }
        
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    @IBAction func onActionButtonClicked(sender: UIBarButtonItem) {

        guard let _ = self.previewImage.image else {
            return
        }
        
        let image = rasterizeImage(self.previewImage.image!)
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if (UIDevice.currentDevice().userInterfaceIdiom == .Pad) {
            let nav = UINavigationController(rootViewController: activity)
            nav.modalPresentationStyle = .Popover
            
            let popover = nav.popoverPresentationController as UIPopoverPresentationController!
            popover.barButtonItem = sender
            
            self.presentViewController(nav, animated: true, completion: nil)
        } else {
            presentViewController(activity, animated: true, completion: nil)
        }
    }
    
    @IBAction func onRotateButtonClicked(sender: UIBarButtonItem) {
        guard let image = self.previewImage.image else {
            return
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let rotationInRatians: CGFloat = CGFloat(M_PI) * (90) / 180.0
            self.setPreviewImageAsync(ImageMaskingUtils.rotate(image, radians: rotationInRatians))
        }
    }
    
    func rasterizeImage(image:UIImage) -> UIImage {
        UIGraphicsBeginImageContext(image.size)
        image.drawInRect(
            CGRect(
                x: 0, y: 0,
                width: image.size.width,
                height: image.size.height
            )
        )
        
        let rasterized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rasterized
    }
    
    func startOver() {
        self.setPreviewImageAsync(nil)
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // ignore movies
        if ((info[UIImagePickerControllerMediaType] as! String) == kUTTypeMovie as String) {
            return
        }
        
        var image: UIImage? = ImageMaskingUtils.reconcileImageOrientation((info[UIImagePickerControllerOriginalImage] as? UIImage)!)
        
        self.previewImage.contentMode = .ScaleAspectFit
        
        // background thread
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            // process image
            var targetImage: UIImage
            if (self.previewImage.image == nil) {
                targetImage = image!
            } else {
                let originalImageSize = self.previewImage.image?.size
                image = ImageMaskingUtils.resize(image!, size: originalImageSize!)
                
                // we have to do this assign/nil dance to free up as much memory as possible
                var inverted: UIImage? = ImageMaskingUtils.invertImageColors(ImageMaskingUtils.colorControlImage(image!, brightness: 1.0, saturation: 1.0, contrast: 2.0))
                
                var desaturated: UIImage? = ImageMaskingUtils.noirImage(inverted)
                inverted = nil
                
                var mask: UIImage? = ImageMaskingUtils.imageToMask(desaturated!)
                desaturated = nil
                
                var merged:UIImage? = ImageMaskingUtils.maskImage(image!, maskImage: mask!)
                mask = nil
                image = nil
                
                targetImage = ImageMaskingUtils.mergeImages(self.previewImage.image!, second: merged!)
                merged = nil
            }
            
            self.setPreviewImageAsync(targetImage)
        }
        
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    // MARK: Helper functions
    func setPreviewImageAsync(image:UIImage?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.previewImage.image = image
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

