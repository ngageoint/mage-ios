//
//  ObservationGeometryView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;
import MaterialComponents.MDCButton;

class ObservationGeometryView : UIView {
    internal var field: [String: Any]!;
    private var value: SFGeometry?;
    private var accuracy: Double?;
    private var provider: String?;
    private var mapEventDelegate: MKMapViewDelegate?;
    
    private var showFieldName = false;
    private var observation: Observation?;
    private var eventForms: [[String: Any]]?;
    
    private var mapObservation: MapObservation?;
    
    private lazy var mapDelegate: MapDelegate = {
        return MapDelegate();
    }()
    
    private lazy var fieldNameLabel: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = .systemGray;
        var font = containerScheme.typographyScheme.body1;
        font = font.withSize(font.pointSize * MDCTextInputControllerBase.floatingPlaceholderScaleDefault);
        label.font = font;
        
        return label;
    }()
    
    private lazy var latitudeLongitudeButton: MDCButton = {
        let containerScheme = globalContainerScheme();
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = "location";
        button.setImage(UIImage(named: "location_tracking_on")?.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5);
        button.applyTextTheme(withScheme: containerScheme);
        return button;
    }()
    
    private lazy var accuracyLabel: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = .systemGray;
        label.font = containerScheme.typographyScheme.caption;
        return label;
    }()
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.mapType = .standard;
        mapView.autoSetDimension(.height, toSize: 200);
        mapDelegate.setMapView(mapView);
        mapView.delegate = mapDelegate;
        mapDelegate.setupListeners();
        mapDelegate.hideStaticLayers = true;
        return mapView;
    }()
    
    lazy var editFab: MDCFloatingButton = {
        let fab = MDCFloatingButton(shape: .mini);
        fab.accessibilityLabel = field[FieldKey.name.key] as? String;
        fab.setImage(UIImage(named: "edit")?.withRenderingMode(.alwaysTemplate), for: .normal);
        fab.applySecondaryTheme(withScheme: globalContainerScheme());
        fab.addTarget(self, action: #selector(handleTap), for: .touchUpInside);
        return fab;
    }()
    
    lazy var observationManager: MapObservationManager = {
        let observationManager: MapObservationManager = MapObservationManager(mapView: self.mapView, andEventForms: eventForms);
        return observationManager;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, mapEventDelegate: MKMapViewDelegate? = nil) {
        self.init(field: field, delegate: delegate, value: nil, mapEventDelegate: mapEventDelegate);
    }
    
    convenience init(field: [String: Any], delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, observation: Observation?, eventForms: [[String : Any]]?, mapEventDelegate: MKMapViewDelegate? = nil, showFieldName: Bool = false) {
        let accuracy = observation?.properties?["accuracy"] as? Double;
        let provider = observation?.properties?["provider"] as? String;
        self.init(field: field, delegate: delegate, value: observation?.getGeometry(), accuracy: accuracy, provider: provider, mapEventDelegate: mapEventDelegate, observation: observation, eventForms: eventForms, showFieldName: showFieldName);
    }
    
    init(field: [String: Any], delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observation: Observation? = nil, eventForms: [[String : Any]]? = nil, showFieldName: Bool = false) {
        super.init(frame: .zero);
        super.configureForAutoLayout();
        self.field = field;
        self.observation = observation;
        self.eventForms = eventForms;
        self.showFieldName = showFieldName;
        
        mapDelegate.setMapEventDelegte(mapEventDelegate);
        buildView();
        
        setValue(value, accuracy: accuracy, provider: provider);
        if (self.observation == nil) {
            addToMap();
        } else {
            addToMapAsObservation();
        }
        
        if (UserDefaults.standard.bool(forKey: "showMGRS")) {
            fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "") + " (MGRS)";
        } else {
            fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "") + " (Lat, Long)";
        }
        
        if ((field[FieldKey.required.key] as? Bool) == true) {
            fieldNameLabel.text = (fieldNameLabel.text ?? "") + " *"
        }
    }
    
    deinit {
        print("Cleaning up the map delegate");
        self.mapDelegate.cleanup();
    }
    
    func addToMapAsObservation() {
        if (self.observation?.getGeometry() != nil) {
            self.mapObservation = self.observationManager.addToMap(with: self.observation);
            guard let viewRegion = self.mapObservation?.viewRegion(of: self.mapView) else { return };
            self.mapView.setRegion(viewRegion, animated: true);
        }
    }
    
    func addToMap() {
        if (self.value != nil) {
            let shapeConverter: GPKGMapShapeConverter = GPKGMapShapeConverter();
            let shape: GPKGMapShape = shapeConverter.toShape(with: (self.value));
            var options: GPKGMapPointOptions? = nil;
            if ((self.value)?.geometryType != SF_POINT) {
                options = GPKGMapPointOptions();
                options!.image = UIImage();
            }
            
            shapeConverter.add(shape, asPointsTo: self.mapView, with: options, andPolylinePointOptions: options, andPolygonPointOptions: options, andPolygonPointHoleOptions: options, andPolylineOptions: nil, andPolygonOptions: nil);
            setMapRegion();
        }
    }
    
    func setMapRegion() {
        if let centroid = (self.value)?.centroid() {
            var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centroid.y as! CLLocationDegrees, longitude: centroid.x as! CLLocationDegrees), span: MKCoordinateSpan(latitudeDelta: 0.03125, longitudeDelta: 0.03125));
            if (accuracy != nil) {
                let coordinate = CLLocationCoordinate2DMake(centroid.y as! CLLocationDegrees, centroid.x as! CLLocationDegrees);
                region = MKCoordinateRegion(center: coordinate, latitudinalMeters: (accuracy ?? 1000) * 2.5, longitudinalMeters: (accuracy ?? 1000) * 2.5);
            }
            
            let viewRegion = self.mapView.regionThatFits(region);
            self.mapView.setRegion(viewRegion, animated: false);
        }
    }
    
    func buildView() {
        let wrapper = UIView(forAutoLayout: ());
        self.addSubview(wrapper);
        wrapper.autoPinEdgesToSuperviewEdges();
        
        wrapper.addSubview(mapView);
        mapView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: showFieldName ? 16 : 0, left: 0, bottom: 0, right: 0), excludingEdge: .bottom);
        
