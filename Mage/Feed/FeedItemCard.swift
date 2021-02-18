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

class FeedItemCard : UITableViewCell {
    
    private lazy var content: UIStackView = {
        let content = UIStackView(forAutoLayout: ());
        content.axis = .vertical
        content.alignment = .fill
        content.distribution = .fill
        content.spacing = 0
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        content.isLayoutMarginsRelativeArrangement = true;
        content.translatesAutoresizingMaskIntoConstraints = false;
        
        content.addArrangedSubview(header);
        content.addArrangedSubview(mapView);
        content.addArrangedSubview(locationTextView);
        
        return content;
    }()
    
    private lazy var header: UIView = {
        let content = UIStackView(forAutoLayout: ());
        content.axis = .horizontal
        content.spacing = 0
        content.alignment = .top
        content.distribution = .fill
        content.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        content.isLayoutMarginsRelativeArrangement = true
        content.translatesAutoresizingMaskIntoConstraints = false
        
        let header = UIStackView(forAutoLayout: ());
        header.axis = .vertical
        header.spacing = 0
        header.alignment = .leading
        header.distribution = .fill
        header.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        header.isLayoutMarginsRelativeArrangement = true
        header.translatesAutoresizingMaskIntoConstraints = false
        
        header.addArrangedSubview(overline);
        header.addArrangedSubview(properties);
        
        content.addArrangedSubview(header)
        content.addArrangedSubview(iconStack)
        
        return content
    }()
    
    private lazy var overline: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.addArrangedSubview(timestamp);

        return stack;
    }()
    
    private lazy var properties: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.addArrangedSubview(primaryField);
        stack.addArrangedSubview(secondaryField);

        return stack;
    }()
    
    private lazy var iconStack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(icon);

        return stack;
    }()

    private lazy var icon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 72, height: 72))
        imageView.contentMode = .scaleAspectFit;
        imageView.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0);
        imageView.kf.indicatorType = .activity

        imageView.autoSetDimensions(to: CGSize(width: 72, height: 72))

        return imageView
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
    
    private lazy var primaryField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        primaryField.font = UIFont.systemFont(ofSize: 24.0, weight: .regular);
        primaryField.textColor = UIColor.black.withAlphaComponent(0.87);
        return primaryField;
    }()
    
    private lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.font = UIFont.systemFont(ofSize: 14.0, weight: .regular);
        secondaryField.textColor = UIColor.black.withAlphaComponent(0.60);
        secondaryField.numberOfLines = 3;
        return secondaryField;
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(content);
        content.autoPinEdgesToSuperviewEdges();
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        self.backgroundColor = scheme?.colorScheme.surfaceColor;
        self.timestamp.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        self.primaryField.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        self.secondaryField.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        self.locationLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        self.locationIcon.tintColor = scheme?.colorScheme.primaryColor;
    }
    
    func bind(feedItem: FeedItem) {
        header.isHidden = true
        if (!isEmpty(feedItem: feedItem)) {
            header.isHidden = false
            
            iconStack.isHidden = true
            if (!isMappable(feedItem: feedItem)) {
                iconStack.isHidden = false
                
                let processor = DownsamplingImageProcessor(size: CGSize(width: 36, height: 36))
                let imageModifier = AlignmentRectInsetsImageModifier(alignmentInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
                icon.kf.setImage(
                    with: feedItem.feed?.iconURL(),
                    placeholder: UIImage(named: "observations"),
                    options: [
                        .imageModifier(imageModifier),
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ]) { result in

                    switch result {
                    case .success(_):
                        self.setNeedsLayout()
                    case .failure(let error):
                        print("Job failed: \(error.localizedDescription)")
                    }
                }
            }
            
            properties.isHidden = feedItem.primaryValue == nil && feedItem.secondaryValue == nil
            primaryField.text = feedItem.primaryValue;
            secondaryField.text = feedItem.secondaryValue;
            
            overline.isHidden = true
            if (feedItem.feed?.itemTemporalProperty != nil) {
                overline.isHidden = false
                
                if let itemDate: NSDate = feedItem.timestamp as NSDate? {
                    timestamp.text = itemDate.formattedDisplay();
                } else {
                    timestamp.text = " ";
                }
            }
        }
        
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
        return CoordinateDisplay.displayFromCoordinate(coordinate: feedItem.coordinate);
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
