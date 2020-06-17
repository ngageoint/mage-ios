//
//  FeedItemHeaderCell.swift
//  MAGE
//
//  Created by Daniel Barela on 6/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher

class FeedItemHeaderCell : UITableViewCell {
    
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
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.autoSetDimension(.height, toSize: 120);
        return mapView;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(itemImage);
        self.contentView.addSubview(primaryField);
        self.contentView.addSubview(secondaryField);
        self.contentView.addSubview(mapView);
        itemImage.autoSetDimensions(to: CGSize(width: 40, height: 40));
        itemImage.autoPinEdge(toSuperviewEdge: .leading, withInset: 16);
        itemImage.autoPinEdge(toSuperviewEdge: .top, withInset: 16);
        primaryField.autoPinEdge(.bottom, to: .top, of: contentView, withOffset: 32);
        primaryField.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        primaryField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
        secondaryField.autoPinEdge(.bottom, to: .bottom, of: primaryField, withOffset: 20);
        secondaryField.autoPinEdge(.leading, to: .trailing, of: itemImage, withOffset: 16);
        secondaryField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
        mapView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0), excludingEdge: .top);
        mapView.autoPinEdge(.top, to: .bottom, of: itemImage, withOffset: 16);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func populate(feedItem: FeedItem) {
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
        primaryField.text = feedItem.primaryValue;
        secondaryField.text = feedItem.secondaryValue;
        
        self.mapView.addAnnotation(feedItem);
        self.mapView.setCenter(feedItem.coordinate, animated: true);
    }
}
