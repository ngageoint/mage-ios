//
//  FeedItemActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
//import MaterialComponents.MDCPalettes

class FeedItemActionsView: UIView {
    var didSetupConstraints = false
    var feedItem: FeedItem?
    var actionsDelegate: FeedItemActionsDelegate?
    var bottomSheet: UIViewController? // MDCBottomSheetController?
    var scheme: AppContainerScheming?
    
    private lazy var actionButtonView: UIStackView = {
        let stack = UIStackView.newAutoLayout()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 24
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(directionsButton)
        return stack
    }()
    
    lazy var latitudeLongitudeButton: LatitudeLongitudeButton = LatitudeLongitudeButton()
    
    private lazy var directionsButton: UIButton = {
        let directionsButton = UIButton()
        directionsButton.accessibilityLabel = "directions"
        directionsButton.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal)
        directionsButton.addTarget(self, action: #selector(getDirectionsToFeature), for: .touchUpInside)
        directionsButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0)
//        directionsButton.inkMaxRippleRadius = 30
//        directionsButton.inkStyle = .unbounded
        return directionsButton
    }()
    
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme
//        directionsButton.applyTextTheme(withScheme: scheme)
//        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        latitudeLongitudeButton.applyTheme(withScheme: scheme)
    }
    
    public convenience init(feedItem: FeedItem?, actionsDelegate: FeedItemActionsDelegate?, scheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.scheme = scheme
        self.feedItem = feedItem
        self.actionsDelegate = actionsDelegate
        self.configureForAutoLayout()
        layoutView()
        populate(feedItem: feedItem, delegate: actionsDelegate)
        applyTheme(withScheme: scheme)
    }
    
    func layoutView() {
        self.addSubview(latitudeLongitudeButton)
        self.addSubview(actionButtonView)
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            actionButtonView.autoSetDimension(.height, toSize: 56)
            actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16), excludingEdge: .left)
            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal)
            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    public func populate(feedItem: FeedItem?, delegate: FeedItemActionsDelegate?) {
        self.feedItem = feedItem
        self.actionsDelegate = delegate
        
        latitudeLongitudeButton.coordinate = self.feedItem?.coordinate
        
        applyTheme(withScheme: scheme)
    }
    
    @objc func getDirectionsToFeature(_ sender: UIButton) {
        guard let feedItem = self.feedItem else {
            return
        }
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
        // let the bottom sheet dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notification = DirectionsToItemNotification(itemKey: feedItem.objectID.uriRepresentation().absoluteString, dataSource: DataSources.feedItem, includeCopy: false)
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
}
