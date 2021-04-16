//
//  StraightLineNavigationView.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout

@objc class StraightLineNavigationView: UIView {
    var delegate: StraightLineNavigationDelegate?;
    var scheme: MDCContainerScheming?;
    var locationManager: CLLocationManager?;
    var destinationCoordinate: CLLocationCoordinate2D?;
    var destinationMarker: UIImage?;
    var targetColor: UIColor = .systemGreen;
    var bearingColor: UIColor = .systemRed;
    
    var bearingLabel: UILabel = UILabel(forAutoLayout: ());
    var speedLabel: UILabel = UILabel(forAutoLayout: ());
    var distanceToTargetLabel: UILabel = UILabel(forAutoLayout: ());
    var bearingToTargetLabel: UILabel = UILabel(forAutoLayout: ());
    var compassView: CompassView?;
    
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom);
        cancelButton.accessibilityLabel = "cancel";
        cancelButton.setImage(UIImage(named: "cancel" )?.withRenderingMode(.alwaysTemplate), for: .normal);
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        return cancelButton;
    }();
    
    private lazy var targetBearingContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(targetBearingMarkerView);
        view.addSubview(bearingToTargetLabel);
        targetBearingMarkerView.autoPinEdge(toSuperviewEdge: .left);
        bearingToTargetLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left);
        bearingToTargetLabel.autoPinEdge(.left, to: .right, of: targetBearingMarkerView, withOffset: 8);
        targetBearingMarkerView.autoAlignAxis(.horizontal, toSameAxisOf: bearingToTargetLabel);
        return view;
    }();
    
    private lazy var bearingContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(bearingLabel);
        view.addSubview(targetBearingContainer);
        targetBearingContainer.autoAlignAxis(.vertical, toSameAxisOf: bearingLabel);
        bearingLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        targetBearingContainer.autoPinEdge(toSuperviewEdge: .bottom);
        targetBearingContainer.autoPinEdge(.top, to: .bottom, of: bearingLabel, withOffset: 0);
        return view;
    }();
    
    private lazy var speedContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(speedLabel);
        view.addSubview(speedMarkerView);
        speedMarkerView.autoPinEdge(toSuperviewEdge: .top);
        speedLabel.autoSetDimension(.width, toSize: 70);
        speedLabel.textAlignment = .center;
        speedLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
        speedLabel.autoPinEdge(.top, to: .bottom, of: speedMarkerView, withOffset: 8);
        speedMarkerView.autoAlignAxis(.vertical, toSameAxisOf: speedLabel);
        return view;
    }();
    
    private lazy var targetBearingMarkerView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "location_tracking_on"));
        view.contentMode = .scaleAspectFit;
        view.autoSetDimensions(to: CGSize(width: 16, height: 16));
        return view;
    }();
    
    private lazy var speedMarkerView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "speed"));
        view.contentMode = .scaleAspectFit;
        view.autoSetDimensions(to: CGSize(width: 36, height: 36));
        return view;
    }();
    
    private lazy var destinationMarkerView: UIImageView = {
        let view = UIImageView(image: destinationMarker);
        view.contentMode = .scaleAspectFit;
        view.autoSetDimensions(to: CGSize(width: 36, height: 36));
        return view;
    }();
    
    private lazy var destinationContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(destinationMarkerView);
        view.addSubview(distanceToTargetLabel);
        destinationMarkerView.autoPinEdge(toSuperviewEdge: .top);
        distanceToTargetLabel.autoSetDimension(.width, toSize: 70);
        distanceToTargetLabel.textAlignment = .center;
        distanceToTargetLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
        distanceToTargetLabel.autoPinEdge(.top, to: .bottom, of: destinationMarkerView, withOffset: 8);
        destinationMarkerView.autoAlignAxis(.vertical, toSameAxisOf: distanceToTargetLabel);
        return view;
    }();
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        bearingLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        speedLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        speedMarkerView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        targetBearingMarkerView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        distanceToTargetLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        bearingToTargetLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        cancelButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        
        bearingLabel.font = scheme.typographyScheme.headline3;
        speedLabel.font = scheme.typographyScheme.overline;
        distanceToTargetLabel.font = scheme.typographyScheme.overline;
        bearingToTargetLabel.font = scheme.typographyScheme.overline;
        
        compassView?.applyTheme(withScheme: scheme);
    }
    
    @objc public convenience init(locationManager: CLLocationManager?, destinationMarker: UIImage?, destinationCoordinate: CLLocationCoordinate2D, delegate: StraightLineNavigationDelegate?, scheme: MDCContainerScheming? = nil, targetColor: UIColor = .systemGreen, bearingColor: UIColor = .systemRed) {
        self.init(frame: .zero);
        self.locationManager = locationManager;
        self.destinationCoordinate = destinationCoordinate;
        self.destinationMarker = destinationMarker;
        self.scheme = scheme;
        self.targetColor = targetColor;
        self.bearingColor = bearingColor;
        self.delegate = delegate;
        layoutView();
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    @objc public func populate(targetColor: UIColor = .systemGreen, bearingColor: UIColor = .systemRed) {
        self.targetColor = targetColor;
        self.bearingColor = bearingColor;
        let measurementFormatter = MeasurementFormatter();
        measurementFormatter.unitOptions = .providedUnit;
        measurementFormatter.unitStyle = .short;
        measurementFormatter.numberFormatter.maximumFractionDigits = 2;
        guard let userLocation = locationManager?.location else {
            return;
        }
        if let heading = locationManager?.heading {
            let bearingTo = userLocation.coordinate.bearing(to: destinationCoordinate!);
            compassView?.updateHeading(heading: heading, destinationBearing: bearingTo, targetColor: self.targetColor, bearingColor: self.bearingColor);
            let headingMeasurement = Measurement(value: heading.trueHeading, unit: UnitAngle.degrees);
            let bearingToMeasurement = Measurement(value: bearingTo, unit: UnitAngle.degrees);
            bearingLabel.text = "\(measurementFormatter.string(from: headingMeasurement))";
            bearingToTargetLabel.text = "\(measurementFormatter.string(from: bearingToMeasurement))";
        }
        
        if let speed = locationManager?.location?.speed {
            let metersPerSecondMeasurement = Measurement(value: speed, unit: UnitSpeed.metersPerSecond);
            speedLabel.text = "\(measurementFormatter.string(from: metersPerSecondMeasurement.converted(to: .knots)))";
        }
        
        let destinationLocation = CLLocation(latitude: destinationCoordinate?.latitude ?? 0, longitude: destinationCoordinate?.longitude ?? 0);
        let metersMeasurement = NSMeasurement(doubleValue: destinationLocation.distance(from: userLocation), unit: UnitLength.meters);
        let convertedMeasurement = metersMeasurement.converting(to: UnitLength.nauticalMiles);
        distanceToTargetLabel.text = "\(measurementFormatter.string(from: convertedMeasurement))"
    }
    
    func layoutView() {
        compassView = CompassView(scheme: self.scheme, targetColor: self.targetColor, bearingColor: self.bearingColor);
        compassView?.autoSetDimensions(to: CGSize(width: 250, height: 250))
        compassView?.clipsToBounds = true;
        compassView?.layer.cornerRadius = 125
        addSubview(compassView!);
        addSubview(bearingContainer);
        addSubview(speedContainer);
        addSubview(destinationContainer);
        addSubview(cancelButton);
        speedContainer.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
        speedContainer.autoAlignAxis(toSuperviewAxis: .horizontal);
        destinationContainer.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        destinationContainer.autoAlignAxis(toSuperviewAxis: .horizontal);
        bearingContainer.autoCenterInSuperview();
        compassView?.autoCenterInSuperview();
        cancelButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 50);
        cancelButton.autoPinEdge(toSuperviewEdge: .right, withInset: 4);
        self.autoSetDimension(.height, toSize: 75);
    }
    
    @objc func cancelButtonPressed() {
        delegate?.cancelStraightLineNavigation();
    }
    
}
