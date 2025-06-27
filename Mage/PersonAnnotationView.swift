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
    
    @objc override var annotation: MKAnnotation? {
        didSet {
            if let annotation = self.annotation as? LocationAnnotation, let user = annotation.user {
                
                if let iconColor = user.iconColor {
                    self.markerTintColor = UIColor(hex: iconColor)
                    self.glyphText = user.iconText
                } else {
                    self.glyphImage = UIImage(systemName: "person.fill")
                    self.markerTintColor = scheme?.colorScheme.primaryColorVariant
                }
                
                for subview in subviews {
                    if subview.accessibilityLabel == "circle" {
                        subview.removeFromSuperview()
                    }
                }
                
                if let circleImage = PersonAnnotationView.circleWithColor(color: PersonAnnotationView.colorForUser(user: user)) {
                    let circleView = UIImageView(image: circleImage)
                    self.addSubview(circleView)
                    circleView.accessibilityLabel = "circle"
                    circleView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -5)
                    circleView.autoAlignAxis(toSuperviewAxis: .vertical)
                    circleView.layer.zPosition = -1.0
                }
            } else {
                self.glyphImage = UIImage(systemName: "person.fill")
                self.markerTintColor = scheme?.colorScheme.primaryColorVariant
            }
        }
    }
    
    @objc public var scheme: AppContainerScheming?
    
    static func circleWithColor(color: UIColor) -> UIImage? {
        let diameter = 10.0
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil
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
            let now = Date()
            if (timestamp <= Calendar.current.date(byAdding: .minute, value: -30, to: now)!) {
                return .systemOrange
            } else if (timestamp <= Calendar.current.date(byAdding: .minute, value: -10, to: now)!) {
                return .systemYellow
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
                        let scale = Float(cgImage.width) / 37.0
                        let image: UIImage = UIImage(cgImage: cgImage, scale: CGFloat(scale), orientation: value.image.imageOrientation)
                        annotation.image = image;
                        annotation.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
                    }
                case .failure(_):
                    if let image = UIImage(systemName: "person.fill"), let cgImage = image.cgImage {
                        let scale = Float(cgImage.width) / 37.0
                        let image: UIImage = UIImage(cgImage: cgImage, scale: CGFloat(scale), orientation: image.imageOrientation)
                        annotation.image = image
                        annotation.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
                    }
                }
            }
        }
        
        if let circleImage = circleWithColor(color: colorForUser(user: user)) {
            let circleView = UIImageView(image: circleImage)
            annotation.addSubview(circleView)
            circleView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -5)
            circleView.autoAlignAxis(toSuperviewAxis: .vertical)
            circleView.layer.zPosition = -1.0
        }
    }

    @objc public override func prepareForDisplay() {
        super.prepareForDisplay();
        
        if let annotation = self.annotation as? LocationAnnotation, let user = annotation.user {
            if let iconColor = user.iconColor {
                self.markerTintColor = UIColor(hex: iconColor)
                self.glyphText = user.iconText
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
                            self.glyphText = nil
                            let scale = Float(cgImage.width) / 37.0
                            let image: UIImage = UIImage(cgImage: cgImage, scale: CGFloat(scale), orientation: value.image.imageOrientation)
                            self.image = image
                            self.glyphTintColor = .clear
                            self.markerTintColor = .clear
                        } else if let iconColor = user.iconColor {
                            self.markerTintColor = UIColor(hex: iconColor)
                            self.glyphText = user.iconText
                        } else {
                            self.glyphText = nil
                            self.glyphImage = UIImage(systemName: "person.fill")
                            self.markerTintColor = self.scheme?.colorScheme.primaryColorVariant
                        }
                    case .failure(_):
                        if let iconColor = user.iconColor {
                            self.markerTintColor = UIColor(hex: iconColor)
                            self.glyphText = user.iconText
                        } else {
                            self.glyphText = nil
                            self.glyphImage = UIImage(systemName: "person.fill")
                            self.markerTintColor = self.scheme?.colorScheme.primaryColorVariant
                        }
                    }
                }
            } else {
                self.glyphImage = UIImage(systemName: "person.fill")
                self.markerTintColor = scheme?.colorScheme.primaryColorVariant
            }
            
            for subview in subviews {
                if subview.accessibilityLabel == "circle" {
                    subview.removeFromSuperview()
                }
            }
            
            if let circleImage = PersonAnnotationView.circleWithColor(color: PersonAnnotationView.colorForUser(user: user)) {
                let circleView = UIImageView(image: circleImage)
                self.addSubview(circleView)
                circleView.accessibilityLabel = "circle"
                circleView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -5)
                circleView.autoAlignAxis(toSuperviewAxis: .vertical)
                circleView.layer.zPosition = -1.0
            }
        } else {
            self.glyphImage = UIImage(systemName: "person.fill")
            self.markerTintColor = scheme?.colorScheme.primaryColorVariant
        }
    }
}
