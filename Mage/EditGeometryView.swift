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
    private var mapEventDelegate: MKMapViewDelegate?;
    
    private var mapDelegate: MapDelegate = MapDelegate();
    private var observation: Observation?;
    private var eventForms: [NSDictionary]?;
    
    private var mapObservation: MapObservation?;
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        controller.textInput = textField;
        return textField;
    }()
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.mapType = .standard;
        mapView.autoSetDimension(.height, toSize: 95);
        mapDelegate.setMapView(mapView);
        mapView.delegate = mapDelegate;
        mapDelegate.setupListeners();
        mapDelegate.hideStaticLayers = true;
        return mapView;
    }()
    
    lazy var observationManager: MapObservationManager = {
        let observationManager: MapObservationManager = MapObservationManager(mapView: self.mapView, andEventForms: eventForms);
        return observationManager;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: NSDictionary, delegate: ObservationEditListener? = nil, mapEventDelegate: MKMapViewDelegate? = nil) {
        self.init(field: field, delegate: delegate, value: nil, mapEventDelegate: mapEventDelegate);
    }
    
    convenience init(field: NSDictionary, delegate: ObservationEditListener? = nil, observation: Observation?, eventForms: [NSDictionary]?, mapEventDelegate: MKMapViewDelegate? = nil) {
        let accuracy = ((observation?.properties as? NSDictionary)?.value(forKey: "accuracy") as? Double);
        let provider = ((observation?.properties as? NSDictionary)?.value(forKey: "provider") as? String);
        self.init(field: field, delegate: delegate, value: observation?.getGeometry(), accuracy: accuracy, provider: provider, mapEventDelegate: mapEventDelegate, observation: observation, eventForms: eventForms);
    }
    
    init(field: NSDictionary, delegate: ObservationEditListener? = nil, value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observation: Observation? = nil, eventForms: [NSDictionary]? = nil) {
        super.init(field: field, delegate: delegate, value: value);
        self.observation = observation;
        self.eventForms = eventForms;
        
        mapDelegate.setMapEventDelegte(mapEventDelegate);
        buildView();
        
        setValue(value, accuracy: accuracy, provider: provider);
        if (self.observation == nil) {
            addToMap();
        } else {
            addToMapAsObservation();
        }

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
    
    func addToMapAsObservation() {
        self.mapObservation = self.observationManager.addToMap(with: self.observation);
        guard let viewRegion = self.mapObservation?.viewRegion(of: self.mapView) else { return };
        self.mapView.setRegion(viewRegion, animated: true);
    }
    
    func addToMap() {
        if (self.value != nil) {
            let shapeConverter: GPKGMapShapeConverter = GPKGMapShapeConverter();
            let shape: GPKGMapShape = shapeConverter.toShape(with: (self.value as? SFGeometry));
            var options: GPKGMapPointOptions? = nil;
            if ((self.value as? SFGeometry)?.geometryType != SF_POINT) {
                options = GPKGMapPointOptions();
                options!.image = UIImage();
            }
            
            shapeConverter.add(shape, asPointsTo: self.mapView, with: options, andPolylinePointOptions: options, andPolygonPointOptions: options, andPolygonPointHoleOptions: options, andPolylineOptions: nil, andPolygonOptions: nil);
            setMapRegion();
        }
    }

    func setMapRegion() {
        if let centroid = (self.value as? SFGeometry)?.centroid() {
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centroid.y as! CLLocationDegrees, longitude: centroid.x as! CLLocationDegrees), span: MKCoordinateSpan(latitudeDelta: 0.03125, longitudeDelta: 0.03125));
            let viewRegion = self.mapView.regionThatFits(region);
            self.mapView.setRegion(viewRegion, animated: false);
        }
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
                if let centroid = (self.value as? SFGeometry)!.centroid() {
                    let overlay = ObservationAccuracy(center: CLLocationCoordinate2D(latitude: centroid.y as! CLLocationDegrees, longitude: centroid.x as! CLLocationDegrees), radius: self.accuracy ?? 0)
                        self.mapView.addOverlay(overlay);
                }
            }
        }
    }
    
    func setValue(_ value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil) {
        self.value = value;
        if (value != nil) {
            if let point: SFPoint = (self.value as? SFGeometry)!.centroid() {
                if (UserDefaults.standard.bool(forKey: "showMGRS")) {
                    textField.text = MGRS.mgrSfromCoordinate(CLLocationCoordinate2D.init(latitude: point.y as! CLLocationDegrees, longitude: point.x as! CLLocationDegrees));
                } else {
                    textField.text = String(format: "%.6f, %.6f", point.y.doubleValue, point.x.doubleValue);
                }
            }
            setAccuracy(accuracy, provider: provider);
            addToMap();
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
