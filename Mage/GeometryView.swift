//
//  GeometryView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;
import MaterialComponents.MDCButton;

class GeometryView : BaseFieldView {
    private var accuracy: Double?;
    private var provider: String?;
    private var mapEventDelegate: MKMapViewDelegate?;
    private var observationActionsDelegate: ObservationActionsDelegate?;
    private var observation: Observation?;
    private var eventForms: [[String: Any]]?;
    
    private var mapObservation: MapObservation?;
    
    private lazy var mapDelegate: MapDelegate = {
        return MapDelegate();
    }()
    
    private lazy var latitudeLongitudeButton: MDCButton = {
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = "location";
        button.setImage(UIImage(named: "location_tracking_on")?.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5);
        button.addTarget(self, action: #selector(locationTapped), for: .touchUpInside);
        return button;
    }()
    
    private lazy var accuracyLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        return label;
    }()
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.mapType = .standard;
        mapView.autoSetDimension(.height, toSize: editMode ? 95 : 200);
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
        fab.addTarget(self, action: #selector(handleTap), for: .touchUpInside);
        return fab;
    }()
    
    lazy var observationManager: MapObservationManager = {
        let observationManager: MapObservationManager = MapObservationManager(mapView: self.mapView, andEventForms: eventForms);
        return observationManager;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        accuracyLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        accuracyLabel.font = scheme.typographyScheme.caption;
        editFab.applySecondaryTheme(withScheme: scheme);
        latitudeLongitudeButton.applyTextTheme(withScheme: scheme);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil, mapEventDelegate: mapEventDelegate, observationActionsDelegate: observationActionsDelegate);
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, observation: Observation?, eventForms: [[String : Any]]?, mapEventDelegate: MKMapViewDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil) {
        let accuracy = (observation?.properties?["accuracy"]) as? Double;
        let provider = (observation?.properties?["provider"]) as? String;
        self.init(field: field, editMode: editMode, delegate: delegate, value: observation?.getGeometry(), accuracy: accuracy, provider: provider, mapEventDelegate: mapEventDelegate, observation: observation, eventForms: eventForms, observationActionsDelegate: observationActionsDelegate);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observation: Observation? = nil, eventForms: [[String : Any]]? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.observation = observation;
        self.eventForms = eventForms;
        self.observationActionsDelegate = observationActionsDelegate;
        mapDelegate.setMapEventDelegte(mapEventDelegate);
        buildView();
        
        setValue(value, accuracy: accuracy, provider: provider);
        if (self.observation == nil) {
            addToMap();
        } else {
            addToMapAsObservation();
        }
        
        if (field[FieldKey.title.key] != nil) {
            if (UserDefaults.standard.showMGRS) {
                fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "") + " (MGRS)";
            } else {
                fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "") + " (Lat, Long)";
            }
            
            if ((field[FieldKey.required.key] as? Bool) == true) {
                fieldNameLabel.text = (fieldNameLabel.text ?? "") + " *"
            }
        }
    }
    
    deinit {
        print("Cleaning up the map delegate");
        self.mapDelegate.cleanup();
    }
    
    @objc func locationTapped() {
        observationActionsDelegate?.copyLocation?(latitudeLongitudeButton.currentTitle ?? "");
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
        if (field[FieldKey.title.key] != nil) {
            if (editMode) {
                viewStack.addArrangedSubview(fieldNameSpacerView);
                viewStack.setCustomSpacing(0, after: fieldNameSpacerView);
            } else {
                viewStack.addArrangedSubview(fieldNameLabel);
                viewStack.setCustomSpacing(4, after: fieldNameLabel);
            }
        }
        viewStack.addArrangedSubview(mapView);
        
        if (editMode) {
            self.addSubview(editFab);
            editFab.autoPinEdge(.bottom, to: .bottom, of: mapView, withOffset: -16);
            editFab.autoPinEdge(.right, to: .right, of: mapView, withOffset: -16)
        }
        
        let wrapper = UIView(forAutoLayout: ());
        wrapper.addSubview(latitudeLongitudeButton);
        latitudeLongitudeButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0), excludingEdge: .right);
        
        wrapper.addSubview(accuracyLabel);
        accuracyLabel.autoPinEdge(.left, to: .right, of: latitudeLongitudeButton);
        accuracyLabel.autoPinEdge(.top, to: .top, of: latitudeLongitudeButton);
        accuracyLabel.autoMatch(.height, to: .height, of: latitudeLongitudeButton);
        
        viewStack.addArrangedSubview(wrapper);
        
        mapDelegate.ensureMapLayout();
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
                
                accuracyLabel.text = String(format: "%@ ± %.02fm", formattedProvider, accuracy!);
                if let centroid = (self.value as? SFGeometry)!.centroid() {
                    let overlay = ObservationAccuracy(center: CLLocationCoordinate2D(latitude: centroid.y as! CLLocationDegrees, longitude: centroid.x as! CLLocationDegrees), radius: self.accuracy ?? 0)
                        self.mapView.addOverlay(overlay);
                }
            }
        }
    }
    
    override func setValue(_ value: Any) {
        self.setValue(value as? SFGeometry);
    }
    
    func setValue(_ value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil) {
        self.value = value;
        if (value != nil) {
            if let point: SFPoint = (self.value as? SFGeometry)!.centroid() {
                if (UserDefaults.standard.showMGRS) {
                    latitudeLongitudeButton.setTitle(MGRS.mgrSfromCoordinate(CLLocationCoordinate2D.init(latitude: point.y as! CLLocationDegrees, longitude: point.x as! CLLocationDegrees)), for: .normal);
                } else {
                    latitudeLongitudeButton.setTitle(String(format: "%.5f, %.5f", point.y.doubleValue, point.x.doubleValue), for: .normal);
                }
            }
            setAccuracy(accuracy, provider: provider);
            addToMap();
        } else {
            latitudeLongitudeButton.setTitle("No Location Set", for: .normal);
        }
    }
    
    override func setValid(_ valid: Bool) {
        if let safeScheme = scheme {
            if (valid) {
                applyTheme(withScheme: safeScheme);
            } else {
                latitudeLongitudeButton.applyTextTheme(withScheme: globalErrorContainerScheme());
                fieldNameLabel.textColor = safeScheme.colorScheme.errorColor;
            }
        }
    }
}
