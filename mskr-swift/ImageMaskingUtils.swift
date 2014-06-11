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
        
        let maskedUIImage: UIImage! = UIImage(CGImage: masked);
        
        // Because maskedUIIMage is of type UIImage!, there shouldn't be
        // any way for it to be nil. This is to handle whatever is causing 
        // this being recycled/garbage-collected prematurely.
        if (maskedUIImage) {
            return maskedUIImage;
        } else {
            return source;
        }
    }
    
    /**
     * Flattens or rasterizes two images into one.
     */
    class func mergeImages(#first: UIImage, second: UIImage) -> UIImage {
        
        let newImageSize: CGSize = CGSizeMake(
            max(first.size.width, second.size.width),
            max(first.size.height, second.size.height));
        
        if (UIGraphicsBeginImageContextWithOptions != nil) {
            UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen().scale);
        } else {
            UIGraphicsBeginImageContext(newImageSize);
        }
        
        let TWO: CGFloat = 2;
        var wid: CGFloat = roundf(
            (newImageSize.width - first.size.width) / TWO);
        var hei: CGFloat = roundf(
            (newImageSize.height-first.size.height) / TWO);
        let firstPoint = CGPointMake(wid, hei);
        first.drawAtPoint(firstPoint);
        
        wid = roundf(
            (newImageSize.width - second.size.width) / TWO);
        hei = roundf(
            (newImageSize.height-second.size.height) / TWO);
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
        
        var size: CGSize = fromImage.size;
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
        
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
}