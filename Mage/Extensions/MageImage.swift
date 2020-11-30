//
//  MageImage.swift
//  MAGE
//
//  Created by Daniel Barela on 11/12/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func aspectResize(to size: CGSize) -> UIImage {
        let scaledRect = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height));
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: scaledRect)
        }
    }
    
    func qualityScaled() -> UIImage {
        
        let kImageQualitySmall = 0;
        let kImageQualityMedium = 1;
        let kImageQualityLarge = 2;
        
        let kImageMaxDimensionSmall: CGFloat = 320.0;
        let kImageMaxDimensionMedium: CGFloat = 640.0;
        let kImageMaxDimensionLarge: CGFloat = 2048.0;

        let imageDefaults = UserDefaults.standard.dictionary(forKey: "imageUploadSizes");
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
            return self;
        }
        
        let size = CGSize(width: self.size.width * scale, height: self.size.height * scale);
        return aspectResize(to: size);
    }
}
