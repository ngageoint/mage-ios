//
//  GeoPackageFeatureSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher

class GeoPackageFeatureSummaryView : CommonSummaryView<GeoPackageFeatureItem, FeatureActionsDelegate> {
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
    
    override init(imageOverride: UIImage? = nil) {
        super.init(imageOverride: imageOverride);
        isUserInteractionEnabled = false;
    }
    
    @objc public override func populate(item: GeoPackageFeatureItem, actionsDelegate: FeatureActionsDelegate? = nil) {
        let image = UIImage(named: "observations");
        if let icon = item.icon {
            itemImage.image = icon;
        } else {
            if item.style?.hasColor() != nil, let color = item.style?.color() {
                itemImage.tintColor = UIColor(red: CGFloat(color.redArithmetic), green: CGFloat(color.greenArithmetic), blue: CGFloat(color.blueArithmetic), alpha: CGFloat(color.alphaArithmetic()));
            } else {
                itemImage.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0);
            }
            
            itemImage.image = image;
        }
        
        primaryField.text = createTitle(item: item)
        if let date = getDate(item: item) {
            timestamp.text = (date as NSDate).formattedDisplay()
            timestamp.isHidden = false;
        } else {
            timestamp.isHidden = true;
        }
        
        secondaryField.text = item.layerName;
        if (secondaryLabelIcon.superview == nil) {
            secondaryContainer.insertArrangedSubview(secondaryLabelIcon, at: 0);
        }
    }
    
    func getDate(item: GeoPackageFeatureItem) -> Date? {
        if let values = item.featureRowData?.values(), let titleKey = values.keys.first(where: { key in
            return ["date", "timestamp"].contains((key as? String)?.lowercased());
        }) {
            return values[titleKey] as? Date;
        }
        return nil;
    }
    
    func createTitle(item: GeoPackageFeatureItem) -> String {
        let title = "GeoPackage Feature";
        if let values = item.featureRowData?.values(), let titleKey = values.keys.first(where: { key in
            return ["name", "title"].contains((key as? String)?.lowercased());
        }) {
            return values[titleKey] as? String ?? title;
        }
        return title;
    }
}

