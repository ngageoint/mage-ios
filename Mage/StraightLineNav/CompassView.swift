//
//  CompassView.swift
//  MAGE
//
//  Created by Daniel Barela on 4/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct Marker {
    let degrees: Double
    let label: String
    
    init(degrees: Double, label: String = "") {
        self.degrees = degrees
        self.label = label
    }
    
    func degreeText() -> String {
        if (self.degrees.remainder(dividingBy: 30) == 0) {
            return String(format: "%.0f", self.degrees);
        }
        return "";
    }
    
    static func markers() -> [Marker] {
        return [
            Marker(degrees: 0, label: "N"),
            Marker(degrees: 5),
            Marker(degrees: 10),
            Marker(degrees: 15),
            Marker(degrees: 20),
            Marker(degrees: 25),
            Marker(degrees: 30),
            Marker(degrees: 35),
            Marker(degrees: 40),
            Marker(degrees: 45),
            Marker(degrees: 50),
            Marker(degrees: 55),
            Marker(degrees: 60),
            Marker(degrees: 65),
            Marker(degrees: 70),
            Marker(degrees: 75),
            Marker(degrees: 80),
            Marker(degrees: 85),
            Marker(degrees: 90, label: "E"),
            Marker(degrees: 95),
            Marker(degrees: 100),
            Marker(degrees: 105),
            Marker(degrees: 110),
            Marker(degrees: 115),
            Marker(degrees: 120),
            Marker(degrees: 125),
            Marker(degrees: 130),
            Marker(degrees: 135),
            Marker(degrees: 140),
            Marker(degrees: 145),
            Marker(degrees: 150),
            Marker(degrees: 155),
            Marker(degrees: 160),
            Marker(degrees: 165),
            Marker(degrees: 170),
            Marker(degrees: 175),
            Marker(degrees: 180, label: "S"),
            Marker(degrees: 185),
            Marker(degrees: 190),
            Marker(degrees: 195),
            Marker(degrees: 200),
            Marker(degrees: 205),
            Marker(degrees: 210),
            Marker(degrees: 215),
            Marker(degrees: 220),
            Marker(degrees: 225),
            Marker(degrees: 230),
            Marker(degrees: 235),
            Marker(degrees: 240),
            Marker(degrees: 245),
            Marker(degrees: 250),
            Marker(degrees: 255),
            Marker(degrees: 260),
            Marker(degrees: 265),
            Marker(degrees: 270, label: "W"),
            Marker(degrees: 275),
            Marker(degrees: 280),
            Marker(degrees: 285),
            Marker(degrees: 290),
            Marker(degrees: 295),
            Marker(degrees: 300),
            Marker(degrees: 305),
            Marker(degrees: 310),
            Marker(degrees: 315),
            Marker(degrees: 320),
            Marker(degrees: 325),
            Marker(degrees: 330),
            Marker(degrees: 335),
            Marker(degrees: 340),
            Marker(degrees: 345),
            Marker(degrees: 350),
            Marker(degrees: 355)
        ]
    }
}

class CompassTargetView: CompassMarkerView {
    var targetColor: UIColor = .systemGreen;
    
    public convenience init(marker: Marker? = nil, compassDegrees: Double? = nil, targetColor: UIColor = .systemGreen) {
        self.init(marker: marker, compassDegrees: compassDegrees);
        self.targetColor = targetColor;
    }
    
    override func capsuleWidth() -> CGFloat {
        return 5
    }
    
    override func capsuleHeight() -> CGFloat {
        return 20;
    }
    
    override func capsuleColor() -> UIColor {
        return targetColor;
    }
}

class CompassMarkerView: UIView {
    var marker: Marker?
    var compassDegrees: Double?
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0;
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.isUserInteractionEnabled = false;
        return stack;
    }()
    
    public convenience init(marker: Marker? = nil, compassDegrees: Double? = nil) {
        self.init(frame: .zero);
        self.marker = marker;
        self.compassDegrees = compassDegrees;
        layout();
    }
    
    func layout() {
        let degreeMeasurement = Measurement(value: marker?.degrees ?? 0, unit: UnitAngle.degrees);
        let transform = CGAffineTransform(rotationAngle: CGFloat(degreeMeasurement.converted(to: .radians).value))
        
        let degreeLabel = UILabel(forAutoLayout: ());
        degreeLabel.text = marker?.degreeText();
        degreeLabel.transform = textTransform();
        
        let capsule = UIView(forAutoLayout: ());
        capsule.autoSetDimensions(to: CGSize(width: capsuleWidth(), height: capsuleHeight()));
        capsule.backgroundColor = capsuleColor();
        
        let capsuleContainer = UIView(forAutoLayout: ());
        capsuleContainer.addSubview(capsule);
        capsule.autoAlignAxis(toSuperviewAxis: .vertical);
        capsule.autoPinEdge(toSuperviewEdge: .top);
        
        let markerLabel = UILabel(forAutoLayout: ());
        markerLabel.text = marker?.label;
        markerLabel.transform = textTransform();
        
        addSubview(capsuleContainer);
        addSubview(degreeLabel);
        addSubview(markerLabel);
        
        degreeLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 5);
        degreeLabel.autoAlignAxis(toSuperviewAxis: .vertical);
        capsuleContainer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 30, left: 0, bottom: 20, right: 0), excludingEdge: .bottom);
        markerLabel.autoPinEdge(.top, to: .bottom, of: degreeLabel, withOffset: 30);
        markerLabel.autoAlignAxis(toSuperviewAxis: .vertical);
        
        self.transform = transform;
    }

    func capsuleWidth() -> CGFloat {
        return self.marker?.degrees == 0 ? 5 : 2
    }
    
    func capsuleHeight() -> CGFloat {
        return self.marker?.degrees.remainder(dividingBy: 90) == 0 ? 20 : self.marker?.degrees.remainder(dividingBy: 30) == 0 ? 12 :
            self.marker?.degrees.remainder(dividingBy: 10) == 0 ? 6 : 3
    }
    
    func capsuleColor() -> UIColor {
        return .gray
    }
    
    func textTransform() -> CGAffineTransform {
        let degrees = CLLocationDegrees(Double((-(self.compassDegrees ?? 0))) - (self.marker?.degrees ?? 0))
        let degreeMeasurement = Measurement(value: degrees, unit: UnitAngle.degrees);
        return CGAffineTransform(rotationAngle: CGFloat(degreeMeasurement.converted(to: .radians).value))
    }
}

