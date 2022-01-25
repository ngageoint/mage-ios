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

class FeedItemCard : MDCCard {
    private var feedItem: FeedItem?;
    private var actionsDelegate: FeedItemActionsDelegate?;
    private var scheme: MDCContainerScheming?;
    private var hideSummaryImage: Bool = false;
    
    private lazy var feedItemView: FeedItemSummary = {
        let view = FeedItemSummary(imageOverride: nil, hideImage: hideSummaryImage);
        return view;
    }()
    
    private lazy var actionsView: FeedItemActionsView = {
        let view = FeedItemActionsView(feedItem: feedItem, actionsDelegate: actionsDelegate, scheme: scheme)
        return view;
    }()
    
    private lazy var content: UIStackView = {
        let content = UIStackView(forAutoLayout: ());
        content.axis = .vertical
        content.alignment = .fill
        content.distribution = .fill
        content.spacing = 0
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        content.isLayoutMarginsRelativeArrangement = true;
        content.translatesAutoresizingMaskIntoConstraints = false;
        
        content.addArrangedSubview(feedItemView);
        content.addArrangedSubview(mapView);
        content.addArrangedSubview(actionsView);
        
        return content;
    }()

    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.autoSetDimension(.height, toSize: 160);
        mapView.delegate = self;
        return mapView;
    }()
    
    private lazy var locationIcon: UIImageView = {
        let image = UIImageView(image: UIImage(named: "location_tracking_on"))
        return image
    }()
    
    private lazy var locationTextView: UIView = {
        let view = UIView(forAutoLayout: ())
        view.addSubview(locationIcon);
        view.addSubview(locationLabel);
        
        locationIcon.autoSetDimensions(to: CGSize(width: 24, height: 24));
        locationIcon.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
        
        locationLabel.autoAlignAxis(.horizontal, toSameAxisOf: locationIcon);
        locationLabel.autoPinEdge(.left, to: .right, of: locationIcon, withOffset: 16);
        locationLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        return view;
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .regular);
        label.textColor = UIColor.black.withAlphaComponent(0.87);
        return label;
    }()
    
    public convenience init(item: FeedItem?, actionsDelegate: FeedItemActionsDelegate?, hideSummaryImage: Bool = false) {
        self.init(frame: CGRect.zero)
        self.configureForAutoLayout();
        self.feedItem = item;
        self.actionsDelegate = actionsDelegate;
        self.hideSummaryImage = hideSummaryImage;
        self.addSubview(content);
        content.autoPinEdgesToSuperviewEdges();
        bind(feedItem: item, actionsDelegate: actionsDelegate)
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        feedItemView.applyTheme(withScheme: scheme);
        actionsView.applyTheme(withScheme: scheme);
        self.locationLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        self.locationIcon.tintColor = scheme.colorScheme.primaryColor;
    }
    
    func bind(feedItem: FeedItem?, actionsDelegate: FeedItemActionsDelegate?) {
        guard let feedItem = feedItem else {
            return
        }

        self.feedItem = feedItem;
        self.actionsDelegate = actionsDelegate;
        feedItemView.populate(item: feedItem, actionsDelegate: actionsDelegate);
        actionsView.populate(feedItem: feedItem, delegate: actionsDelegate);
        if (isMappable(feedItem: feedItem)) {
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
    
    private func isEmpty(feedItem: FeedItem) -> Bool {
        if (feedItem.feed?.itemTemporalProperty != nil) {
            return false;
        }
        
        if (feedItem.primaryValue != nil) {
            return false;
        }
        
        if (feedItem.secondaryValue != nil) {
            return false;
        }

        return true
    }
    
    private func isMappable(feedItem: FeedItem) -> Bool {
        return feedItem.isMappable && feedItem.feed?.itemsHaveSpatialDimension ?? true
    }
    
    func getLocationText(feedItem: FeedItem) -> String {
        return feedItem.coordinate.toDisplay()
    }
}

extension FeedItemCard : MKMapViewDelegate {
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
