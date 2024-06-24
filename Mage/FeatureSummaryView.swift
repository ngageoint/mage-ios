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

class FeatureItem: NSObject, Codable {
    
    init(annotation: StaticPointAnnotation) {
        self.featureDetail = StaticLayer.featureDescription(feature: annotation.feature)
        self.coordinate = annotation.coordinate
        self.featureTitle = StaticLayer.featureName(feature: annotation.feature)
        self.featureDate = StaticLayer.featureTimestamp(feature: annotation.feature)
        self.layerName = annotation.layerName
        if let iconUrl = annotation.iconUrl {
            if iconUrl.hasPrefix("http") {
                self.iconURL = URL(string: iconUrl)
            } else {
                self.iconURL = URL(fileURLWithPath: "\(FeatureItem.getDocumentsDirectory())/\(iconUrl)")
            }
        }
    }
    
    init(featureId: Int = 0, featureDetail: String? = nil, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, featureTitle: String? = nil, layerName: String? = nil, iconURL: URL? = nil) {
        self.featureId = featureId
        self.featureDetail = featureDetail
        self.coordinate = coordinate
        self.featureTitle = featureTitle
        self.iconURL = iconURL
        self.layerName = layerName;
    }
    
    var featureId: Int = 0;
    var featureDetail: String?;
    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid;
    var featureTitle: String?;
    var iconURL: URL?;
    var layerName: String?
    var featureDate: Date?
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
    @objc public func toKey() -> String {
        let jsonEncoder = JSONEncoder()
        if let jsonData = try? jsonEncoder.encode(self) {
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        }
        return ""
    }
    
    static func fromKey(jsonString: String) -> FeatureItem? {
        if let jsonData = jsonString.data(using: .utf8) {
            let jsonDecoder = JSONDecoder()
            return try? jsonDecoder.decode(FeatureItem.self, from: jsonData)
        }
        return nil
    }
}

class FeatureSummaryView : CommonSummaryView<FeatureItem, FeatureActionsDelegate> {
    private var didSetUpConstraints = false;
    
    private lazy var secondaryLabelIcon: UIImageView = {
        let secondaryLabelIcon = UIImageView(image: UIImage(systemName: "square.stack.3d.up"));
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
    
    override func populate(item: FeatureItem, actionsDelegate: FeatureActionsDelegate? = nil) {
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
        if let featureDate: NSDate = item.featureDate as NSDate? {
            timestamp.text = featureDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}")
        }
        secondaryField.text = item.layerName;
        if (secondaryLabelIcon.superview == nil) {
            secondaryContainer.insertArrangedSubview(secondaryLabelIcon, at: 0);
        }
//        secondaryField.text = item.featureDetail;
    }
}
