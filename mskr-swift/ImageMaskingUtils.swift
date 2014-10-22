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
    class func maskImage(#source: UIImage!, maskImage: UIImage!) -> CIImage {
        
        let maskRef: CGImageRef! = maskImage.CGImage;
        let mask: CGImageRef! = CGImageMaskCreate(CGImageGetWidth(maskRef),
            CGImageGetHeight(maskRef),
            CGImageGetBitsPerComponent(maskRef),
            CGImageGetBitsPerPixel(maskRef),
            CGImageGetBytesPerRow(maskRef),
            CGImageGetDataProvider(maskRef), nil, true);
        
        let sourceImage: CGImageRef! = source.CGImage;
        let masked: CGImageRef! = CGImageCreateWithMask(sourceImage, mask);
        
        return CIImage(CGImage: masked)
    }
    
    class func resizeImage(#source: UIImage, size: CGSize) -> UIImage {
        
        let largerWidth = max(size.width, source.size.width)
        let smallerWidth = min(size.width, source.size.width)
        
        let largerHeight = max(size.height, source.size.height)
        let smallerHeight = min(size.height, source.size.height)
        
        let widthScale = (smallerWidth / largerWidth) / 2
        let heightScale = (smallerHeight / largerHeight) / 2
        
        let transformedSize = CGSizeApplyAffineTransform(source.size, CGAffineTransformMakeScale(widthScale, heightScale))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(transformedSize, !hasAlpha, scale)
        source.drawInRect(CGRect(origin: CGPointZero, size: transformedSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }

    class func mergeImages(#first: UIImage, second: UIImage, withAlpha alpha: CGFloat, context: CIContext) -> UIImage! {

        var merged: UIImage!;

        var useExperimental = false
        if useExperimental {
            //merged = ImageMaskingUtils.mergeImagesCIFilters(image: first, mask: second, withAlpha: alpha, context: context)
        } else {
            merged = ImageMaskingUtils.mergeImagesUIKit(first: first, second: second, withAlpha: alpha, context: context)
        }

        return merged;
    }
    
    /**
     * Rasterizes two images into one.
     */
    class func mergeImagesUIKit(#first: UIImage, second: UIImage, withAlpha alpha: CGFloat, context: CIContext) -> UIImage! {
        
        let background = UIImage(CIImage: ImageMaskingUtils.image(fromImage: first, withAlpha: alpha))!
        let foreground = UIImage(CIImage: ImageMaskingUtils.maskImage(source: first, maskImage: second))!
        
        let newImageSize = CGSizeMake(
            max(foreground.size.width, background.size.width),
            max(foreground.size.height, background.size.height))
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1)
        
        var wid: CGFloat = (newImageSize.width - foreground.size.width) / 2
        var hei: CGFloat = (newImageSize.height - foreground.size.height) / 2
        
        let foregroundPoint = CGPointMake(wid, hei)
            foreground.drawAtPoint(foregroundPoint)
        
        wid = (newImageSize.width  - background.size.width)  / 2.0
        hei = (newImageSize.height - background.size.height) / 2.0
        
        let backgroundPoint = CGPointMake(wid, hei)
            background.drawAtPoint(backgroundPoint)
       
        var image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /**
     * Rasterizes two images into one.
     */
    class func mergeImagesCIFilters(#image: UIImage, mask: UIImage, withAlpha alpha: CGFloat, context: CIContext) -> UIImage! {
        
        let rects: CGRect = CGRectMake(0, 0, image.size.width, image.size.height)
        
        let background: CIImage = ImageMaskingUtils.image(fromImage: image, withAlpha: alpha)
        let foreground = ImageMaskingUtils.maskImage(source: image, maskImage: mask)
        let scaledMask = CIImage(image: ImageMaskingUtils.resizeImage(source: (mask.copy() as UIImage), size: image.size))
        
        let alphaMaskFilter: CIFilter = CIFilter(name: "CIMaskToAlpha")
            alphaMaskFilter.setValue(scaledMask, forKey: kCIInputImageKey)
        let alphaMaskFilterOutputImage = alphaMaskFilter.valueForKey(kCIOutputImageKey) as CIImage
        let alphaMaskCGImage = context.createCGImage(alphaMaskFilterOutputImage, fromRect: rects)
        let alphaMask = CIImage(CGImage: alphaMaskCGImage)
        
        let filter: CIFilter = CIFilter(name: "CIBlendWithAlphaMask")
            filter.setValue(background, forKey: kCIInputImageKey)
            filter.setValue(foreground, forKey: kCIInputBackgroundImageKey)
            filter.setValue(alphaMask, forKey: kCIInputMaskImageKey)
        
        let outputImage = filter.valueForKey(kCIOutputImageKey) as CIImage
        
        //let outputImage = filter.outputImage!
        let merged = UIImage(CIImage: outputImage)
        
        return merged
    }
    /**
    * Returns a UIImage with the alpha modified
    */
    class func image(#fromImage: UIImage, withAlpha alpha: CGFloat) -> CIImage {
        return image(fromImage: fromImage, withSize: fromImage.size, andAlpha: alpha);
    }
    
    class func image(#fromImage: UIImage, withSize size:CGSize, andAlpha alpha: CGFloat) -> CIImage {
        
        let alphaFadeFilter: CIFilter = CIFilter(name: "CIColorMatrix")
        alphaFadeFilter.setValue(CIImage(image: fromImage), forKey: kCIInputImageKey)
        alphaFadeFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: alpha), forKey: "inputAVector")
        let background: CIImage = alphaFadeFilter.outputImage
        return background;
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
        return UIImage(CGImage: outputCGImageRef)!;
    }
    
}
