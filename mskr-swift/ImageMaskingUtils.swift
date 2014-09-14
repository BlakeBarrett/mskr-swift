//
//  ImageMaskingUtils.swift
//  mskr-swift
//
//  Created by Blake Barrett on 6/6/14.
//  Copyright (c) 2014 Blake Barrett. All rights reserved.
//

import Foundation
import UIKit

class ImageMaskingUtils {
    
    /**
     * Masks the source image with the second.
     */
    class func maskImage(#source: UIImage!, maskImage: UIImage!) -> UIImage {
        
        let maskRef: CGImageRef! = maskImage.CGImage;
        let mask: CGImageRef! = CGImageMaskCreate(CGImageGetWidth(maskRef),
            CGImageGetHeight(maskRef),
            CGImageGetBitsPerComponent(maskRef),
            CGImageGetBitsPerPixel(maskRef),
            CGImageGetBytesPerRow(maskRef),
            CGImageGetDataProvider(maskRef), nil, true);
        
        let sourceImage: CGImageRef! = source.CGImage;
        let masked: CGImageRef! = CGImageCreateWithMask(sourceImage, mask);
        
        var maskedImage = UIImage(CGImage: masked);
        
        return maskedImage;
    }
    
    /**
     * Flattens or rasterizes two images into one.
     */
    class func mergeImages(#first: UIImage, second: UIImage) -> UIImage {
        
        // TODO: use CIFilter(name: "CIBlendWithAlphaMask") or CIFilter(name: "CIBlendWithMask")
        // https://developer.apple.com/library/mac/documentation/graphicsimaging/reference/CoreImageFilterReference/Reference/reference.html#//apple_ref/doc/uid/TP30000136-DontLinkElementID_14
        
        
        let newImageSize: CGSize = CGSizeMake(
            max(first.size.width, second.size.width),
            max(first.size.height, second.size.height));

        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1);
        
        var wid: CGFloat = CGFloat(roundf(
            CFloat(newImageSize.width - first.size.width) / 2.0));
        var hei: CGFloat = CGFloat(roundf(
            CFloat(newImageSize.height-first.size.height) / 2.0));
        let firstPoint = CGPointMake(wid, hei);
        first.drawAtPoint(firstPoint);
        
        wid = CGFloat(roundf(
            CFloat(newImageSize.width - second.size.width) / 2.0));
        hei = CGFloat(roundf(
            CFloat(newImageSize.height-second.size.height) / 2.0));
        let secondPoint = CGPointMake(wid, hei);
        second.drawAtPoint(secondPoint);
        
        var image: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
    
    /**
     * Returns a UIImage with the alpha modified
     * Uses Core Image Filter
     */
    class func image(#fromImage: UIImage, withAlpha alpha: CGFloat, context: CIContext) -> UIImage {
        let ciImage = CIImage(image: fromImage)
        let filter: CIFilter = CIFilter(name: "CIColorMatrix")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: alpha), forKey: "inputAVector")
        
        let outputCIImage: CIImage = filter.outputImage!
        let outputCGImageRef: CGImageRef =  context.createCGImage(outputCIImage, fromRect: outputCIImage.extent())
        return UIImage(CGImage: outputCGImageRef);
    }
    
    /**
     * Stretches images that aren't 1:1 to squares based on their longest edge
     */
    class func makeItSquare(#image: UIImage, context: CIContext) -> UIImage {
        let shortestSide = min(image.size.width, image.size.height);
        let size: CGSize = CGSize(width: shortestSide, height: shortestSide);
        
        let x: CGFloat = (image.size.width - size.width) / 2;
        let y: CGFloat = (image.size.height - size.height) / 2;
        
        let cropRect: CGRect = CGRectMake(x, y, size.width, size.height);
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
        let cropped: UIImage = UIImage(CGImage: imageRef);
        
        return ImageMaskingUtils.image(fromImage: cropped, withAlpha: 1, context: context);
    }
    
    /**
     * Takes an image and rotates it using CoreImage filters.
     */
    class func rotate(#image: UIImage, radians: CGFloat, context: CIContext) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter: CIFilter = CIFilter(name: "CIStraightenFilter")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radians, forKey: kCIInputAngleKey)
        
        let outputCIImage: CIImage = filter.outputImage!
        let outputCGImageRef: CGImageRef =  context.createCGImage(outputCIImage, fromRect: outputCIImage.extent())
        return UIImage(CGImage: outputCGImageRef);
    }
}
