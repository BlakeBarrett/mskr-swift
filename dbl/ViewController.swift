//
//  ViewController.swift
//  dbl
//
//  Created by Blake Barrett on 3/17/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /*
    TODO:
        1) Load image √
        2) Desaturate image √
        3) Apply desaturated image as alpha-mask
        4) merge with any previous images in stack
    */
    
    @IBOutlet weak var previewImage: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.sourceType = .PhotoLibrary
        // .PhotoLibrary, .Camera, .SavedPhotosAlbum
        if let cameraType = UIImagePickerController.availableMediaTypesForSourceType(.Camera) {
            imagePicker.mediaTypes = cameraType
        } else {
            imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
        }
    }
    
    // MARK: Button click handlers
    @IBAction func onAddButtonClick(sender: UIBarButtonItem) {
        presentViewController(imagePicker, animated: true) { () -> Void in
            // no-op
        }
    }
    @IBAction func onTrashButtonClicked(sender: UIBarButtonItem) {
        self.previewImage.image = nil
    }
    
    @IBAction func onActionButtonClicked(sender: UIBarButtonItem) {
        UIGraphicsBeginImageContext(previewImage.bounds.size)
        previewImage.image?.drawInRect(CGRect(x: 0, y: 0, width: previewImage.frame.size.width, height: previewImage.frame.size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        presentViewController(activity, animated: true, completion: nil)
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // ignore movies
        if ("public.movie" == info[UIImagePickerControllerMediaType] as! NSString) {
            return
        }
        
        let image = ImageMaskingUtils.reconcileImageOrientation((info[UIImagePickerControllerOriginalImage] as? UIImage)!)
        
        self.previewImage.contentMode = .ScaleAspectFit
        
        // background thread
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            // process image
            var targetImage: UIImage
            if (self.previewImage.image == nil) {
                targetImage = image
            } else {
                // we have to do this assign/nil dance to free up as much memory as possible
                var inverted: UIImage? = self.invertColorsForImage(ImageMaskingUtils.colorControlImage(image))
                
                var desaturated: UIImage? = ImageMaskingUtils.noirImage(inverted)
                inverted = nil
                
                var mask: UIImage? = ImageMaskingUtils.imageToMask(desaturated!)
                desaturated = nil
                
                var merged:UIImage? = self.maskImage(image, maskImage: mask!)
                mask = nil
                
                targetImage = self.mergeImages(self.previewImage.image!, secondImage: merged!)
                merged = nil
            }
            
            // back to the main thread
            dispatch_async(dispatch_get_main_queue(), {
                self.previewImage.image = targetImage
            })
        }
        
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    // MARK: Image manipulations
    func invertColorsForImage(image: UIImage) -> UIImage {
        return ImageMaskingUtils.invertImageColors(image)
    }
    
    func desaturateImage(image: UIImage) -> UIImage {
        return ImageMaskingUtils.saturateImage(image, saturation: 0.0)
    }
    
    func maskImage(image: UIImage, maskImage: UIImage) -> UIImage {
        return ImageMaskingUtils.maskImage(image, maskImage: maskImage)
    }
    
    func mergeImages(firstImage: UIImage, secondImage: UIImage) -> UIImage {
        return ImageMaskingUtils.mergeImages(firstImage, second: secondImage)
    }

}

