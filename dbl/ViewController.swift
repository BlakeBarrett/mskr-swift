//
//  ViewController.swift
//  dbl
//
//  Created by Blake Barrett on 3/17/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MaskReceiver {
    
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
    var noImagesHaveBeenSelected = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previewImage.contentMode = .scaleAspectFit
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: Gesture recognizer
    @IBAction func onImageTap(_ sender: UITapGestureRecognizer) {
        if (self.noImagesHaveBeenSelected) {
            self.openImagePicker()
        }
    }
    
    // MARK: Button click handlers
    @IBAction func onAddButtonClick(_ sender: UIBarButtonItem) {
        self.openImagePicker()
    }
    
    @IBAction func onTrashButtonClicked(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let destroyAction = UIAlertAction(title: "Reset", style: .destructive) { (action) in
            self.startOver()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // no-op
        }
        
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    @IBAction func onActionButtonClicked(_ sender: UIBarButtonItem) {
        guard let _ = self.previewImage.image else {
            return
        }
        
        let image = rasterizeImage(self.previewImage.image!)
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            let nav = UINavigationController(rootViewController: activity)
            nav.modalPresentationStyle = .popover
            
            let popover = nav.popoverPresentationController as UIPopoverPresentationController!
            popover?.barButtonItem = sender
            
            self.present(nav, animated: true, completion: nil)
        } else {
            present(activity, animated: true, completion: nil)
        }
    }
    
    @IBAction func onRotateButtonClicked(_ sender: UIBarButtonItem) {
        guard let image = self.previewImage.image else {
            return
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let rotationInRatians: CGFloat = CGFloat(M_PI) * (90) / 180.0
            self.setPreviewImageAsync(ImageMaskingUtils.rotate(image, radians: rotationInRatians))
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) { () -> Void in
            // background thread
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                let mediaType = info[UIImagePickerControllerMediaType] as! CFString
                if (mediaType == kUTTypeImage) {
                    let image = ImageMaskingUtils.reconcileImageOrientation((info[UIImagePickerControllerOriginalImage] as! UIImage))
                    self.onImageSelected(image)
                } else if (mediaType == kUTTypeMovie) {
//                    if let referenceUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
//                        self.onVideoSelected(referenceUrl)
//                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { () -> Void in
            
        }
    }
    
    func onImageSelected(_ image: UIImage) {
        // process image
        if (self.noImagesHaveBeenSelected) {
            self.setPreviewImageAsync(image)
        } else {
            self.setPreviewImageAsync(self.overlayImageMethodTwo(self.previewImage.image, fresh: image))
        }
    }
    
//    var moviePath: NSURL? = nil
//    func onVideoSelected(path: NSURL) {
//        if moviePath != nil {
//            return
//        }
//        self.moviePath = path
//        let movieAsset = AVURLAsset(URL: url, options: nil)
//    }
    
    // MARK: Merge functions
    
    func produceAlphaMaskedImage(_ image: UIImage?) -> UIImage {
        return ImageMaskingUtils.imageToMask(ImageMaskingUtils.noirImage(image!))
    }
    
    func produceInvertedAlphaMaskedImage(_ image: UIImage?) -> UIImage {
        return produceAlphaMaskedImage(ImageMaskingUtils.invertImageColors(ImageMaskingUtils.colorControlImage(image!, brightness: 1.0, saturation: 1.0, contrast: 2.0)))
    }
    
    func overlayImage(_ original: UIImage?, fresh: UIImage?) -> UIImage {
        let originalImageSize = original?.size
        let image: UIImage? = ImageMaskingUtils.fit(fresh!, inSize: originalImageSize!)
        
        var mask: UIImage? = produceInvertedAlphaMaskedImage(image)
        
        let merged:UIImage? = ImageMaskingUtils.maskImage(image!, maskImage: mask!)
        mask = nil
        
        return ImageMaskingUtils.mergeImages(original!, second: merged!)
    }
    
    func overlayImageMethodTwo(_ original: UIImage?, fresh: UIImage?) -> UIImage {
        let originalImageSize = original?.size
        let image: UIImage? = ImageMaskingUtils.resize(fresh!, size: originalImageSize!)
        let mask: UIImage? = produceAlphaMaskedImage(image)
        let merged: UIImage? = ImageMaskingUtils.maskImage(image!, maskImage: mask!)
        
        return ImageMaskingUtils.mergeImages(original!, second: merged!)
    }
    
    // TODO: Implement finger-paint a mask:
    // https://www.raywenderlich.com/87899/make-simple-drawing-app-uikit-swift
    
    // MARK: Helper functions
    func openImagePicker() {
        present(imagePicker, animated: true) { () -> Void in
            // no-op
        }
    }
    
    func setPreviewImageAsync(_ image:UIImage?) {
        self.noImagesHaveBeenSelected = false
        DispatchQueue.main.async(execute: {
            self.previewImage.image = image
        })
    }
    
    func rasterizeImage(_ image:UIImage) -> UIImage {
        UIGraphicsBeginImageContext(image.size)
        image.draw(
            in: CGRect(
                x: 0, y: 0,
                width: image.size.width,
                height: image.size.height
            )
        )
        
        let rasterized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rasterized!
    }
    
    func startOver() {
        self.setPreviewImageAsync(nil)
        self.noImagesHaveBeenSelected = true
    }
    
    func setSelectedMask(_ mask: String) {
        var masked: UIImage? = ImageMaskingUtils.maskImage(self.previewImage.image!, maskImage: UIImage(named: mask))
        var background: UIImage? = ImageMaskingUtils.image(self.previewImage.image!, withAlpha: 0.5)
        let merged: UIImage? = ImageMaskingUtils.mergeImages(masked!, second: background!)
        masked = nil
        background = nil
        self.setPreviewImageAsync(merged!)
    }
    
    // MARK: Prepare For Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let maskSelector = segue.destination as? MaskSelectorViewController {
            maskSelector.delegate = self
            maskSelector.image = self.previewImage.image
        }
    }
}

protocol MaskReceiver {
    func openImagePicker()
    func setSelectedMask(_ mask:String)
}
