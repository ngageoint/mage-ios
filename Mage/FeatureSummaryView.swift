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
    var featureDetail: String?;
    var coordinate: CLLocationCoordinate2D?;
    var featureTitle: String?;
    var iconURL: URL?;
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
