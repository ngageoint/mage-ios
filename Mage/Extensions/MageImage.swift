//
//  MageImage.swift
//  MAGE
//
//  Created by Daniel Barela on 11/12/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import AVKit

extension CIImage {
    func qualityScaled() -> Data? {
        let kImageQualitySmall = 0;
        let kImageQualityMedium = 1;
        let kImageQualityLarge = 2;
        
        let kImageMaxDimensionSmall: CGFloat = 320.0;
        let kImageMaxDimensionMedium: CGFloat = 640.0;
        let kImageMaxDimensionLarge: CGFloat = 2048.0;
        
        let imageDefaults = UserDefaults.standard.imageUploadSizes;
        let imageUploadQuality: Int = UserDefaults.standard.integer(forKey: imageDefaults?["preferenceKey"] as? String ?? "imageUploadSize");
        let largestDimension: CGFloat = max(self.extent.width, self.extent.height);
        var scale: CGFloat = 1.0;
        if (imageUploadQuality == kImageQualitySmall && largestDimension > kImageMaxDimensionSmall) {
            scale = kImageMaxDimensionSmall / largestDimension;
        } else if (imageUploadQuality == kImageQualityMedium && largestDimension > kImageMaxDimensionMedium) {
            scale = kImageMaxDimensionMedium / largestDimension;
        } else if (imageUploadQuality == kImageQualityLarge && largestDimension > kImageMaxDimensionLarge) {
            scale = kImageMaxDimensionLarge / largestDimension;
        }
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey:kCIInputAspectRatioKey)
        return (filter.value(forKey: kCIOutputImageKey) as! CIImage).jpegData()
    }
    
    func jpegData() -> Data? {
        if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                let context = CIContext()
            return context.jpegRepresentation(of: self, colorSpace: colorSpace, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : 1.0])
        }
        return nil
    }
}

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    @objc func aspectResize(to size: CGSize) -> UIImage {
        let scaledRect = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height));
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: scaledRect)
        }
    }
    
    @objc func aspectResizeJpeg(to size: CGSize) -> Data? {
        let scaledRect = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height));
        return UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 1.0) { ctx in
            
            draw(in: scaledRect)
        }
    }
    
    func qualityScaled() -> Data? {
        let kImageQualitySmall = 0;
        let kImageQualityMedium = 1;
        let kImageQualityLarge = 2;
        
        let kImageMaxDimensionSmall: CGFloat = 320.0;
        let kImageMaxDimensionMedium: CGFloat = 640.0;
        let kImageMaxDimensionLarge: CGFloat = 2048.0;

        let imageDefaults = UserDefaults.standard.imageUploadSizes;
        let imageUploadQuality: Int = UserDefaults.standard.integer(forKey: imageDefaults?["preferenceKey"] as? String ?? "imageUploadSize");
        
        let largestDimension: CGFloat = max(self.size.width, self.size.height);
        var scale: CGFloat = 1.0;
        if (imageUploadQuality == kImageQualitySmall && largestDimension > kImageMaxDimensionSmall) {
            scale = kImageMaxDimensionSmall / largestDimension;
        } else if (imageUploadQuality == kImageQualityMedium && largestDimension > kImageMaxDimensionMedium) {
            scale = kImageMaxDimensionMedium / largestDimension;
        } else if (imageUploadQuality == kImageQualityLarge && largestDimension > kImageMaxDimensionLarge) {
            scale = kImageMaxDimensionLarge / largestDimension;
        } else {
            return self.jpegData(compressionQuality: 1.0);
        }
        
        let size = CGSize(width: self.size.width * scale, height: self.size.height * scale);
        return aspectResizeJpeg(to: size);
    }
}
