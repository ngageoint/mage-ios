//
//  FeedItemSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 6/29/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher

class FeedItemSummaryView : UIView {
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        return formatter;
    }()
    
    private lazy var timestamp: UILabel = {
        let timestamp = UILabel(forAutoLayout: ());
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
        timestamp.font = font;
        return timestamp;
    }()
    
    private lazy var itemImage: UIImageView = {
        let itemImage = UIImageView(forAutoLayout: ());
        itemImage.contentMode = .scaleAspectFit;
        return itemImage;
    }()
    
    private lazy var primaryField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        primaryField.font = UIFont.systemFont(ofSize: 16.0, weight: .regular);
        primaryField.textColor = UIColor.black.withAlphaComponent(0.87);
        return primaryField;
    }()
    
    private lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.font = UIFont.systemFont(ofSize: 14.0, weight: .regular);
        secondaryField.textColor = UIColor.black.withAlphaComponent(0.60);
        return secondaryField;
    }()
    
    private lazy var noContentView: UIView = {
        let view = UIView(forAutoLayout: ());
        let label = UILabel(forAutoLayout: ());
        label.text = "No Content";
        label.font = UIFont.systemFont(ofSize: 32, weight: .regular);
        label.textColor = UIColor.black.withAlphaComponent(0.60);
        view.addSubview(label);
        label.autoCenterInSuperview();
        return view;
    }()
    
    @objc public convenience init(temporal: Bool) {
        self.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        if (temporal) {
            layoutTemporalView();
        } else {
            layoutView();
        }
    }
    
    @objc public func populate(feedItem: FeedItem) {
        let processor = DownsamplingImageProcessor(size: CGSize(width: 40, height: 40))
        itemImage.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0);
        let image = UIImage(named: "observations");
        let iconUrl = feedItem.iconURL;
        itemImage.kf.indicatorType = .activity
        itemImage.kf.setImage(
            with: iconUrl,
            placeholder: image,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            
            switch result {
            case .success(let value):
                self.setNeedsLayout()
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
        
        if (!feedItem.hasContent()) {
            noContentView.isHidden = false;
            return;
        }
        noContentView.isHidden = true;
        primaryField.text = feedItem.primaryValue;
        secondaryField.text = feedItem.secondaryValue;
        if let itemDate = feedItem.timestamp {
            timestamp.text = formatter.string(from: itemDate);
        } else {
            timestamp.text = nil;
        }
    }
    
    func layoutView() {
        self.addSubview(itemImage);
        self.addSubview(primaryField);
        self.addSubview(secondaryField);
        self.addSubview(noContentView);
        noContentView.autoPinEdgesToSuperviewEdges();
        NSLayoutConstraint.autoSetPriority(.defaultHigh) {
            itemImage.autoSetDimensions(to: CGSize(width: 40, height: 40));
            itemImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
        }
        primaryField.autoPinEdge(.top, to: .top, of: self, withOffset: 16);
        primaryField.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        primaryField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
        secondaryField.autoPinEdge(.top, to: .bottom, of: primaryField);
        secondaryField.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        secondaryField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
    }
    
    func layoutTemporalView() {
        self.addSubview(itemImage);
        self.addSubview(timestamp);
        self.addSubview(primaryField);
        self.addSubview(secondaryField);
        self.addSubview(noContentView);
        noContentView.autoPinEdgesToSuperviewEdges();
        // do this to stop the automatically created constraint from throwing errors
        NSLayoutConstraint.autoSetPriority(.defaultHigh) {
            itemImage.autoSetDimensions(to: CGSize(width: 40, height: 40));
            itemImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 0), excludingEdge: .right);
        };
        timestamp.autoPinEdge(.top, to: .top, of: self, withOffset: 16);
        timestamp.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        timestamp.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
        primaryField.autoPinEdge(.top, to: .bottom, of: timestamp);
        primaryField.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        primaryField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
        secondaryField.autoPinEdge(.top, to: .bottom, of: primaryField);
        secondaryField.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        secondaryField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
    }
}
