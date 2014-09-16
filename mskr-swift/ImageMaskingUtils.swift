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
     * Rasterizes two images into one.
     */
    class func mergeImages(#first: UIImage, second: UIImage, withAlpha alpha: CGFloat, context: CIContext) -> UIImage {
        
        let background = ImageMaskingUtils.image(fromImage: first, withAlpha: alpha)
        let foreground = ImageMaskingUtils.maskImage(source: first, maskImage: second)
        
        let newImageSize: CGSize = CGSizeMake(
            max(foreground.size.width, background.size.width),
            max(foreground.size.height, background.size.height));
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1);
        
        var wid: CGFloat = CGFloat(roundf(
            CFloat(newImageSize.width - foreground.size.width) / 2.0));
        var hei: CGFloat = CGFloat(roundf(
            CFloat(newImageSize.height-foreground.size.height) / 2.0));
        let foregroundPoint = CGPointMake(wid, hei);
        foreground.drawAtPoint(foregroundPoint);
        
        wid = CGFloat(roundf(
            CFloat(newImageSize.width - background.size.width) / 2.0));
        hei = CGFloat(roundf(
            CFloat(newImageSize.height-background.size.height) / 2.0));
        let backgroundPoint = CGPointMake(wid, hei);
        background.drawAtPoint(backgroundPoint);
       
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
        
        let ctx: CGContextRef = UIGraphicsGetCurrentContext();
        let area: CGRect = CGRectMake(0, 0, size.width, size.height);
        
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -area.size.height);
        
        CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
        
        CGContextSetAlpha(ctx, alpha);
        
        CGContextDrawImage(ctx, area, fromImage.CGImage);
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
    /**
     * Crops images that aren't 1:1 to squares based on their shortest edge.
     */
    class func makeItSquare(#image: UIImage, context: CIContext) -> UIImage {
        let shortestSide = min(image.size.width, image.size.height);
        let size: CGSize = CGSize(width: shortestSide, height: shortestSide);
        
        let x: CGFloat = (image.size.width - size.width) / 2;
        let y: CGFloat = (image.size.height - size.height) / 2;
        
        let cropRect: CGRect = CGRectMake(x, y, size.width, size.height);
        return ImageMaskingUtils.uiImageFromCIImage(input: CIImage(image: image), withSize: cropRect, context: context)
    }
    
    /**
     * Crops an image to the rects specified.
     */
    class func cropImageToRects(#image: UIImage, rects: CGRect, context: CIContext) -> UIImage {
        return ImageMaskingUtils.uiImageFromCIImage(input: CIImage(image: image), withSize: rects, context: context)
    }
    
    /**
     * Takes an image and rotates it using CoreImage filters.
     */
    class func rotate(#image: UIImage, radians: CGFloat, context: CIContext) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter: CIFilter = CIFilter(name: "CIStraightenFilter")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radians, forKey: kCIInputAngleKey)
        
        return ImageMaskingUtils.uiImageFromCIImage(input: filter.outputImage, context: context);
    }
    
    class func uiImageFromCIImage(#input: CIImage, context: CIContext) -> UIImage {
        return uiImageFromCIImage(input: input, withSize: input.extent(), context: context);
    }
    
    class func uiImageFromCIImage(#input: CIImage, withSize size: CGRect, context: CIContext) -> UIImage {
        let outputCGImageRef: CGImageRef =  context.createCGImage(input, fromRect: size)
        return UIImage(CGImage: outputCGImageRef);
    }
    
}
