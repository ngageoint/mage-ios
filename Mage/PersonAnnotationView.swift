//
//  PersonAnnotationView.swift
//  MAGE
//
//  Created by Daniel Barela on 10/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import Kingfisher

@objc class PersonAnnotationView: MKMarkerAnnotationView {
    
    @objc public var scheme: MDCContainerScheming?
    
    static func circleWithColor(color: UIColor) -> UIImage? {
        let diameter = 10.0;
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil;
        }
        ctx.saveGState()
        
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)
        
        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img
    }
    
    static func colorForUser(user: User) -> UIColor {
        if let timestamp = user.location?.timestamp {
            let now = Date();
            if (timestamp <= Calendar.current.date(byAdding: .minute, value: -30, to: now)!) {
                return .systemOrange;
            } else if (timestamp <= Calendar.current.date(byAdding: .minute, value: -10, to: now)!) {
                return .systemYellow;
            }
        }
        return .systemBlue;
    }
    
    @objc public static func setImageForAnnotation(annotation: MKAnnotationView, user: User) {
        if let iconUrl = user.cacheIconUrl {
            KingfisherManager.shared.retrieveImage(with: URL(string: iconUrl)!, options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .transition(.fade(1)),
                .cacheOriginalImage
            ]) { result in
                switch result {
                case .success(let value):
                    if let cgImage = value.image.cgImage {
                        let scale = value.image.size.width / 37;
                        let image: UIImage = UIImage(cgImage: cgImage, scale: scale, orientation: value.image.imageOrientation)
                        annotation.image = image;
                        annotation.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
                    }
                case .failure(_):
                    if let image = UIImage(named: "me"), let cgImage = image.cgImage {
                        let scale = image.size.width / 37;
                        let image: UIImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
                        annotation.image = image;
                        annotation.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
//                        annotation.layer.anchorPoint = CGPoint(x: 0.5, y: 1);
                    }
                }
            }
        }
        
        if let circleImage = circleWithColor(color: colorForUser(user: user)) {
            let circleView = UIImageView(image: circleImage);
            annotation.addSubview(circleView);
            circleView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -5);
            circleView.autoAlignAxis(toSuperviewAxis: .vertical);
            circleView.layer.zPosition = -1.0;
        }
    }

    @objc public override func prepareForDisplay() {
        super.prepareForDisplay();
        
        if let annotation = self.annotation as? LocationAnnotation, let user = annotation.user {
            
            
            if let iconColor = user.iconColor {
                self.markerTintColor = UIColor(hex: iconColor);
                self.glyphText = user.iconText;
            } else if let iconUrl = user.cacheIconUrl {
                KingfisherManager.shared.retrieveImage(with: URL(string: iconUrl)!, options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                    switch result {
                    case .success(let value):
                        if let cgImage = value.image.cgImage {
                            let scale = value.image.size.width / 37;
                            let image: UIImage = UIImage(cgImage: cgImage, scale: scale, orientation: value.image.imageOrientation)
                            self.image = image;
                            self.glyphTintColor = .clear;
                            self.markerTintColor = .clear;
                        } else {
                            self.glyphImage = UIImage(named: "me")
                            self.markerTintColor = self.scheme?.colorScheme.primaryColor;
                        }
                    case .failure(_):
                        self.glyphImage = UIImage(named: "me")
                        self.markerTintColor = self.scheme?.colorScheme.primaryColor;
                    }
                }
            } else {
                self.glyphImage = UIImage(named: "me")
                self.markerTintColor = scheme?.colorScheme.primaryColor;
            }
            
            if let circleImage = PersonAnnotationView.circleWithColor(color: PersonAnnotationView.colorForUser(user: user)) {
                let circleView = UIImageView(image: circleImage);
                self.addSubview(circleView);
                circleView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -5);
                circleView.autoAlignAxis(toSuperviewAxis: .vertical);
                circleView.layer.zPosition = -1.0;
            }
        } else {
        
            self.image = UIImage(named: "people")
        }
    }
}
