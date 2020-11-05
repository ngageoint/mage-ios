//
//  EditGeometryView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;
import MaterialComponents.MDCButton;

extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}

class EditGeometryView : BaseFieldView {
    private var accuracy: Double?;
    private var provider: String?;
    private var mapEventDelegate: MKMapViewDelegate?;
    
    private var mapDelegate: MapDelegate = MapDelegate();
    private var observation: Observation?;
    private var eventForms: [[String: Any]]?;
    
    private var mapObservation: MapObservation?;
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        controller.textInput = textField;
        return textField;
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
        mapView.autoSetDimension(.height, toSize: 95);
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
        fab.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside);
        return fab;
    }()
    
    lazy var observationManager: MapObservationManager = {
        let observationManager: MapObservationManager = MapObservationManager(mapView: self.mapView, andEventForms: eventForms);
        return observationManager;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil, mapEventDelegate: MKMapViewDelegate? = nil) {
        self.init(field: field, delegate: delegate, value: nil, mapEventDelegate: mapEventDelegate);
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil, observation: Observation?, eventForms: [[String : Any]]?, mapEventDelegate: MKMapViewDelegate? = nil) {
        let accuracy = ((observation?.properties as? NSDictionary)?.value(forKey: "accuracy") as? Double);
        let provider = ((observation?.properties as? NSDictionary)?.value(forKey: "provider") as? String);
        self.init(field: field, delegate: delegate, value: observation?.getGeometry(), accuracy: accuracy, provider: provider, mapEventDelegate: mapEventDelegate, observation: observation, eventForms: eventForms);
    }
    
    init(field: [String: Any], delegate: ObservationEditListener? = nil, value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observation: Observation? = nil, eventForms: [[String : Any]]? = nil) {
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
            fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "") + " (MGRS)";
        } else {
            fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "") + " (Lat, Long)";
        }
        
        if ((field[FieldKey.required.key] as? Bool) == true) {
            fieldNameLabel.text = (fieldNameLabel.text ?? "") + " *"
        }
    }
    
    deinit {
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
    
    override func setupController() {
        if (UserDefaults.standard.bool(forKey: "showMGRS")) {
            controller.placeholderText = (field[FieldKey.title.key] as? String ?? "") + " (MGRS)";
        } else {
            controller.placeholderText = (field[FieldKey.title.key] as? String ?? "") + " (Lat, Long)";
        }
        
        if ((field[FieldKey.required.key] as? Bool) == true) {
            controller.placeholderText = (controller.placeholderText ?? "") + " *"
        }
    }
    
    func buildView() {
        let wrapper = UIView(forAutoLayout: ());
        self.addSubview(wrapper);
        wrapper.autoPinEdgesToSuperviewEdges();
        
        wrapper.addSubview(mapView);
        mapView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0), excludingEdge: .bottom);
        
        wrapper.addSubview(editFab);
        editFab.autoPinEdge(.bottom, to: .bottom, of: mapView, withOffset: -16);
        editFab.autoPinEdge(.right, to: .right, of: mapView, withOffset: -16)
        
        wrapper.addSubview(fieldNameLabel);
        fieldNameLabel.autoPinEdge(toSuperviewEdge: .top);
        fieldNameLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
        
        wrapper.addSubview(latitudeLongitudeButton);
        latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left);
        latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .bottom);
        latitudeLongitudeButton.autoPinEdge(.top, to: .bottom, of: mapView, withOffset: 8);
        
        wrapper.addSubview(accuracyLabel);
        accuracyLabel.autoPinEdge(.left, to: .right, of: latitudeLongitudeButton);
        accuracyLabel.autoPinEdge(.top, to: .top, of: latitudeLongitudeButton);
        accuracyLabel.autoMatch(.height, to: .height, of: latitudeLongitudeButton);
        
        mapDelegate.ensureMapLayout();
    }
    
    override func isEmpty() -> Bool{
        return self.value == nil;
    }
    
    @objc func editButtonTapped() {
        delegate?.fieldSelected?(field);
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
    
    func setValue(_ value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil) {
        self.value = value;
        if (value != nil) {
            if let point: SFPoint = (self.value as? SFGeometry)!.centroid() {
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
    
    override func setValid(_ valid: Bool) {
        if (valid) {
            latitudeLongitudeButton.applyTextTheme(withScheme: globalContainerScheme());
            fieldNameLabel.textColor = .systemGray;
        } else {
            latitudeLongitudeButton.applyTextTheme(withScheme: globalErrorContainerScheme());
            fieldNameLabel.textColor = .systemRed;
        }
    }
}
