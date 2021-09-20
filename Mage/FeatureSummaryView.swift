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
    @objc public init(featureId: Int = 0, featureDetail: String? = nil, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, featureTitle: String? = nil, iconURL: URL? = nil, images: [UIImage]? = nil) {
        self.featureId = featureId
        self.featureDetail = featureDetail
        self.coordinate = coordinate
        self.featureTitle = featureTitle
        self.iconURL = iconURL
        self.images = images
    }
    
    @objc public var featureId: Int = 0;
    @objc public var featureDetail: String?;
    @objc public var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid;
    @objc public var featureTitle: String?;
    @objc public var iconURL: URL?;
    @objc public var images: [UIImage]?;
}

class FeatureSummaryView : CommonSummaryView<FeatureItem, FeatureActionsDelegate> {
    private var didSetUpConstraints = false;
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(imageOverride: UIImage? = nil) {
        super.init(imageOverride: imageOverride);
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
        secondaryField.text = item.featureDetail;
    }
}
