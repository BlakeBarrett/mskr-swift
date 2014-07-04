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
        
        let newImageSize: CGSize = CGSizeMake(
            max(first.size.width, second.size.width),
            max(first.size.height, second.size.height));
        
        if (UIGraphicsBeginImageContextWithOptions != nil) {
            UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1);
        } else {
            UIGraphicsBeginImageContext(newImageSize);
        }
        
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
     */
    class func image(#fromImage: UIImage, withAlpha alpha: CGFloat) -> UIImage {
        return image(fromImage: fromImage, withSize: fromImage.size, andAlpha: alpha);
    }

    class func image(#fromImage: UIImage, withSize size:CGSize, andAlpha alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1);
        
        var ctx: CGContextRef = UIGraphicsGetCurrentContext();
        var area: CGRect = CGRectMake(0, 0, size.width, size.height);
        
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -area.size.height);
        
        CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
        
        CGContextSetAlpha(ctx, alpha);
        
        CGContextDrawImage(ctx, area, fromImage.CGImage);
        
        var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
    /**
     * Stretches images that aren't 1:1 to squares based on their longest edge
     */
    class func makeItSquare(#image: UIImage) -> UIImage {
        let longestSide = max(image.size.width, image.size.height);
        let size: CGSize = CGSize(width: longestSide, height: longestSide);
        
        let x: CGFloat = (size.width - image.size.width) / 2;
        let y: CGFloat = (size.height - image.size.height) / 2;
        
        let cropRect: CGRect = CGRectMake(x, y, size.width, size.height);
        
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
        let cropped: UIImage = UIImage(CGImage: imageRef);
        
        return ImageMaskingUtils.image(fromImage: cropped, withSize: size, andAlpha: 1);
    }
    
    /**
     * Takes an image and rotates it.
     */
    class func rotate(#image: UIImage, radians: CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        var rotatedViewBox: UIView = UIView(frame: CGRectMake(0, 0, image.size.width, image.size.height));
        var transform: CGAffineTransform = CGAffineTransformMakeRotation(radians);
        rotatedViewBox.transform = transform;
        var rotatedSize: CGSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        var bitmap: CGContextRef = UIGraphicsGetCurrentContext();
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        
        // Rotate the image context
        CGContextRotateCTM(bitmap, radians);
        
        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), image.CGImage);
        
        var rotated: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return rotated;
    }
}
