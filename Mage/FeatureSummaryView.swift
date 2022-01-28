//
//  FeatureSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 8/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher

@objc class FeatureItem: NSObject {
    
    @objc public init(annotation: StaticPointAnnotation) {
        self.featureDetail = (annotation.feature["properties"] as? [AnyHashable : Any])?["description"] as? String
        self.coordinate = annotation.coordinate
        self.featureTitle = (annotation.feature["properties"] as? [AnyHashable : Any])?["name"] as? String
        self.layerName = annotation.layerName
        if let iconUrl = annotation.iconUrl {
            if iconUrl.hasPrefix("http") {
                self.iconURL = URL(string: iconUrl)
            } else {
                self.iconURL = URL(fileURLWithPath: "\(FeatureItem.getDocumentsDirectory())/\(iconUrl)")
            }
        }
    }
    
    @objc public init(featureId: Int = 0, featureDetail: String? = nil, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, featureTitle: String? = nil, layerName: String? = nil, iconURL: URL? = nil, images: [UIImage]? = nil) {
        self.featureId = featureId
        self.featureDetail = featureDetail
        self.coordinate = coordinate
        self.featureTitle = featureTitle
        self.iconURL = iconURL
        self.images = images
        self.layerName = layerName;
    }
    
    @objc public var featureId: Int = 0;
    @objc public var featureDetail: String?;
    @objc public var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid;
    @objc public var featureTitle: String?;
    @objc public var iconURL: URL?;
    @objc public var images: [UIImage]?;
    @objc public var layerName: String?
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
}

class FeatureSummaryView : CommonSummaryView<FeatureItem, FeatureActionsDelegate> {
    private var didSetUpConstraints = false;
    
    private lazy var secondaryLabelIcon: UIImageView = {
        let secondaryLabelIcon = UIImageView(image: UIImage(named: "layers"));
        secondaryLabelIcon.tintColor = secondaryField.textColor
        secondaryLabelIcon.autoSetDimensions(to: CGSize(width: 14, height: 14));
        return secondaryLabelIcon;
    }();
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(imageOverride: UIImage? = nil, hideImage: Bool = false) {
        super.init(imageOverride: imageOverride, hideImage: hideImage);
        isUserInteractionEnabled = false;
    }
    
    @objc public override func populate(item: FeatureItem, actionsDelegate: FeatureActionsDelegate? = nil) {
        let processor = DownsamplingImageProcessor(size: CGSize(width: 40, height: 40))
        itemImage.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0);
        let image = UIImage(named: "observations");
        let iconUrl = item.iconURL;
        itemImage.kf.indicatorType = .activity
        itemImage.kf.setImage(
            with: iconUrl,
            placeholder: image,
            options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            
            switch result {
            case .success(_):
                self.setNeedsLayout()
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
        
        primaryField.text = item.featureTitle ?? " ";
        timestamp.isHidden = true;
        secondaryField.text = item.layerName;
        if (secondaryLabelIcon.superview == nil) {
            secondaryContainer.insertArrangedSubview(secondaryLabelIcon, at: 0);
        }
//        secondaryField.text = item.featureDetail;
    }
}