class CompassView: UIView {
    var scheme: MDCContainerScheming?;
    var targetColor: UIColor = .systemGreen;
    var bearingColor: UIColor = .systemRed;
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0;
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.isUserInteractionEnabled = false;
        return stack;
    }()
    
    public convenience init(scheme: MDCContainerScheming? = nil, targetColor: UIColor = .systemGreen, bearingColor: UIColor = .systemRed) {
        self.init(frame: .zero);
        self.scheme = scheme;
        self.targetColor = targetColor;
        self.bearingColor = bearingColor;
        
        layoutView(heading: 0.0);
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.backgroundColor = scheme.colorScheme.surfaceColor.withAlphaComponent(0.87);
    }
    
    func layoutView(heading: Double, destinationBearing: Double) {
        let rotationalHeading = 360.0 - heading;
        let markerContainer = layoutView(heading: heading);
        let marker = Marker(degrees: destinationBearing);
        let compassTargetView = CompassTargetView(marker: marker, compassDegrees: rotationalHeading, targetColor: self.targetColor);
        markerContainer.addSubview(compassTargetView);
        compassTargetView.autoPinEdgesToSuperviewEdges();
    }
    
    @discardableResult func layoutView(heading: Double) -> UIView {
        let rotationalHeading = 360.0 - heading;
        let capsule = UIView(forAutoLayout: ());
        capsule.autoSetDimensions(to: CGSize(width: 5, height: 50));
        capsule.backgroundColor = self.bearingColor;
        
        let markerContainer = UIView(forAutoLayout: ());
        for marker in Marker.markers() {
            var leftLowerLimit = heading - 60;
            if (leftLowerLimit < 0) {
                leftLowerLimit = leftLowerLimit + 360;
            }
            if (leftLowerLimit > 360) {
                leftLowerLimit = leftLowerLimit - 360;
            }
            var rightUpperLimit = heading + 60;
            if (rightUpperLimit < 0) {
                rightUpperLimit = rightUpperLimit + 360;
            }
            if (rightUpperLimit > 360) {
                rightUpperLimit = rightUpperLimit - 360;
            }
            if (leftLowerLimit > rightUpperLimit) {
                if ((marker.degrees <= rightUpperLimit) || (marker.degrees >= leftLowerLimit)) {
                    let compassMarkerView = CompassMarkerView(marker: marker, compassDegrees: rotationalHeading);
                    markerContainer.addSubview(compassMarkerView);
                    compassMarkerView.autoPinEdgesToSuperviewEdges();
                }
            } else {
                if ((marker.degrees <= rightUpperLimit) && (marker.degrees >= leftLowerLimit)) {
                    let compassMarkerView = CompassMarkerView(marker: marker, compassDegrees: rotationalHeading);
                    markerContainer.addSubview(compassMarkerView);
                    compassMarkerView.autoPinEdgesToSuperviewEdges();
                }
            }
        }
        let degreeMeasurement = Measurement(value: rotationalHeading, unit: UnitAngle.degrees);
        markerContainer.transform = CGAffineTransform(rotationAngle: CGFloat(degreeMeasurement.converted(to: .radians).value));
        
        addSubview(capsule);
        addSubview(markerContainer);
        
        capsule.autoPinEdge(toSuperviewEdge: .top);
        capsule.autoAlignAxis(toSuperviewAxis: .vertical);
        markerContainer.autoPinEdgesToSuperviewEdges();
        return markerContainer;
    }
    
    func updateHeading(heading: CLHeading, targetColor: UIColor = .systemGreen, bearingColor: UIColor = .systemRed) {
        self.targetColor = targetColor;
        self.bearingColor = bearingColor;
        for v in subviews {
            v.removeFromSuperview();
        }
        layoutView(heading: heading.trueHeading);
    }
    
    func updateHeading(heading: CLHeading, destinationBearing: Double, targetColor: UIColor = .systemGreen, bearingColor: UIColor = .systemRed) {
        self.targetColor = targetColor;
        self.bearingColor = bearingColor;
        for v in subviews {
            v.removeFromSuperview();
        }
        layoutView(heading: heading.trueHeading, destinationBearing: destinationBearing);
    }
    
}
