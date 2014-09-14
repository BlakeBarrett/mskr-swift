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
    
    @IBOutlet var imageView: UIImageView!;
    @IBOutlet var toolbar: UIToolbar!;
    @IBOutlet var maskCollectionView: UICollectionView!;
    
    var maskedImage: UIImage = UIImage();
    var selectedMask: UIImage;
    
    // TODO: Hook this up to a slider control somewhere.
    let ALPHA_BLEND_VAL: CGFloat! = 0.5;
    
    var context: CIContext;
    
    required init(coder aDecoder: NSCoder)  {
        self.selectedMask = UIImage(named: "sqrmsk");
        self.context = CIContext(options: nil);
        super.init(coder: aDecoder);
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.selectedMask = UIImage(named: "sqrmsk");
        self.context = CIContext(options: nil);
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }
    
    override func viewDidLoad() {
        self.context = CIContext(options: nil);
        imagePicker.delegate = self;
        imagePicker.allowsEditing = true;
        imagePicker.sourceType = .SavedPhotosAlbum
        // .PhotoLibrary, .Camera, .SavedPhotosAlbum
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
        
        disableToolbar();
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:
    // MARK: CollectionView goodies
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return availableMasks.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("mskcell", forIndexPath: indexPath) as CollectionViewCell
        
        let index = indexPath.row
        let imageName = getMaskNameForRow(row: index)
        let maskImage = UIImage(named: imageName)
        
        cell.imageView.image = maskImage
        return cell
    }
    
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
            let indexPathRow: Int! = indexPath.row;
            let maskName = getMaskNameForRow(row: indexPathRow);
            self.selectedMask = getMaskForName(name: maskName);
            applyMaskToImage();
    }
    
    // MARK: UIImagePicker goodies
    // UIImagePickerControllerDelegate interface/"protocol" implementation
    
    // handle camera capture
    //func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!)
    @IBAction func onImageTouch(sender: AnyObject) {
        presentViewController(imagePicker, animated: true) {}
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        picker.dismissViewControllerAnimated(true){}
        
        // ignore movies (for now).
        if ("public.movie" == info.valueForKey("UIImagePickerControllerMediaType") as NSString) {
            return;
        }
        
        println("Selected Image: \(info)");
        selectedImageInfoDict = info;
        var selectedImage: UIImage = info.valueForKey("UIImagePickerControllerEditedImage") as UIImage;
        var squareImage: UIImage = ImageMaskingUtils.makeItSquare(image: selectedImage);
        onImageSelected(image: squareImage);
        
        enableToolbar();
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        picker.dismissViewControllerAnimated(true) {}
    }
    
    func extractMetadataFromImageInfoDict(info: NSDictionary) {
        var imageMetadata:NSMutableDictionary;
        var assetURL = info.valueForKey("UIImagePickerControllerReferenceURL") as NSURL;
        
        var library = ALAssetsLibrary();
    }
    
    // MARK: ActionSheet goodies
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
        toolbar.userInteractionEnabled = true;
        maskCollectionView.hidden = false;
    }
    
    func disableToolbar() {
        toolbar.userInteractionEnabled = false;
        maskCollectionView.hidden = true;
    }
    
    // MARK: Mskr goodies
    func onImageSelected(#image: UIImage!) {
        self.maskedImage = image;
        applyMaskToImage();
    }
    
    func onMaskSelected(#row: Int) {
        showPleaseWait();
        var maskName: String = getMaskNameForRow(row: row);
        self.selectedMask = UIImage(named: maskName);
        applyMaskToImage();
        hidePleaseWait();
    }
    
    func getMaskNameForRow(#row: Int) -> String {
        return availableMasks[row].lowercaseString + "msk";
    }
    
    func getMaskForName(#name: String) -> UIImage {
        return UIImage(named: name);
    }
    
    func applyMaskToImage() -> UIImage! {
        return applyMaskToImage(image: self.maskedImage, mask: self.selectedMask);
    }
    
    func applyMaskToImage(#image: UIImage!, mask: UIImage!) -> UIImage! {
        var masked: UIImage! = (ImageMaskingUtils.maskImage(source: image, maskImage: mask).copy() as UIImage);
        // TODO: Make this either be alpha or gaussian blur based on user preference
        // See: http://stackoverflow.com/questions/19432773/creating-a-blur-effect-in-ios7
        var background = ImageMaskingUtils.image(fromImage: self.maskedImage, withAlpha: ALPHA_BLEND_VAL);
        var merged = ImageMaskingUtils.mergeImages(first: masked, second: background);
        imageView.image = merged;
        return merged;
    }
    
    func rotateImage(#image: UIImage, rotation radians: CGFloat) {
        showPleaseWait();
        self.maskedImage = ImageMaskingUtils.rotate(image: self.maskedImage, radians: radians, context: context);
        applyMaskToImage();
        hidePleaseWait();
    }
    
    @IBAction func onAddLayer(sender: AnyObject) {
        var masked = applyMaskToImage();
        self.maskedImage = masked;
        imageView.image = self.maskedImage;
    }
    
    func onAddImageLayer() {
        // TODO: Implement
    }
    
    func onAddColorLayer() {
        // TODO: Implement
    }
    
    @IBAction func onRotate(sender: AnyObject) {
        var rotationInRatians: CGFloat = CGFloat(M_PI) * (-90) / 180.0;
        rotateImage(image: self.maskedImage, rotation: rotationInRatians);
    }
    
    @IBAction func onSave(sender: AnyObject) {
        // TODO: Write EXIF metadata.
        // See: http://stackoverflow.com/questions/5125323/problem-setting-exif-data-for-an-image
        UIImageWriteToSavedPhotosAlbum(applyMaskToImage(),  nil, nil, nil);
    }
    
    func onShare() {
        var sharingItems = [AnyObject]()
        sharingItems.append("Made with #mskr.")
        
        let image = applyMaskToImage()
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
    
    var activityIndicatorView = UIActivityIndicatorView();
    
    func showPleaseWait() {
        self.view.addSubview(activityIndicatorView);
    }
    
    func hidePleaseWait() {
        self.activityIndicatorView.removeFromSuperview();
    }

}

