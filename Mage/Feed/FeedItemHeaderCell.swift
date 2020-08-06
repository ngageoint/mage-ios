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
    
    private lazy var itemInfoView: FeedItemSummaryView = {
        let view = FeedItemSummaryView();
        return view;
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.autoSetDimension(.height, toSize: 120);
        mapView.delegate = self;
        return mapView;
    }()
    
    private lazy var locationTextView: UIView = {
        let view = UIView(forAutoLayout: ());
        let image = UIImageView(image: UIImage(named: "location_tracking_on"));
        image.tintColor = UIColor.mageBlue();
        view.addSubview(image);
        view.addSubview(locationLabel);
        
        image.autoSetDimensions(to: CGSize(width: 24, height: 24));
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
        itemInfoView.populate(feedItem: feedItem, showNoContent: false);
        if (feedItem.isMappable && feedItem.feed?.itemsHaveSpatialDimension == true) {
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
        return CoordinateDisplay.displayFromCoordinate(coordinate: feedItem.coordinate);
    }
}

extension FeedItemHeaderCell : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let item: FeedItem = annotation as? FeedItem {
            let annotationView: MKAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "feedItem") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "feedItem");
            annotationView.canShowCallout = false;
            FeedItemRetriever.setAnnotationImage(feedItem: item, annotationView: annotationView);
            annotationView.annotation = item;
            return annotationView;
        }
        return nil;
    }
    
}
