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
    var didSetupConstraints = false;

    var delegate: StraightLineNavigationDelegate?;
    var scheme: MDCContainerScheming?;
    var locationManager: CLLocationManager?;
    var destinationCoordinate: CLLocationCoordinate2D?;
    var destinationMarker: UIImage?;
    var relativeBearingColor: UIColor = .systemGreen;
    var headingColor: UIColor = .systemRed;
    
    var headingLabel: UILabel = UILabel(forAutoLayout: ());
    var speedLabel: UILabel = UILabel(forAutoLayout: ());
    var distanceToTargetLabel: UILabel = UILabel(forAutoLayout: ());
    var relativeBearingToTargetLabel: UILabel = UILabel(forAutoLayout: ());
    var compassView: CompassView?;
    
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom);
        cancelButton.accessibilityLabel = "cancel";
        cancelButton.setImage(UIImage(named: "cancel" )?.withRenderingMode(.alwaysTemplate), for: .normal);
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        return cancelButton;
    }();
    
    private lazy var relativeBearingContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(targetMarkerView);
        view.addSubview(relativeBearingToTargetLabel);
        return view;
    }();
    
    private lazy var headingContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(headingLabel);
        view.addSubview(relativeBearingContainer);
        return view;
    }();
    
    private lazy var speedContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(speedLabel);
        view.addSubview(speedMarkerView);
        speedLabel.textAlignment = .center;
        return view;
    }();
    
    private lazy var targetMarkerView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "location_tracking_on"));
        view.contentMode = .scaleAspectFit;
        return view;
    }();
    
    private lazy var speedMarkerView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "speed"));
        view.contentMode = .scaleAspectFit;
        return view;
    }();
    
    private lazy var destinationMarkerView: UIImageView = {
        let view = UIImageView(image: destinationMarker);
        view.contentMode = .scaleAspectFit;
        return view;
    }();
    
    private lazy var destinationContainer: UIView = {
        let view = UIView(forAutoLayout: ());
        view.addSubview(destinationMarkerView);
        view.addSubview(distanceToTargetLabel);
        distanceToTargetLabel.textAlignment = .center;
        return view;
    }();
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        headingLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        speedLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        speedMarkerView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        targetMarkerView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        distanceToTargetLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        relativeBearingToTargetLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        cancelButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        
        headingLabel.font = scheme.typographyScheme.headline3;
        speedLabel.font = scheme.typographyScheme.overline;
        distanceToTargetLabel.font = scheme.typographyScheme.overline;
        relativeBearingToTargetLabel.font = scheme.typographyScheme.overline;
        
        compassView?.applyTheme(withScheme: scheme);
    }
    
    @objc public convenience init(locationManager: CLLocationManager?, destinationMarker: UIImage?, destinationCoordinate: CLLocationCoordinate2D, delegate: StraightLineNavigationDelegate?, scheme: MDCContainerScheming? = nil, targetColor: UIColor = .systemGreen, bearingColor: UIColor = .systemRed) {
        self.init(frame: .zero);
        self.locationManager = locationManager;
        self.destinationCoordinate = destinationCoordinate;
        self.destinationMarker = destinationMarker;
        self.scheme = scheme;
        self.relativeBearingColor = targetColor;
        self.headingColor = bearingColor;
        self.delegate = delegate;
        layoutView();
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            targetMarkerView.autoPinEdge(toSuperviewEdge: .left);
            relativeBearingToTargetLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left);
            relativeBearingToTargetLabel.autoPinEdge(.left, to: .right, of: targetMarkerView, withOffset: 8);
            targetMarkerView.autoAlignAxis(.horizontal, toSameAxisOf: relativeBearingToTargetLabel);
            relativeBearingContainer.autoAlignAxis(.vertical, toSameAxisOf: headingLabel);
            headingLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            relativeBearingContainer.autoPinEdge(toSuperviewEdge: .bottom);
            relativeBearingContainer.autoPinEdge(.top, to: .bottom, of: headingLabel, withOffset: 0);
            speedLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
            speedLabel.autoPinEdge(.top, to: .bottom, of: speedMarkerView, withOffset: 8);
            speedMarkerView.autoAlignAxis(.vertical, toSameAxisOf: speedLabel);
            speedMarkerView.autoPinEdge(toSuperviewEdge: .top);
            speedLabel.autoSetDimension(.width, toSize: 70);
            targetMarkerView.autoSetDimensions(to: CGSize(width: 16, height: 16));
            speedMarkerView.autoSetDimensions(to: CGSize(width: 36, height: 36));
            destinationMarkerView.autoSetDimensions(to: CGSize(width: 36, height: 36));
            destinationMarkerView.autoPinEdge(toSuperviewEdge: .top);
            distanceToTargetLabel.autoSetDimension(.width, toSize: 70);
            distanceToTargetLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
            distanceToTargetLabel.autoPinEdge(.top, to: .bottom, of: destinationMarkerView, withOffset: 8);
            destinationMarkerView.autoAlignAxis(.vertical, toSameAxisOf: distanceToTargetLabel);
            compassView?.autoSetDimensions(to: CGSize(width: 250, height: 250))
            speedContainer.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
            speedContainer.autoAlignAxis(toSuperviewAxis: .horizontal);
            destinationContainer.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
            destinationContainer.autoAlignAxis(toSuperviewAxis: .horizontal);
            headingContainer.autoCenterInSuperview();
            compassView?.autoCenterInSuperview();
            cancelButton.autoPinEdge(toSuperviewEdge: .top, withInset: 4);
            cancelButton.autoPinEdge(toSuperviewEdge: .right, withInset: 4);
            self.autoSetDimension(.height, toSize: 75);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    @objc public func populate(relativeBearingColor: UIColor = .systemGreen, headingColor: UIColor = .systemRed) {
        self.relativeBearingColor = relativeBearingColor;
        self.headingColor = headingColor;
        let measurementFormatter = MeasurementFormatter();
        measurementFormatter.unitOptions = .providedUnit;
        measurementFormatter.unitStyle = .short;
        measurementFormatter.numberFormatter.maximumFractionDigits = 2;
        guard let userLocation = locationManager?.location else {
            return;
        }
        
        var bearing = userLocation.course;
        let speed = userLocation.speed;
        // if the user is moving, use their direction of movement
        if (bearing < 0 || speed <= 0) {
            // if the user is not moving, use the heading of the phone
            if let trueHeading = locationManager?.heading?.trueHeading {
                bearing = trueHeading;
            }
        }
        
        if (bearing >= 0) {
            let bearingTo = userLocation.coordinate.bearing(to: destinationCoordinate!);
            compassView?.updateHeading(heading: bearing, destinationBearing: bearingTo, targetColor: self.relativeBearingColor, bearingColor: self.headingColor);
            let headingMeasurement = Measurement(value: bearing, unit: UnitAngle.degrees);
            let bearingToMeasurement = Measurement(value: bearingTo, unit: UnitAngle.degrees);
            headingLabel.text = "\(measurementFormatter.string(from: headingMeasurement))";
            relativeBearingToTargetLabel.text = "\(measurementFormatter.string(from: bearingToMeasurement))";
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
        compassView = CompassView(scheme: self.scheme, targetColor: self.relativeBearingColor, headingColor: self.headingColor);
        compassView?.clipsToBounds = true;
        compassView?.layer.cornerRadius = 125
        addSubview(compassView!);
        addSubview(headingContainer);
        addSubview(speedContainer);
        addSubview(destinationContainer);
        addSubview(cancelButton);
    }
    
    @objc func cancelButtonPressed() {
        delegate?.cancelStraightLineNavigation();
    }
    
}
