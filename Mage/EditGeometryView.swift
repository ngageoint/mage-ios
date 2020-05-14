//
//  EditGeometryView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditGeometryView : BaseFieldView {
    private var accuracy: Double?;
    private var provider: String?;
    
    private var mapDelegate: MapDelegate = MapDelegate();
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        controller.textInput = textField;
        return textField;
    }()
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.autoSetDimension(.height, toSize: 95);
        mapDelegate.setMapView(mapView);
        mapView.delegate = mapDelegate;
        mapDelegate.setupListeners();
        mapDelegate.hideStaticLayers = true;
        return mapView;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: NSDictionary, delegate: ObservationEditListener? = nil) {
        self.init(field: field, delegate: delegate, value: nil);
    }
    
    init(field: NSDictionary, delegate: ObservationEditListener? = nil, value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil) {
        super.init(field: field, delegate: delegate, value: value);
        setValue(value);

        buildView();
        setValue(value);

        setAccuracy(accuracy, provider: provider);
        
        setupController();
        if (UserDefaults.standard.bool(forKey: "showMGRS")) {
            controller.placeholderText = (field.object(forKey: "title") as? String ?? "") + " (MGRS)";
        } else {
            controller.placeholderText = (field.object(forKey: "title") as? String ?? "") + " (Lat, Long)";
        }
        
        if ((field.object(forKey: "required") as? Bool) == true) {
            controller.placeholderText = (controller.placeholderText ?? "") + " *"
        }
    }
    
    deinit {
        self.mapDelegate.cleanup();
    }
    
    override func setupController() {
        if (UserDefaults.standard.bool(forKey: "showMGRS")) {
            controller.placeholderText = (field.object(forKey: "title") as? String ?? "") + " (MGRS)";
        } else {
            controller.placeholderText = (field.object(forKey: "title") as? String ?? "") + " (Lat, Long)";
        }
        
        if ((field.object(forKey: "required") as? Bool) == true) {
            controller.placeholderText = (controller.placeholderText ?? "") + " *"
        }
    }
    
    func buildView() {
        let wrapper = UIView(forAutoLayout: ());
        self.addSubview(wrapper);
        wrapper.autoPinEdgesToSuperviewEdges();
        wrapper.addSubview(textField);
        textField.sizeToFit();
        textField.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .bottom);
        wrapper.addSubview(mapView);
        mapView.autoPinEdge(.top, to: .bottom, of: textField, withOffset: 8);
        mapView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .top);
        
        mapDelegate.ensureMapLayout();
        
        addTapRecognizer();
    }
    
    override func isEmpty() -> Bool{
        return self.value == nil;
    }
    
    func setAccuracy(_ accuracy: Double?, provider: String?) {
        self.accuracy = accuracy;
        self.provider = provider;
        if (accuracy != nil) {
            if (self.provider != "manual") {
                var formattedProvider: String = "";
                if (self.provider == "gps") {
                    formattedProvider = provider!.uppercased();
                } else if (provider != nil) {
                    formattedProvider = provider!.capitalized;
                }
                
                controller.helperText = String(format: "%@ Location Accuracy +/- %.02fm", formattedProvider, accuracy!);
            }
        }
        //            double accuracy = [accuracyProperty doubleValue];
        //
        //            ObservationAccuracy *overlay = [ObservationAccuracy circleWithCenterCoordinate:observation.location.coordinate radius:accuracy];
        //            [self.mapView addOverlay:overlay];
        //
        //            NSString *provider = [observation.properties objectForKey:@"provider"];
        //            if (![provider isEqualToString:@"manual"]) {
        //                self.locationHelperView.hidden = NO;
        //
        //                if ([provider isEqualToString:@"gps"]) {
        //                    provider = [provider uppercaseString];
        //                } else if (provider != nil) {
        //                    provider = [provider capitalizedString];
        //                }
        //
        //                NSString *accuracy = @"";
        //                id accuracyProperty = [observation.properties valueForKey:@"accuracy"];
        //                if (accuracyProperty != nil) {
        //                    accuracy = [NSString stringWithFormat:@" +/- %.02fm", [accuracyProperty floatValue]];
        //                }
        //
        //                self.locationHelperLabel.text = [NSString stringWithFormat:@"%@ Location Accuracy %@", provider ?: @"", accuracy];
        //            }
    }
    
    func setValue(_ value: SFGeometry?) {
        self.value = value;
        if (value != nil) {
            if let point: SFPoint = (self.value as? SFGeometry)!.centroid() {
                if (UserDefaults.standard.bool(forKey: "showMGRS")) {
                    textField.text = MGRS.mgrSfromCoordinate(CLLocationCoordinate2D.init(latitude: point.y as! CLLocationDegrees, longitude: point.x as! CLLocationDegrees));
                } else {
                    textField.text = String(format: "%.6f, %.6f", point.y.doubleValue, point.x.doubleValue);
                }
            }
        } else {
            textField.text = nil;
        }
    }
    
    override func setValid(_ valid: Bool) {
        if (valid) {
            controller.setErrorText(nil, errorAccessibilityValue: nil);
        } else {
            controller.setErrorText(((field.object(forKey: "title") as? String) ?? "Field ") + " is required", errorAccessibilityValue: nil);
        }
    }
}