//        wrapper.addSubview(editFab);
//        editFab.autoPinEdge(.bottom, to: .bottom, of: mapView, withOffset: -16);
//        editFab.autoPinEdge(.right, to: .right, of: mapView, withOffset: -16)
        
        if (showFieldName) {
            wrapper.addSubview(fieldNameLabel);
            fieldNameLabel.autoPinEdge(toSuperviewEdge: .top);
            fieldNameLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
        }
        
        wrapper.addSubview(latitudeLongitudeButton);
        latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left);
        latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8);
        latitudeLongitudeButton.autoPinEdge(.top, to: .bottom, of: mapView, withOffset: 8);
        
        wrapper.addSubview(accuracyLabel);
        accuracyLabel.autoPinEdge(.left, to: .right, of: latitudeLongitudeButton);
        accuracyLabel.autoPinEdge(.top, to: .top, of: latitudeLongitudeButton);
        accuracyLabel.autoMatch(.height, to: .height, of: latitudeLongitudeButton);
        
        mapDelegate.ensureMapLayout();
    }
    
//    override func isEmpty() -> Bool{
//        return self.value == nil;
//    }
    
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
                
                accuracyLabel.text = String(format: "%@ ± %.02fm", formattedProvider, accuracy!);
                if let centroid = (self.value)!.centroid() {
                    let overlay = ObservationAccuracy(center: CLLocationCoordinate2D(latitude: centroid.y as! CLLocationDegrees, longitude: centroid.x as! CLLocationDegrees), radius: self.accuracy ?? 0)
                    self.mapView.addOverlay(overlay);
                }
            }
        }
    }
    
    func setValue(_ value: Any) {
        self.setValue(value as? SFGeometry);
    }
    
    func setValue(_ value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil) {
        self.value = value;
        if (value != nil) {
            if let point: SFPoint = (self.value)!.centroid() {
                if (UserDefaults.standard.bool(forKey: "showMGRS")) {
                    latitudeLongitudeButton.setTitle(MGRS.mgrSfromCoordinate(CLLocationCoordinate2D.init(latitude: point.y as! CLLocationDegrees, longitude: point.x as! CLLocationDegrees)), for: .normal);
                } else {
                    latitudeLongitudeButton.setTitle(String(format: "%.5f, %.5f", point.y.doubleValue, point.x.doubleValue), for: .normal);
                }
                latitudeLongitudeButton.sizeToFit();
            }
            setAccuracy(accuracy, provider: provider);
            addToMap();
        } else {
            latitudeLongitudeButton.setTitle("No Location Set", for: .normal);
        }
    }
    
    @objc func handleTap() {
//        fieldSelectionCoordinator?.fieldSelected();
    }
}
