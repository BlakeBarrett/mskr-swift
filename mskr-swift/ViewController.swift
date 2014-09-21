//
//  ViewController.swift
//  mskr-swift
//
//  Created by Blake Barrett on 6/4/14.
//  Copyright (c) 2014 Blake Barrett. All rights reserved.
//

import UIKit
import AssetsLibrary

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIActionSheetDelegate {
    
    var imagePicker: UIImagePickerController = UIImagePickerController();
    
    var selectedImageInfoDict: NSDictionary = NSDictionary();
    let availableMasks: Array<String>! = ["sqr", "crcl", "trngl", "POW", "plrd", "x", "eqlty", "hrt", "dmnd"];
    var maskCache: Array<(name: String, image: UIImage)> = [];
    
    
    @IBOutlet var imageView: UIImageView!;
    @IBOutlet var toolbar: UIToolbar!;
    @IBOutlet var maskCollectionView: UICollectionView!;
    
    var maskedImage: UIImage = UIImage();
    var selectedMaskName: String = "crclmsk"
    
    // TODO: Hook this up to a slider control somewhere.
    let ALPHA_BLEND_VAL: CGFloat! = 0.5;
    
    var context: CIContext;
    
    required init(coder aDecoder: NSCoder)  {
        self.context = CIContext(options: nil);
        self.activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        
        super.init(coder: aDecoder);
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.context = CIContext(options: nil)
        self.activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }
    
    override func viewDidLoad() {
        
        self.context = CIContext(options: nil)
        
        initImagePickerController()
        
        initAcitvityIndicatiorView()
        
        disableToolbar()
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func precacheMasks() {
        for mskName in availableMasks {
            let mask = UIImage(named: mskName);
            self.maskCache.append(name: mskName, image: mask);
        }
    }
    
    func resizeCachedMasks(size: CGSize) {
        for var index = 0; index < self.maskCache.count; index++ {
            let maskKV = self.maskCache[index]
            self.maskCache[index].image = ImageMaskingUtils.resizeImage(source: maskKV.image, size: size)
        }
    }
    
    // MARK: Getters
    func getMask() -> UIImage {
        return UIImage(named: self.selectedMaskName)
    }
    
    func getMaskNameForRow(#row: Int) -> String {
        return availableMasks[row].lowercaseString + "msk";
    }
    
    func getMaskForName(#name: String) -> UIImage {
        for maskKVpair in self.maskCache {
            if maskKVpair.name == name {
                return maskKVpair.image;
            }
        }
        return UIImage(named: name);
    }
    
    // MARK:
    // MARK: CollectionView goodies (mask selector)
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return availableMasks.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("mskcell", forIndexPath: indexPath) as CollectionViewCell
        
        let index = indexPath.row
        dispatch_async(dispatch_get_main_queue()) {
            let maskName = self.getMaskNameForRow(row: index)
            let maskImage = self.getMaskForName(name: maskName)
            
            cell.imageView.image = maskImage
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.showPleaseWait();
        dispatch_async(dispatch_get_main_queue()) {
            let indexPathRow: Int! = indexPath.row;
            let maskName = self.getMaskNameForRow(row: indexPathRow);
            if (maskName != self.selectedMaskName) {
                self.selectedMaskName = maskName;
                self.applyMaskToImage(self.selectedMaskName);
            }
            self.hidePleaseWait();
        }

    }
    
    // MARK: UIImagePicker goodies
    // UIImagePickerControllerDelegate interface/"protocol" implementation
    
    // handle camera capture
    //func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!)
    @IBAction func onImageTouch(sender: AnyObject) {
        presentViewController(imagePicker, animated: true) {}
    }
    
    func initImagePickerController() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .SavedPhotosAlbum
        // .PhotoLibrary, .Camera, .SavedPhotosAlbum
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
//        picker.dismissViewControllerAnimated(false){}
        
        // ignore movies (for now).
        if ("public.movie" == info.valueForKey("UIImagePickerControllerMediaType") as NSString) {
            return;
        }
        
        println("Selected Image: \(info)");
        selectedImageInfoDict = info;
        
        var selectedImage: UIImage = info.valueForKey("UIImagePickerControllerEditedImage") as UIImage;
        
        /*
        // Fullsize image with user selected crop
        var selectedImage: UIImage = info.valueForKey("UIImagePickerControllerOriginalImage") as UIImage;
        var rects: CGRect = (info.objectForKey("UIImagePickerControllerCropRect")?.CGRectValue() as CGRect!);
        selectedImage = ImageMaskingUtils.cropImageToRects(image: selectedImage, rects: rects, context: context)
        */
        var squareImage: UIImage = ImageMaskingUtils.makeItSquare(image: selectedImage, context: context);
        onImageSelected(image: squareImage);
        
        enableToolbar()
        
        precacheMasks()
        
        picker.dismissViewControllerAnimated(false){}
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        picker.dismissViewControllerAnimated(true) {}
    }
    
    func extractMetadataFromImageInfoDict(info: NSDictionary) {
        var imageMetadata:NSMutableDictionary;
        var assetURL = info.valueForKey("UIImagePickerControllerReferenceURL") as NSURL;
        
        var library = ALAssetsLibrary();
    }
    
    // MARK: ActionSheet goodies -- (not used presently)
    // UIActionSheetDelegate interface/"protocol" implementation
    func showActionSheet() {
        var actionSheet = UIActionSheet();
        // TODO: i18n
        actionSheet.addButtonWithTitle("Add layer");
        actionSheet.addButtonWithTitle("Rotate");
        actionSheet.addButtonWithTitle("Save");
        actionSheet.addButtonWithTitle("Share");
        actionSheet.addButtonWithTitle("Delete");
        actionSheet.addButtonWithTitle("About");
        actionSheet.addButtonWithTitle("Cancel");
        actionSheet.cancelButtonIndex = 6;
        actionSheet.showInView(self.view);
        actionSheet.delegate = self;
    }
    
    func actionSheet(actionSheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int){
        switch (buttonIndex) {
            case 0:
                onAddLayer(actionSheet);
                break;
            case 1:
                onRotate(actionSheet);
                break;
            case 2:
                onSave(actionSheet);
                break;
            case 3:
                onShare();
                break;
            case 4:
                onStartOver(actionSheet);
                break;
            case 5:
                onAbout();
                break;
            default:break;
        }
    }
    
    func enableToolbar() {
        toolbar.userInteractionEnabled = true
        toolbar.hidden = false
        maskCollectionView.hidden = false
    }
    
    func disableToolbar() {
        toolbar.userInteractionEnabled = false
        toolbar.hidden = true
        maskCollectionView.hidden = true
    }
    
    // MARK: Mskr goodies
    func onImageSelected(#image: UIImage!) {
        self.maskedImage = image;
        applyMaskToImage(self.selectedMaskName);
    }
    
    func onMaskSelected(#row: Int) {
        self.showPleaseWait();
        dispatch_async(dispatch_get_main_queue()) {
            var maskName: String = self.getMaskNameForRow(row: row);
            self.selectedMaskName = maskName
            self.applyMaskToImage(maskName);
            self.hidePleaseWait();
        }
    }
    
    func applyMaskToImage(maskName: String) -> UIImage! {
        let mask = getMaskForName(name: maskName)
        let masked = applyMaskToImage(image: self.maskedImage, mask: mask)!
        imageView.image = masked
        return masked
    }
    
    func applyMaskToImage(#image: UIImage!, mask: UIImage!) -> UIImage! {
        return ImageMaskingUtils.mergeImages(first: image, second: mask, withAlpha: ALPHA_BLEND_VAL, context: context)
    }
    
    func rotateImage(#image: UIImage, rotation radians: CGFloat) {
        self.maskedImage = ImageMaskingUtils.rotate(image: self.maskedImage, radians: radians, context: context);
        applyMaskToImage(self.selectedMaskName);
    }
    
    @IBAction func onAddLayer(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            var masked = self.applyMaskToImage(self.selectedMaskName);
            self.maskedImage = masked;
            self.imageView.image = self.maskedImage;
        }
    }
    
    func onAddImageLayer() {
        // TODO: Implement
    }
    
    func onAddColorLayer() {
        // TODO: Implement
    }
    
    @IBAction func onRotate(sender: AnyObject) {
        self.showPleaseWait();
        dispatch_async(dispatch_get_main_queue()) {
            var rotationInRatians: CGFloat = CGFloat(M_PI) * (-90) / 180.0;
            self.rotateImage(image: self.maskedImage, rotation: rotationInRatians);
            self.hidePleaseWait();
        }
    }
    
    @IBAction func onSave(sender: AnyObject) {
        // TODO: Write EXIF metadata.
        // See: http://stackoverflow.com/questions/5125323/problem-setting-exif-data-for-an-image
        UIImageWriteToSavedPhotosAlbum(applyMaskToImage(self.selectedMaskName),  nil, nil, nil);
    }
    
    func onShare() {
        var sharingItems = [AnyObject]()
        sharingItems.append("Made with #mskr.")
        
        let image = applyMaskToImage(self.selectedMaskName)
        sharingItems.append(image)
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func onStartOver(sender: AnyObject) {
        self.maskedImage = UIImage(named: "mskr_add");
        imageView.image = self.maskedImage;
        // TODO: Disable new/save/trash/action buttons
        disableToolbar();
    }
    
    func onAbout() {
        // TODO: Implement
    }
    
    @IBAction func onShowActionSheet(sender: AnyObject) {
        //showActionSheet();
        onShare();
    }
    
    var activityIndicatorView: UIActivityIndicatorView
    
    func initAcitvityIndicatiorView() {
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityIndicatorView.alpha = 1.0
        activityIndicatorView.center = CGPointMake(self.view.bounds.width / 2, self.view.bounds.height / 2)
        activityIndicatorView.hidesWhenStopped = true
    }
    
    func showPleaseWait() {
        self.view.addSubview(activityIndicatorView)
        self.activityIndicatorView.startAnimating()
    }
    
    func hidePleaseWait() {
        self.activityIndicatorView.removeFromSuperview()
        self.activityIndicatorView.stopAnimating()
    }

}
