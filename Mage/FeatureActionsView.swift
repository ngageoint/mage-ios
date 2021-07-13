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

class FeatureActionsView: UIView {
    var didSetupConstraints = false;
    var location: CLLocationCoordinate2D?;
    var title: String?;
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
    
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        directionsButton.applyTextTheme(withScheme: scheme);
        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
    }
    
    public convenience init(location: CLLocationCoordinate2D?, title: String?, featureActionsDelegate: FeatureActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.location = location;
        self.title = title;
        self.featureActionsDelegate = featureActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        populate(location: location, title: title, delegate: featureActionsDelegate);
        if let safeScheme = self.scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    func layoutView() {
        self.addSubview(actionButtonView);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            actionButtonView.autoSetDimension(.height, toSize: 56);
            actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16), excludingEdge: .left);
            
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(location: CLLocationCoordinate2D?, title: String?, delegate: FeatureActionsDelegate?) {
        self.location = location;
        self.title = title;
        self.featureActionsDelegate = delegate;
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    @objc func getDirectionsToFeature() {
        guard let location = self.location else {
            return;
        }
        featureActionsDelegate?.getDirectionsToLocation?(location, title: title);
    }
}
