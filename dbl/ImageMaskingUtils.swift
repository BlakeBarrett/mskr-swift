//
//  ImageMaskingUtils.swift
//  mskr
//
//  Created by Blake Barrett on 6/6/14.
//  Copyright © 2014 Blake Barrett. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class ImageMaskingUtils {
    
    // TODO: Implement "Green Screen" a.k.a. Chroma Key/Color Replacement.
    // https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html#//apple_ref/doc/uid/TP30001185-CH4-SW2
    // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html#//apple_ref/doc/uid/TP30001185-CH3-BAJDAHAD
    
    // Apple's docs on CIFilters:
    // https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
    
    // Video modification tutorials:
    // https://www.objc.io/issues/23-video/core-image-video/
    // http://krakendev.io/blog/be-cool-with-cifilter-animations
    // https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/FunctionalCoreImage.swift
    // Merge and Export videos:
    // https://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
    // https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVMutableComposition_Class/
    // Overlay videos:
    // https://abdulazeem.wordpress.com/2012/04/02/video-manipulation-in-ios-resizingmerging-and-overlapping-videos-in-ios/
    
    /**
     * Changes the saturation of the image to the provided value
     */
    class func setImageSaturation(_ image: UIImage!, saturation: NSNumber) -> UIImage {
        return ImageMaskingUtils.colorControlImage(image, brightness: 1.0, saturation: saturation, contrast: 1.0)
    }
    
    /**
     * Changes the brightness of the image
     */
    class func setImageBrightness(_ image: UIImage, brightness: NSNumber) -> UIImage {
        return ImageMaskingUtils.colorControlImage(image, brightness: brightness, saturation: 1.0, contrast: 1.0)
    }
    
    /**
     * Changes the contrast of the image
     */
    class func setImageContrast(_ image: UIImage, contrast: NSNumber) -> UIImage {
        return ImageMaskingUtils.colorControlImage(image, brightness: 1.0, saturation: 1.0, contrast: contrast)
    }
    
    /**
     * Modifies the image's Saturation/Brightness/Contrast
     */
    class func colorControlImage(_ image: UIImage, brightness: NSNumber, saturation: NSNumber, contrast: NSNumber) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        //ciImage?.imageByApplyingTransform:CGAffineTransformMakeTranslation(100, 100)]
        
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        guard let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage else {
            UIGraphicsEndImageContext()
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let ret = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
        UIGraphicsEndImageContext()
        return ret
    }
    
    /**
     * Changes the saturation of the image to the provided value
     */
    class func noirImage(_ image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage else {
            UIGraphicsEndImageContext()
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let ret = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
        UIGraphicsEndImageContext()
        return ret
    }
    
    /**
     * Invert colors of image
     */
    class func invertImageColors(_ image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage else {
            UIGraphicsEndImageContext()
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let ret = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
        UIGraphicsEndImageContext()
        return ret
    }
    
    /**
     * Takes a greyscale image, darker the color the lower the alpha (0x000000 == 0.0)
     */
    class func imageToMask(_ image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIMaskToAlpha")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage else {
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        return UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
    }
    
    /**
     * Masks the source image with the mask.
     */
    class func maskImage(_ source: UIImage!, maskImage: UIImage!) -> UIImage {
        
        // try the quick and dirty first
        if let mskd: CGImage = source.cgImage?.masking(invertImageColors(maskImage).cgImage!) {
            log("CGImageCreateWithMask returned nil from source: \(source.cgImage) mask: \(maskImage.cgImage)")
            return UIImage(cgImage: mskd)
        } // okay then, do it the longer way
        
        guard let _ = maskImage.cgImage else {
            log("maskRef was nil")
            return source
        }
        
        guard let mask: CGImage = CGImage(maskWidth: (maskImage.cgImage?.width)!,
                                                       height: (maskImage.cgImage?.height)!,
                                                       bitsPerComponent: (maskImage.cgImage?.bitsPerComponent)!,
                                                       bitsPerPixel: (maskImage.cgImage?.bitsPerPixel)!,
                                                       bytesPerRow: (maskImage.cgImage?.bytesPerRow)!,
                                                       provider: (maskImage.cgImage?.dataProvider!)!, decode: nil, shouldInterpolate: true) else {
                                                        log("CGImageMaskCreate was nil")
                                                        return source
        }
        
        guard let _ = source.cgImage else {
            log("source.CGImage was nil")
            return source
        }
        
        guard let masked: CGImage = source.cgImage?.masking(mask) else {
            log("CGImageCreateWithMask returned nil from source: \(source.cgImage) mask: \(mask)")
            return source
        }
        
        return UIImage(cgImage: masked)
    }
    
    /**
     * Flattens or rasterizes two images into one.
     */
    class func mergeImages(_ first: UIImage, second: UIImage) -> UIImage {
        let newImageSize: CGSize = CGSize(
            width: max(first.size.width, second.size.width),
            height: max(first.size.height, second.size.height))
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1)
        
        var wid: CGFloat = CGFloat(roundf(CFloat(newImageSize.width - first.size.width) / 2.0))
        var hei: CGFloat = CGFloat(roundf(CFloat(newImageSize.height-first.size.height) / 2.0))
        
        let firstPoint = CGPoint(x: wid, y: hei)
        first.draw(at: firstPoint)
        
        wid = CGFloat(roundf(CFloat(newImageSize.width - second.size.width) / 2.0))
        hei = CGFloat(roundf(CFloat(newImageSize.height-second.size.height) / 2.0))
        
        let secondPoint = CGPoint(x: wid, y: hei);
        second.draw(at: secondPoint)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func crop(_ image: UIImage, inRect rect: CGRect) -> UIImage {
        let imageRef = image.cgImage?.cropping(to: rect)
        return UIImage(cgImage: imageRef!)
    }
    
    class func fit(_ image:UIImage, inSize: CGSize) -> UIImage {
        let size = inSize
        let originalAspectRatio = image.size.width / image.size.height
        
        let rect: CGRect
        let width, height, x, y: CGFloat
        //      width > height
        if (originalAspectRatio > 1) {
            // this appears to work
            width = size.width
            height = size.width / originalAspectRatio
            x = 0
            y = (size.height - height) / 2
            rect = CGRect(
                x: x, y: y,
                width: width,
                height: height
            )
        } else {
            // while this does not
            width = size.height * originalAspectRatio
            height = size.height
            x = (size.width - width) / 2
            y = 0
            rect = CGRect(
                x: x, y: y,
                width: width,
                height: height
            )
        }
        
        UIGraphicsBeginImageContext(size)
        image.draw(in: rect)
        
        let rasterized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rasterized!
    }
    /*
    class func imagePreservingAspectRatio(fromImage: UIImage, withSize size: CGSize, andAlpha alpha: CGFloat) -> UIImage {
        let originalSize = fromImage.size
        let naturalAspectRatio = originalSize.width / originalSize.height
        var newSize: CGSize
        if (fromImage.size.width > fromImage.size.height) {
            if (originalSize.width < originalSize.height) {
                newSize = CGSizeMake(size.width, size.width * naturalAspectRatio)
            } else {
                newSize = CGSizeMake(size.width * naturalAspectRatio, size.width)
            }
        } else {
            if (originalSize.width < originalSize.height) {
                newSize = CGSizeMake(size.height, size.height * naturalAspectRatio)
            } else {
                newSize = CGSizeMake(size.height * naturalAspectRatio, size.height)
            }
        }
        return ImageMaskingUtils.image(fromImage, withSize: newSize, andAlpha: alpha)
    }
    */
    /**
     * Returns a UIImage with the alpha modified
     */
    class func image(_ fromImage: UIImage, withAlpha alpha: CGFloat) -> UIImage {
        return image(fromImage, withSize: fromImage.size, andAlpha: alpha);
    }
    
    /**
     * Returns a UIImage with size and alpha passed in.
     * size param overrides image's natural size and aspect ratio.
     **/
    class func image(_ fromImage: UIImage, withSize size:CGSize, andAlpha alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        let area: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -area.size.height)
        
        ctx.setBlendMode(CGBlendMode.multiply)
        
        ctx.setAlpha(alpha)
        
        ctx.draw(fromImage.cgImage!, in: area)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
     * Resize image: http://stackoverflow.com/a/12140767 and http://nshipster.com/image-resizing/
     **/
    class func resize(_ image: UIImage, size: CGSize) -> UIImage {
        let cgImage = image.cgImage
        let colorspace = cgImage?.colorSpace
        
        let context = CGContext(data: nil,
                                            width: Int(size.width), height: Int(size.height),
                                            bitsPerComponent: (cgImage?.bitsPerComponent)!,
                                            bytesPerRow: (cgImage?.bytesPerRow)!,
                                            space: colorspace!,
                                            bitmapInfo: (cgImage?.alphaInfo.rawValue)!)
        
        context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        // extract resulting image from context
        guard let imgRef = context?.makeImage() else {
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()
        let resizedImage = UIImage(cgImage: imgRef)
        return resizedImage
    }
    
    /**
     * Stretches images that aren't 1:1 to squares based on their longest edge
     */
    class func makeItSquare(_ image: UIImage) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        let size: CGSize = CGSize(width: longestSide, height: longestSide)
        
        let x: CGFloat = (size.width - image.size.width) / 2
        let y: CGFloat = (size.height - image.size.height) / 2
        
        let cropRect: CGRect = CGRect(x: x, y: y, width: size.width, height: size.height)
        
        let imageRef: CGImage = image.cgImage!.cropping(to: cropRect)!
        let cropped: UIImage = UIImage(cgImage: imageRef)
        UIGraphicsEndImageContext()
        return ImageMaskingUtils.image(cropped, withSize: size, andAlpha: 1)
    }
    
    /**
     * Takes an image and rotates it.
     */
    class func rotate(_ image: UIImage, radians: CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height));
        let transform: CGAffineTransform = CGAffineTransform(rotationAngle: radians);
        rotatedViewBox.transform = transform;
        let rotatedSize: CGSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2);
        
        // Rotate the image context
        bitmap.rotate(by: radians);
        
        // Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0);
        bitmap.draw(image.cgImage!, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height));
        
        let rotated: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        return rotated;
    }
    
    /**
     * Fix the image orientation issues we've seen.
     * Translated from Objective-C from here: http://stackoverflow.com/a/1262395
     **/
    class func reconcileImageOrientation(_ image:UIImage) -> UIImage {
        let targetWidth = Int(image.size.width)
        let targetHeight = Int(image.size.height)
        
        let imageRef = image.cgImage
        let bitmapInfo = imageRef!.bitmapInfo
        let colorSpaceInfo = imageRef!.colorSpace
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(image.size);
        var bitmap: CGContext = UIGraphicsGetCurrentContext()!
        
        if (image.imageOrientation == UIImageOrientation.up || image.imageOrientation == UIImageOrientation.down) {
            bitmap = CGContext(data: nil, width: targetWidth, height: targetHeight, bitsPerComponent: (imageRef?.bitsPerComponent)!, bytesPerRow: (imageRef?.bytesPerRow)!, space: colorSpaceInfo!, bitmapInfo: bitmapInfo.rawValue)!
        } else {
            bitmap = CGContext(data: nil, width: targetHeight, height: targetWidth, bitsPerComponent: (imageRef?.bitsPerComponent)!, bytesPerRow: (imageRef?.bytesPerRow)!, space: colorSpaceInfo!, bitmapInfo: bitmapInfo.rawValue)!
        }
        
        if (image.imageOrientation == UIImageOrientation.left) {
            bitmap.rotate (by: radians(90))
            bitmap.translateBy (x: 0, y: CGFloat(-targetHeight))
        } else if (image.imageOrientation == UIImageOrientation.right) {
            bitmap.rotate (by: radians(-90))
            bitmap.translateBy (x: CGFloat(-targetWidth), y: 0)
        } else if (image.imageOrientation == UIImageOrientation.up) {
            // NOTHING
        } else if (image.imageOrientation == UIImageOrientation.down) {
            bitmap.translateBy (x: CGFloat(targetWidth), y: CGFloat(targetHeight))
            bitmap.rotate (by: radians(-180))
        }
        
        bitmap.draw(imageRef!, in: CGRect(x: 0, y: 0, width: CGFloat(targetWidth), height: CGFloat(targetHeight)))
        let ref = bitmap.makeImage()
        let newImage = UIImage(cgImage: ref!)
        
        UIGraphicsEndImageContext()
        
        return newImage;
    }
    
    static func radians (_ degrees: Int) -> CGFloat {
        return CGFloat(Double(degrees) * M_PI / 180.0)
    }
    
    static func log(_ message:String) {
        print(message)
    }
}
