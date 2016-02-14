//
//  MskrViewController.swift
//  mskr
//
//  Created by Blake Barrett on 2/13/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class MskrViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MaskReceiver {

    var image:UIImage?
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .SavedPhotosAlbum
        // .PhotoLibrary, .Camera, .SavedPhotosAlbum
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
    }
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBAction func onPreviewImageClick(sender: UITapGestureRecognizer) {
        if image != nil {
            return
        }
        presentViewController(imagePicker, animated: true) { () -> Void in
            // no-op
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // ignore movies
        if ("public.movie" == info[UIImagePickerControllerMediaType] as! NSString) {
            return
        }
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
//            self.image = editedImage
            self.image = ImageMaskingUtils.makeItSquare(editedImage)
        }
        
        self.previewImage.image = self.image
        picker.dismissViewControllerAnimated(true) { () -> Void in

        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    // MARK: Button Bar Item click handlers
    @IBAction func onTrashClick(sender: UIBarButtonItem) {
        self.startOver()
    }
    
    @IBAction func onActionClick(sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

//        let aboutAction = UIAlertAction(title: "About", style: .Default) { (action) in
//            
//        }

        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action) in
            self.save()
        }
        
        let destroyAction = UIAlertAction(title: "Reset", style: .Destructive) { (action) in
            self.startOver()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // no-op
        }
        
//        alertController.addAction(aboutAction)
        alertController.addAction(saveAction)
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)

        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    // MARK: MSKR functions
    func startOver() {
        self.image = nil
        self.previewImage.image = UIImage(named: "mskr_add")
    }
    
    func save() {
        UIImageWriteToSavedPhotosAlbum(self.image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
    }
    // save error handler
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        guard let error = error else { return }
        
        let title = "Save error"
        let message = (error.localizedDescription)
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    let ALPHA_BLEND_VAL: CGFloat! = 0.5
    func applyMaskToImage(image: UIImage, mask: UIImage) -> UIImage {
        
        guard let maskedImage = self.image else {
            return image
        }
        
        let masked: UIImage! = (ImageMaskingUtils.maskImage(image, maskImage: mask).copy() as! UIImage)
        // TODO: Make this either be alpha or gaussian blur based on user preference
        // See: http://stackoverflow.com/questions/19432773/creating-a-blur-effect-in-ios7
        let background = ImageMaskingUtils.image(maskedImage, withAlpha: ALPHA_BLEND_VAL)
        let merged = ImageMaskingUtils.mergeImages(masked, second: background)
        return merged
    }
    
    func getMaskNamed(maskName:String) -> UIImage {
        if let mask = UIImage(named: maskName) {
            return mask
        } else {
            return UIImage()
        }
    }
    
    // MARK: MaskReceiver Protocol Implementation
    func setSelectedMask(mask: String) {
        guard let _ = self.image else { return }
        
        let mask = getMaskNamed(mask)
        self.image = applyMaskToImage(self.image!, mask: mask)
        self.previewImage.image = self.image
    }
    
    // MARK: Prepare For Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let maskSelector = segue.destinationViewController as? MaskSelectorViewController {
            maskSelector.delegate = self
            maskSelector.image = self.image
        }
    }
}

protocol MaskReceiver {
    func setSelectedMask(mask:String)
}

