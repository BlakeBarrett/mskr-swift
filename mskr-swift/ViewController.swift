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
    var selectedMask: String = "crclmsk";
    let availableMasks = ["sqr", "crcl", "trngl", "POW", "plrd", "x", "eqlty", "hrt", "dmnd"];
    
    @IBOutlet var maskSelector : UIPickerView;
    @IBOutlet var imageView: UIImageView;
    @IBOutlet var backgroundImageView: UIImageView;
    
    var currentImage: UIImage = UIImage();
    var backgroundImage: UIImage = UIImage();
    var maskImage: UIImage = UIImage(named: "crclmsk");
    
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
        var maskName = availableMasks[row] + "msk";
        
        var mask: UIImage = UIImage(named: maskName);
        self.maskImage = mask;
        
        var img: UIImage = self.currentImage;
        
        onImageSelected(image: img, mask: mask);
    }
    
    // MARK: UIImagePicker goodies
    // UIImagePickerControllerDelegate interface/"protocol" implementation
    
    // handle camera capture
    //func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!)
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        println("Selected Image: \(info)");
        selectedImageInfoDict = info;
        
        var selectedImage: UIImage = info.valueForKey("UIImagePickerControllerEditedImage") as UIImage;
        onImageSelected(image: selectedImage, mask: self.maskImage);
        
        picker.dismissViewControllerAnimated(true){}
        
        // enable the mask selector
        maskSelector.userInteractionEnabled = true;
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        picker.dismissViewControllerAnimated(true) {}
    }
    
    // MARK: Mskr goodies
    func onImageSelected(#image: UIImage!, mask: UIImage!) {
        // background
        self.backgroundImage = ImageMaskingUtils.image(fromImage: image, withAlpha: 0.5);
        backgroundImageView.image = backgroundImage;

        // foreground
        self.currentImage = ImageMaskingUtils.maskImage(source: image, maskImage: mask);
        imageView.image = currentImage;
    }
    
    @IBAction func onAddLayer(sender: AnyObject) {
        currentImage = imageView.image;
        var tempImage: UIImage = ImageMaskingUtils.mergeImages(first: backgroundImage, second: currentImage);
        // TODO: Set alpha to .5
        backgroundImage = ImageMaskingUtils.image(fromImage: tempImage, withAlpha: 0.5);
        currentImage = tempImage;
        imageView.image = tempImage;
    }
    
    func onAddImage() {
        
    }
    
    @IBAction func onSave(sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(imageView.image,  nil, nil, nil);
    }
    
    @IBAction func onStartOver(sender: AnyObject) {
        
    }
    
    @IBAction func onShare(sender: AnyObject) {
        
    }

}

