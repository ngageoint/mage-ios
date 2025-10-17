//
//  LatitudeLongitudeButton.swift
//  MAGE
//
//  Created by Daniel Barela on 4/11/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreLocation

class LatitudeLongitudeButton : MDCButton {
    var _coordinate: CLLocationCoordinate2D?
    
    var coordinate: CLLocationCoordinate2D? {
        get {
            return _coordinate
        }
        set {
            _coordinate = newValue
            if let coordinate = _coordinate, CLLocationCoordinate2DIsValid(coordinate) {
                setTitle(coordinate.toDisplay(short: true), for: .normal)
                isHidden = false
            } else {
                isHidden = true
                setTitle("", for: .normal)
            }
        }
    }

    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
            }
        super.applyTextTheme(withScheme: scheme)
        setTitleColor(scheme.colorScheme.primaryColorVariant.withAlphaComponent(0.87), for: .normal)
        setImageTintColor(scheme.colorScheme.primaryColorVariant.withAlphaComponent(0.87), for: .normal)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        accessibilityLabel = "location";
        setImage(UIImage(named: "location_tracking_on")?.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate), for: .normal);
        var contentInsets = defaultContentEdgeInsets
        contentInsets.left = 0
        setInsets(forContentPadding: contentInsets, imageTitlePadding: 5);
        addTarget(self, action: #selector(copyLocation), for: .touchUpInside);
        accessibilityLabel = "location button"
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.lineBreakMode = .byClipping
        titleLabel?.numberOfLines = 1
    }
    
    @objc func copyLocation() {
        UIPasteboard.general.string = currentTitle ?? "No Location";
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(currentTitle ?? "No Location") copied to clipboard"))
    }
}
