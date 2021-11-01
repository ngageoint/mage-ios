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
    
    private lazy var directionArrowLayer: CAShapeLayer = {
        let path = CGMutablePath()
        let heightWidth = 50
        
        path.move(to: CGPoint(x: heightWidth / 2, y: 0))
        path.addLine(to: CGPoint(x:(heightWidth / 2 - 6), y:8))
        path.addLine(to: CGPoint(x:(heightWidth / 2 - 1), y:8))
        path.addLine(to: CGPoint(x:(heightWidth / 2 - 1), y:16))
        path.addLine(to: CGPoint(x:(heightWidth / 2 + 1), y:16))
        path.addLine(to: CGPoint(x:(heightWidth / 2 + 1), y:8))
        path.addLine(to: CGPoint(x:(heightWidth / 2 + 6), y:8))
        path.addLine(to: CGPoint(x:(heightWidth / 2), y:0))
        
        let shape = CAShapeLayer()
        shape.path = path
        
        return shape;
    }()
    
    private lazy var directionArrow: UIView = {
        let view = UIView.newAutoLayout();
        view.layer.insertSublayer(directionArrowLayer, at: 0);
        return view;
    }()
    
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom);
        cancelButton.accessibilityLabel = "cancel";
        cancelButton.setImage(UIImage(named: "cancel" )?.withRenderingMode(.alwaysTemplate), for: .normal);
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        return cancelButton;
    }();
    
    private lazy var myInformationContainer: UIView = {
        let view = UIView.newAutoLayout();
        view.addSubview(headingLabel);
        view.addSubview(speedLabel);
        return view;
    }()
    
    private lazy var targetInformationContainer: UIView = {
        let view = UIView.newAutoLayout();
        view.addSubview(relativeBearingToTargetLabel);
        view.addSubview(distanceToTargetLabel);
        return view;
    }()
    
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
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        self.backgroundColor = scheme?.colorScheme.surfaceColor;
        headingLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        speedLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        speedMarkerView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        targetMarkerView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        distanceToTargetLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        relativeBearingToTargetLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        cancelButton.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        
        headingLabel.font = scheme?.typographyScheme.overline;
        speedLabel.font = scheme?.typographyScheme.overline;
        distanceToTargetLabel.font = scheme?.typographyScheme.headline6;
        relativeBearingToTargetLabel.font = scheme?.typographyScheme.headline6;
        
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
        
        applyTheme(withScheme: scheme);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            compassView?.autoSetDimensions(to: CGSize(width: 350, height: 350))
            compassView?.autoAlignAxis(toSuperviewAxis: .vertical);
            compassView?.autoAlignAxis(.horizontal, toSameAxisOf: self, withOffset: 50);
            
            cancelButton.autoPinEdge(toSuperviewEdge: .top, withInset: 4);
            cancelButton.autoPinEdge(toSuperviewEdge: .right, withInset: 4);
            
            destinationMarkerView.autoSetDimensions(to: CGSize(width: 18, height: 18));
            destinationMarkerView.autoAlignAxis(toSuperviewAxis: .vertical);
            targetInformationContainer.autoPinEdge(.top, to: .bottom, of: destinationMarkerView, withOffset: 16);
            
            distanceToTargetLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right);
            relativeBearingToTargetLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left);
            relativeBearingToTargetLabel.autoPinEdge(.left, to: .right, of: distanceToTargetLabel, withOffset: 8);
            
            targetInformationContainer.autoAlignAxis(toSuperviewAxis: .vertical);
            
            speedLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right);
            headingLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left);
            headingLabel.autoPinEdge(.left, to: .right, of: speedLabel, withOffset: 8);
            myInformationContainer.autoPinEdge(.top, to: .bottom, of: targetInformationContainer, withOffset: 2);
            myInformationContainer.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4);
            myInformationContainer.autoAlignAxis(toSuperviewAxis: .vertical);
            
            directionArrow.autoAlignAxis(.horizontal, toSameAxisOf: destinationMarkerView);
            directionArrow.autoAlignAxis(.vertical, toSameAxisOf: destinationMarkerView);
            directionArrow.autoSetDimensions(to: CGSize(width: 51, height: 51));
            
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
            relativeBearingToTargetLabel.text = "@ \(measurementFormatter.string(from: bearingToMeasurement))";
            let degreeMeasurement = Measurement(value: 360 - (headingMeasurement.value - bearingToMeasurement.value) , unit: UnitAngle.degrees);
            directionArrow.transform = CGAffineTransform(rotationAngle: CGFloat(degreeMeasurement.converted(to: .radians).value));
            directionArrowLayer.fillColor = self.headingColor.cgColor;
            relativeBearingToTargetLabel.textColor = self.relativeBearingColor;
            headingLabel.textColor = self.headingColor;
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
        compassView?.layer.cornerRadius = 175
        addSubview(compassView!);
        addSubview(destinationMarkerView);
        addSubview(myInformationContainer);
        addSubview(targetInformationContainer);
        addSubview(directionArrow);
        addSubview(cancelButton);
    }
    
    @objc func cancelButtonPressed() {
        delegate?.cancelStraightLineNavigation();
    }
    
}
