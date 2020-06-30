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
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(itemInfoView);
        stack.addArrangedSubview(mapView);
        stack.addArrangedSubview(locationTextView);
        return stack;
    }()
    
    private lazy var itemInfoView: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(itemImage);
        view.addSubview(primaryField);
        view.addSubview(secondaryField);
        
        // do this to stop the automatically created constraint from throwing errors
        NSLayoutConstraint.autoSetPriority(.defaultHigh) {
            itemImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
        };
        itemImage.autoSetDimensions(to: CGSize(width: 40, height: 40));
        primaryField.autoPinEdge(.bottom, to: .top, of: view, withOffset: 32);
        primaryField.autoPinEdge(.left, to: .right, of: itemImage, withOffset: 16);
        primaryField.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        secondaryField.autoPinEdge(.bottom, to: .bottom, of: primaryField, withOffset: 20);
        secondaryField.autoPinEdge(.left, to: .right, of: itemImage, withOffset: 16);
        secondaryField.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        return view;
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
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.autoSetDimension(.height, toSize: 120);
        return mapView;
    }()
    
    private lazy var locationTextView: UIView = {
        let view = UIView(forAutoLayout: ());
        let image = UIImageView(image: UIImage(named: "location_tracking_on"));
        image.autoSetDimensions(to: CGSize(width: 24, height: 24));
        image.tintColor = UIColor.mageBlue();
        view.addSubview(image);
        view.addSubview(locationLabel);
        image.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
        locationLabel.autoAlignAxis(.horizontal, toSameAxisOf: image);
        locationLabel.autoPinEdge(.left, to: .right, of: image, withOffset: 16);
        locationLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        return view;
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .regular);
        label.textColor = UIColor.black.withAlphaComponent(0.87);
        return label;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(stack);
        stack.autoPinEdgesToSuperviewEdges();
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
        if (feedItem.primaryValue != nil || feedItem.secondaryValue != nil) {
            primaryField.text = feedItem.primaryValue;
            secondaryField.text = feedItem.secondaryValue;
            itemInfoView.isHidden = false;
        } else {
            itemInfoView.isHidden = true;
        }
        if (feedItem.isMappable) {
            self.mapView.isHidden = false;
            self.locationTextView.isHidden = false;
            self.mapView.addAnnotation(feedItem);
            self.mapView.setCenter(feedItem.coordinate, animated: true);
            self.locationLabel.text = getLocationText(feedItem: feedItem);
        } else {
            self.mapView.isHidden = true;
            self.locationTextView.isHidden = true;
        }
    }
    
    func getLocationText(feedItem: FeedItem) -> String {
        if (UserDefaults.standard.bool(forKey: "showMGRS")) {
            return MGRS.mgrSfromCoordinate(feedItem.coordinate);
        } else {
            return String(format: "%.05f, %.05f", feedItem.coordinate.latitude, feedItem.coordinate.longitude);
        }
    }
}
