//
//  ImageMaskingUtils.swift
//  mskr
//
//  Created by Blake Barrett on 6/6/14.
//  Copyright © 2014 Blake Barrett. All rights reserved.
//

import Foundation
import UIKit

class ImageMaskingUtils {
    
    /**
     * Modifies the image's Saturation/Brightness/Contrast
     */
    class func colorControlImage(image: UIImage) -> UIImage {
        let context = CIContext()
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        //ciImage?.imageByApplyingTransform:CGAffineTransformMakeTranslation(100, 100)]
        
        //Saturation: NSNumber/CIAttributeTypeScalar
        //Brightness
        //Contrast
        
        filter?.setValue(2.0, forKey: kCIInputContrastKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            return image
        }
        let ciImageRef = context.createCGImage(result, fromRect: result.extent)
        let returnImage = UIImage(CGImage: ciImageRef)
        return returnImage
    }
    
    /**
    * Changes the saturation of the image to the provided value
    */
    class func noirImage(image: UIImage!) -> UIImage {
        let context = CIContext()
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            return image
        }
        let ciImageRef = context.createCGImage(result, fromRect: result.extent)
        let returnImage = UIImage(CGImage: ciImageRef)
        return returnImage
    }
    
    /**
     * Changes the saturation of the image to the provided value
     */
    class func saturateImage(image: UIImage!, saturation: CGFloat) -> UIImage {
        let context = CIContext()
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            return image
        }
        let ciImageRef = context.createCGImage(result, fromRect: result.extent)
        let returnImage = UIImage(CGImage: ciImageRef)
        return returnImage
    }
    
    /**
     * Invert colors of image
     */
    class func invertImageColors(image: UIImage) -> UIImage {
        let context = CIContext()
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            return image
        }
        let ciImageRef = context.createCGImage(result, fromRect: result.extent)
        let returnImage = UIImage(CGImage: ciImageRef)
        return returnImage
    }
    
    /**
     * Takes a greyscale image, darker the color the lower the alpha (0x000000 == 0.0)
     */
    class func imageToMask(image: UIImage) -> UIImage {
        let context = CIContext()
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIMaskToAlpha")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            return image
        }
        let ciImageRef = context.createCGImage(result, fromRect: result.extent)
        let returnImage = UIImage(CGImage: ciImageRef)
        return returnImage
    }
    
    /**
     * Masks the source image with the second.
     */
    class func maskImage(source: UIImage!, maskImage: UIImage!) -> UIImage {
        let maskRef: CGImageRef! = maskImage.CGImage
        let mask: CGImageRef! = CGImageMaskCreate(CGImageGetWidth(maskRef),
            CGImageGetHeight(maskRef),
            CGImageGetBitsPerComponent(maskRef),
            CGImageGetBitsPerPixel(maskRef),
            CGImageGetBytesPerRow(maskRef),
            CGImageGetDataProvider(maskRef), nil, true)
        
        let sourceImage: CGImageRef! = source.CGImage
        let masked: CGImageRef! = CGImageCreateWithMask(sourceImage, mask)
        
        let maskedImage = UIImage(CGImage: masked)
        
        return maskedImage
    }
    
    /**
     * Flattens or rasterizes two images into one.
     */
    class func mergeImages(first: UIImage, second: UIImage) -> UIImage {
        
        let newImageSize: CGSize = CGSizeMake(
            max(first.size.width, second.size.width),
            max(first.size.height, second.size.height))

        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1)
        
        var wid: CGFloat = CGFloat(roundf(CFloat(newImageSize.width - first.size.width) / 2.0))
        var hei: CGFloat = CGFloat(roundf(CFloat(newImageSize.height-first.size.height) / 2.0))
        
        let firstPoint = CGPointMake(wid, hei)
        first.drawAtPoint(firstPoint)
        
        wid = CGFloat(roundf(CFloat(newImageSize.width - second.size.width) / 2.0))
        hei = CGFloat(roundf(CFloat(newImageSize.height-second.size.height) / 2.0))
        
        let secondPoint = CGPointMake(wid, hei);
        second.drawAtPoint(secondPoint)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /**
     * Returns a UIImage with the alpha modified
     */
    class func image(fromImage: UIImage, withAlpha alpha: CGFloat) -> UIImage {
        return image(fromImage, withSize: fromImage.size, andAlpha: alpha);
    }

    class func image(fromImage: UIImage, withSize size:CGSize, andAlpha alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
        let area: CGRect = CGRectMake(0, 0, size.width, size.height)
        
        CGContextScaleCTM(ctx, 1, -1)
        CGContextTranslateCTM(ctx, 0, -area.size.height)
        
        CGContextSetBlendMode(ctx, CGBlendMode.Multiply)
        
        CGContextSetAlpha(ctx, alpha)
        
        CGContextDrawImage(ctx, area, fromImage.CGImage)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
     * Stretches images that aren't 1:1 to squares based on their longest edge
     */
    class func makeItSquare(image: UIImage) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        let size: CGSize = CGSize(width: longestSide, height: longestSide)
        
        let x: CGFloat = (size.width - image.size.width) / 2
        let y: CGFloat = (size.height - image.size.height) / 2
        
        let cropRect: CGRect = CGRectMake(x, y, size.width, size.height)
        
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(image.CGImage!, cropRect)!
        let cropped: UIImage = UIImage(CGImage: imageRef)
        
        return ImageMaskingUtils.image(cropped, withSize: size, andAlpha: 1)
    }
    
    /**
     * Takes an image and rotates it.
     */
    class func rotate(image: UIImage, radians: CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRectMake(0, 0, image.size.width, image.size.height));
        let transform: CGAffineTransform = CGAffineTransformMakeRotation(radians);
        rotatedViewBox.transform = transform;
        let rotatedSize: CGSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        let bitmap: CGContextRef = UIGraphicsGetCurrentContext()!
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        
        // Rotate the image context
        CGContextRotateCTM(bitmap, radians);
        
        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), image.CGImage);
        
        let rotated: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return rotated;
    }
    
    /**
     * Fix the image orientation issues we've seen.
     * Translated from Objective-C from here: http://stackoverflow.com/a/1262395
     **/
    class func reconcileImageOrientation(image:UIImage) -> UIImage {
        let targetWidth = Int(image.size.width)
        let targetHeight = Int(image.size.height)
        
        let imageRef = image.CGImage
        let bitmapInfo = CGImageGetBitmapInfo(imageRef!)
        let colorSpaceInfo = CGImageGetColorSpace(imageRef!)
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(image.size);
        var bitmap: CGContextRef = UIGraphicsGetCurrentContext()!

        if (image.imageOrientation == UIImageOrientation.Up || image.imageOrientation == UIImageOrientation.Down) {
            bitmap = CGBitmapContextCreate(nil, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo.rawValue)!
        } else {
            bitmap = CGBitmapContextCreate(nil, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo.rawValue)!
        }
        
        if (image.imageOrientation == UIImageOrientation.Left) {
            CGContextRotateCTM (bitmap, radians(90))
            CGContextTranslateCTM (bitmap, 0, CGFloat(-targetHeight))
        } else if (image.imageOrientation == UIImageOrientation.Right) {
            CGContextRotateCTM (bitmap, radians(-90))
            CGContextTranslateCTM (bitmap, CGFloat(-targetWidth), 0)
        } else if (image.imageOrientation == UIImageOrientation.Up) {
            // NOTHING
        } else if (image.imageOrientation == UIImageOrientation.Down) {
            CGContextTranslateCTM (bitmap, CGFloat(targetWidth), CGFloat(targetHeight))
            CGContextRotateCTM (bitmap, radians(-180))
        }
        
        CGContextDrawImage(bitmap, CGRectMake(0, 0, CGFloat(targetWidth), CGFloat(targetHeight)), imageRef)
        let ref = CGBitmapContextCreateImage(bitmap)
        let newImage = UIImage(CGImage: ref!)
        
        return newImage;
    }
    
    static func radians (degrees: Int) -> CGFloat {
        return CGFloat(Double(degrees) * M_PI / 180.0)
    }
}
