//
//  FeedItemPropertyCell.swift
//  MAGE
//
//  Created by Daniel Barela on 6/15/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout

class FeedItemPropertyCell : UITableViewCell {

    public lazy var keyField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        let systemFont = UIFont.systemFont(ofSize: 12.0, weight: .light)
        let smallCapsDesc = systemFont.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
        let font = UIFont(descriptor: smallCapsDesc, size: systemFont.pointSize)
        primaryField.font = font;
        return primaryField;
    }()
    
    public lazy var valueField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.numberOfLines = 10;
        secondaryField.lineBreakMode = .byWordWrapping;
        secondaryField.font = UIFont.systemFont(ofSize: 16.0, weight: .regular);
        secondaryField.textColor = UIColor.black.withAlphaComponent(0.87);
        return secondaryField;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(keyField);
        self.contentView.addSubview(valueField);
        
        keyField.autoPinEdge(.bottom, to: .top, of: contentView, withOffset: 32);
        keyField.autoPinEdge(toSuperviewEdge: .leading, withInset: 16);
        keyField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);

        valueField.autoPinEdge(.top, to: .bottom, of: keyField, withOffset: 8);
        valueField.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16), excludingEdge: .top);
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
