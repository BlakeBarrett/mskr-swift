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
        
        var wid: CGFloat = roundf(
            (newImageSize.width - first.size.width) / 2);
        var hei: CGFloat = roundf(
            (newImageSize.height-first.size.height) / 2);
        let firstPoint = CGPointMake(wid, hei);
        first.drawAtPoint(firstPoint);
        
        wid = roundf(
            (newImageSize.width - second.size.width) / 2);
        hei = roundf(
            (newImageSize.height-second.size.height) / 2);
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
}
