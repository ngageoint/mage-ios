//
//  FeatureActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import MaterialComponents.MDCPalettes
import CoreLocation
import UIKit

class FeatureActionsView: UIView {
    var didSetupConstraints = false;
    var location: CLLocationCoordinate2D?;
    var title: String?;
    var featureItem: FeatureItem?
    var geoPackageFeatureItem: GeoPackageFeatureItem?
    var featureActionsDelegate: FeatureActionsDelegate?;
    var bottomSheet: MDCBottomSheetController?;
    internal var scheme: MDCContainerScheming?;
    
    private lazy var actionButtonView: UIStackView = {
        let stack = UIStackView.newAutoLayout()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 24
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(directionsButton);
        return stack;
    }()
    
    private lazy var latitudeLongitudeButton: MDCButton = {
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = "location";
        button.setImage(UIImage(named: "location_tracking_on")?.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5);
        button.addTarget(self, action: #selector(copyLocation), for: .touchUpInside);
        return button;
    }()
    
    private lazy var directionsButton: MDCButton = {
        let directionsButton = MDCButton();
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(named: "directions_large")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToFeature), for: .touchUpInside);
        directionsButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        directionsButton.inkMaxRippleRadius = 30;
        directionsButton.inkStyle = .unbounded;
        return directionsButton;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        directionsButton.applyTextTheme(withScheme: scheme);
        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        latitudeLongitudeButton.applyTextTheme(withScheme: scheme);
        latitudeLongitudeButton.setTitleColor(scheme.colorScheme.primaryColorVariant.withAlphaComponent(0.87), for: .normal)
        latitudeLongitudeButton.setImageTintColor(scheme.colorScheme.primaryColorVariant.withAlphaComponent(0.87), for: .normal)
    }
    
    public convenience init(geoPackageFeatureItem: GeoPackageFeatureItem?, featureActionsDelegate: FeatureActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.geoPackageFeatureItem = geoPackageFeatureItem
        self.location = featureItem?.coordinate
        self.featureActionsDelegate = featureActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        populate(location: location, title: title, delegate: featureActionsDelegate);
        applyTheme(withScheme: scheme);
    }
    
    
    public convenience init(featureItem: FeatureItem?, featureActionsDelegate: FeatureActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.featureItem = featureItem
        self.location = featureItem?.coordinate
        self.title = featureItem?.featureTitle;
        self.featureActionsDelegate = featureActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        populate(location: location, title: title, delegate: featureActionsDelegate);
        applyTheme(withScheme: scheme);
    }
    
    func layoutView() {
        self.addSubview(latitudeLongitudeButton);
        self.addSubview(actionButtonView);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left);
            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal);
            actionButtonView.autoSetDimension(.height, toSize: 56);
            actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16), excludingEdge: .left);
            
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(location: CLLocationCoordinate2D? = kCLLocationCoordinate2DInvalid, title: String?, delegate: FeatureActionsDelegate?) {
        self.location = location;
        self.title = title;
        self.featureActionsDelegate = delegate;
        
        if let location = location, CLLocationCoordinate2DIsValid(location) {
            latitudeLongitudeButton.setTitle(location.toDisplay(short: true), for: .normal)
            latitudeLongitudeButton.isEnabled = true;
            latitudeLongitudeButton.isHidden = false;
        } else {
            latitudeLongitudeButton.isHidden = true;
        }
        
        applyTheme(withScheme: scheme);
    }
    
    @objc func getDirectionsToFeature(_ sender: UIButton) {
        guard let location = self.location else {
            return;
        }
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
        // let the bottom sheet dismiss
        var notification = DirectionsToItemNotification()
        notification.imageUrl = featureItem?.iconURL
        notification.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
    
    @objc func copyLocation() {
        UIPasteboard.general.string = latitudeLongitudeButton.currentTitle ?? "No Location";
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(latitudeLongitudeButton.currentTitle ?? "No Location") copied to clipboard"))
    }
}
