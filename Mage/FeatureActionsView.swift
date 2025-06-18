//
//  FeatureActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Updated by Brent Michalski on 6/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import PureLayout
import CoreLocation
import MapKit

class FeatureActionsView: UIView {
    var didSetupConstraints = false
    var location: CLLocationCoordinate2D?
    var title: String?
    var featureItem: FeatureItem?
    var geoPackageFeatureItem: GeoPackageFeatureItem?
    var featureActionsDelegate: FeatureActionsDelegate?
    var scheme: AppContainerScheming?

    private lazy var actionButtonView: UIStackView = {
        let stack = UIStackView.newAutoLayout()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 24
        stack.distribution = .fill
        stack.addArrangedSubview(directionsButton)
        return stack
    }()

    lazy var latitudeLongitudeButton: LatitudeLongitudeButton = LatitudeLongitudeButton()

    private lazy var directionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "directions"
        let image = UIImage(systemName: "arrow.triangle.turn.up.right.diamond")?
            .resized(to: CGSize(width: 24, height: 24))
            .withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        button.addTarget(self, action: #selector(getDirectionsToFeature), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializers

    public convenience init(
        geoPackageFeatureItem: GeoPackageFeatureItem?,
        featureActionsDelegate: FeatureActionsDelegate?,
        scheme: AppContainerScheming?
    ) {
        self.init(frame: .zero)
        self.scheme = scheme
        self.geoPackageFeatureItem = geoPackageFeatureItem
        self.location = geoPackageFeatureItem?.coordinate
        self.featureActionsDelegate = featureActionsDelegate
        configureLayout()
        populate(location: location, title: title, delegate: featureActionsDelegate)
        applyTheme(withScheme: scheme)
    }

    public convenience init(
        featureItem: FeatureItem?,
        featureActionsDelegate: FeatureActionsDelegate?,
        scheme: AppContainerScheming?
    ) {
        self.init(frame: .zero)
        self.scheme = scheme
        self.featureItem = featureItem
        self.location = featureItem?.coordinate
        self.title = featureItem?.featureTitle
        self.featureActionsDelegate = featureActionsDelegate
        configureLayout()
        populate(location: location, title: title, delegate: featureActionsDelegate)
        applyTheme(withScheme: scheme)
    }

    // MARK: - Layout

    func configureLayout() {
        addSubview(latitudeLongitudeButton)
        addSubview(actionButtonView)
    }

    override func updateConstraints() {
        if !didSetupConstraints {
            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left)
            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal)
            actionButtonView.autoSetDimension(.height, toSize: 56)
            actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16), excludingEdge: .left)
            didSetupConstraints = true
        }
        super.updateConstraints()
    }

    // MARK: - Theming

    func applyTheme(withScheme scheme: AppContainerScheming?) {
        self.scheme = scheme
        directionsButton.tintColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        latitudeLongitudeButton.applyTheme(withScheme: scheme)
    }

    // MARK: - Content

    public func populate(location: CLLocationCoordinate2D? = kCLLocationCoordinate2DInvalid, title: String?, delegate: FeatureActionsDelegate?) {
        self.location = location
        self.title = title
        self.featureActionsDelegate = delegate
        latitudeLongitudeButton.coordinate = location
        applyTheme(withScheme: scheme)
    }

    // MARK: - Actions

    @objc func getDirectionsToFeature(_ sender: UIButton) {
        guard let location = self.location else { return }

        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)

        var notification = DirectionsToItemNotification(dataSource: DataSources.featureItem, includeCopy: false)
        notification.imageUrl = featureItem?.iconURL
        notification.location = CLLocation(latitude: location.latitude, longitude: location.longitude)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
}
