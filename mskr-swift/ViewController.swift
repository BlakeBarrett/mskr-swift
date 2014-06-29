//
//  ViewController.swift
//  mskr-swift
//
//  Created by Blake Barrett on 6/4/14.
//  Copyright (c) 2014 Blake Barrett. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var imagePicker: UIImagePickerController = UIImagePickerController();
    
    var selectedImageInfoDict: NSDictionary = NSDictionary();
    let availableMasks = ["sqr", "crcl", "trngl", "POW", "plrd", "x", "eqlty", "hrt", "dmnd"];
    
    @IBOutlet var maskSelector : UIPickerView;
    @IBOutlet var imageView: UIImageView;
    
    var maskedImage: UIImage = UIImage();
    var selectedMask: UIImage! = UIImage(named: "crclmsk");
    
    let ALPHA_BLEND_VAL: CGFloat! = 0.5;
    
    override func viewDidLoad() {
        imagePicker.delegate = self;
        imagePicker.allowsEditing = true;
        imagePicker.sourceType = .PhotoLibrary
        // .PhotoLibrary, .Camera, .SavedPhotosAlbum
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)
        //TODO: File a bug that if I put the above line in [ ]  I crash the compiler
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onImageTouch(sender: AnyObject) {
        presentViewController(imagePicker, animated: true) {}
    }

    // MARK: UIPickerView goodies
    // UIPickerViewDelegate "protocol" implementation
    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView!) -> Int {
        return 1;
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView!, numberOfRowsInComponent component: Int) -> Int {
        return availableMasks.count;
    }
    
    // UIPickerViewDataSource "protocol" implementation
    func pickerView(pickerView: UIPickerView!, titleForRow row: Int, forComponent component: Int) -> String! {
        return availableMasks[row];
    }
    
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int) {
        onMaskSelected(row: row);
    }
    
    // MARK: UIImagePicker goodies
    // UIImagePickerControllerDelegate interface/"protocol" implementation
    
    // handle camera capture
    //func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!)
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        picker.dismissViewControllerAnimated(true){}
        // enable the mask selector
        maskSelector.userInteractionEnabled = true;

        println("Selected Image: \(info)");
        selectedImageInfoDict = info;
        var selectedImage: UIImage = info.valueForKey("UIImagePickerControllerEditedImage") as UIImage;
        onImageSelected(image: selectedImage);
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        picker.dismissViewControllerAnimated(true) {}
    }
    
    // MARK: Mskr goodies
    func onImageSelected(#image: UIImage!) {
        self.maskedImage = image;
        applyMaskToImage();
    }
    
    func onMaskSelected(#row: Int) {
        var maskName: String = getMaskNameForRow(row: row);
        self.selectedMask = UIImage(named: maskName);
        applyMaskToImage();
    }
    
    func getMaskNameForRow(#row: Int) -> String {
        return availableMasks[row].lowercaseString + "msk";
    }
    
    func applyMaskToImage() -> UIImage! {
        return applyMaskToImage(image: self.maskedImage, mask: self.selectedMask);
    }
    
    func applyMaskToImage(#image: UIImage!, mask: UIImage!) -> UIImage! {
        var masked: UIImage! = (ImageMaskingUtils.maskImage(source: image, maskImage: mask).copy() as UIImage);
        var alphad = ImageMaskingUtils.image(fromImage: self.maskedImage, withAlpha: ALPHA_BLEND_VAL);
        var merged = ImageMaskingUtils.mergeImages(first: masked, second: alphad);
        imageView.image = merged;
        return merged;
    }
    
    @IBAction func onAddLayer(sender: AnyObject) {
        var masked = applyMaskToImage();
        self.maskedImage = masked;
        imageView.image = self.maskedImage;
    }
    
    func onAddImage() {
        // TODO: Implement
    }
    
    @IBAction func onSave(sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(applyMaskToImage(),  nil, nil, nil);
    }
    
    @IBAction func onStartOver(sender: AnyObject) {
        
    }
    
    @IBAction func onShare(sender: AnyObject) {
        
    }

}

