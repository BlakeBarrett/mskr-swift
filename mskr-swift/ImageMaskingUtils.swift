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
     * Rasterizes two images into one.
     */
    class func mergeImages(#first: UIImage, second: UIImage, withAlpha alpha: CGFloat, context: CIContext) -> UIImage {
        let foreground = CIImage(image: first)

        // create a faded image (for the background)
        let alphaFadeFilter: CIFilter = CIFilter(name: "CIColorMatrix")
        alphaFadeFilter.setValue(foreground, forKey: kCIInputImageKey)
        alphaFadeFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: alpha), forKey: "inputAVector")
        let background: CIImage = alphaFadeFilter.outputImage
        
        // convert the mask image into alpha mask
        let alphaMaskFilter: CIFilter = CIFilter(name: "CIMaskToAlpha")
        alphaMaskFilter.setValue(CIImage(image: second), forKey: kCIInputImageKey)
        let alphaMask = alphaMaskFilter.outputImage;
        
        // scale the mask to the appropriate size
        let scale = foreground.extent().width / alphaMask.extent().width;
        let maskScaleFilter: CIFilter = CIFilter(name: "CILanczosScaleTransform")
        maskScaleFilter.setValue(alphaMask, forKey: kCIInputImageKey)
        maskScaleFilter.setValue(scale, forKey: kCIInputScaleKey);
        let scaledMask = maskScaleFilter.outputImage;
        
        // merge all elements
        let filter: CIFilter = CIFilter(name: "CIBlendWithAlphaMask")
        filter.setValue(background, forKey: kCIInputImageKey)
        filter.setValue(foreground, forKey: kCIInputBackgroundImageKey)
        filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)

        return ImageMaskingUtils.uiImageFromCIImage(input: filter.outputImage, context: context);
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
        let outputCIImage: CIImage = input
        let outputCGImageRef: CGImageRef =  context.createCGImage(outputCIImage, fromRect: size)
        return UIImage(CGImage: outputCGImageRef);
    }
    
}
