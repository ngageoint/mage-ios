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
import MapFramework

class GeometryView : BaseFieldView {
    private var accuracy: Double?;
    private var provider: String?;
    private weak var observationActionsDelegate: ObservationActionsDelegate?;
    private weak var observation: Observation?;
    var mapItemsTappedObserver: Any?
    var mapItemCount: Int = 1
    var currentMapItem: Int = 1

    lazy var textField: MDCFilledTextField = {
        // this is just an estimated size
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 300, height: 100));
        textField.label.text = fieldNameLabel.text
        textField.trailingView = UIImageView(image: UIImage(named: "outline_place"));
        textField.trailingViewMode = .always;
        textField.sizeToFit()
        return textField;
    }()
    
    lazy var latitudeLongitudeButton: LatitudeLongitudeButton = LatitudeLongitudeButton()
    
    lazy var accuracyLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        return label;
    }()
    
    lazy var mapView: SingleFeatureMapView = {
        let mapView = SingleFeatureMapView(observation: nil, scheme: scheme)
        mapView.autoSetDimension(.height, toSize: editMode ? 150 : 200);

        mapItemsTappedObserver = NotificationCenter.default.addObserver(forName: .MapItemsTapped, object: nil, queue: .main) { [weak self] notification in
            if let mapView = mapView.mapView,
               let notification = notification.object as? MapItemsTappedNotification,
               notification.mapView == mapView
            {
                print("XXX map item clicked annotations \(notification.annotations) items \(notification.items)")
            }
        }

        return mapView;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        self.scheme = scheme
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        accuracyLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        accuracyLabel.font = scheme.typographyScheme.caption;
        latitudeLongitudeButton.applyTheme(withScheme: scheme);
        textField.applyTheme(withScheme: scheme);
        textField.trailingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        mapView.applyTheme(scheme: scheme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil, mkmapDelegate: MKMapViewDelegate? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil, mapEventDelegate: mapEventDelegate, observationActionsDelegate: observationActionsDelegate, mkmapDelegate: mkmapDelegate);
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, observation: Observation?, mapEventDelegate: MKMapViewDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil, mkmapDelegate: MKMapViewDelegate? = nil) {
        let accuracy = (observation?.properties?["accuracy"]) as? Double;
        let provider = (observation?.properties?["provider"]) as? String;
        self.init(field: field, editMode: editMode, delegate: delegate, value: observation?.geometry, accuracy: accuracy, provider: provider, mapEventDelegate: mapEventDelegate, observation: observation, observationActionsDelegate: observationActionsDelegate, mkmapDelegate: mkmapDelegate);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: SFGeometry?, accuracy: Double? = nil, provider: String? = nil, mapEventDelegate: MKMapViewDelegate? = nil, observation: Observation? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil, mkmapDelegate: MKMapViewDelegate? = nil) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        if (field[FieldKey.title.key] != nil) {
            fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "");
            
            if ((field[FieldKey.required.key] as? Bool) == true) {
                fieldNameLabel.text = (fieldNameLabel.text ?? "") + " *"
            }
        }
        
        buildView();
        setValue(value, accuracy: accuracy, provider: provider);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            if (editMode) {
                
            } else {
                latitudeLongitudeButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0), excludingEdge: .right);
                accuracyLabel.autoPinEdge(.left, to: .right, of: latitudeLongitudeButton);
                accuracyLabel.autoPinEdge(.top, to: .top, of: latitudeLongitudeButton);
                accuracyLabel.autoMatch(.height, to: .height, of: latitudeLongitudeButton);
            }
        }
        super.updateConstraints();
    }

    func setObservation(observation: Observation) {
        self.observation = observation;
        let accuracy = (observation.properties?["accuracy"]) as? Double;
        let provider = (observation.properties?["provider"]) as? String;
     
        setValue(observation.geometry, accuracy: accuracy, provider: provider);
        addToMapAsObservation();
    }
    
    func addToMapAsObservation() {
        if let locations = observation?.locations, locations.count != 0 {
            mapItemCount = locations.count
            currentMapItem = 0
            mapView.observation = self.observation
        }
    }
    
    func addToMap() {
        if let sfGeometry = self.value as? SFGeometry {
            mapView.sfgeometry = sfGeometry
        }
    }
    
    func buildView() {
        if (editMode) {
            viewStack.spacing = 0;
            viewStack.addArrangedSubview(textField);
            viewStack.addArrangedSubview(mapView);
            let spacer = UIView(forAutoLayout: ());
            spacer.autoSetDimension(.height, toSize: 24);
            viewStack.addArrangedSubview(spacer);
            
            let tapView = addTapRecognizer();
            tapView.accessibilityLabel = field[FieldKey.name.key] as? String;
            textField.accessibilityLabel = "\(field[FieldKey.name.key] as? String ?? "") value"
        } else {
        
            if (field[FieldKey.title.key] != nil) {
                viewStack.addArrangedSubview(fieldNameLabel);
                viewStack.setCustomSpacing(4, after: fieldNameLabel);
            }
            viewStack.addArrangedSubview(mapView);

            let wrapper = UIView(forAutoLayout: ());
            wrapper.addSubview(latitudeLongitudeButton);
            wrapper.addSubview(accuracyLabel);
            viewStack.addArrangedSubview(wrapper);
        }
    }
    
    override func isEmpty() -> Bool{
        return self.value == nil;
    }
    
    func setAccuracy(_ accuracy: Double?, provider: String?) {
        self.accuracy = accuracy;
        self.provider = provider;
        if self.provider == "manual" {
            accuracyLabel.text = "";
            return
        }
        if let accuracy = accuracy, let provider = provider {
            var formattedProvider: String = "";
            if provider == "gps" {
                formattedProvider = provider.uppercased()
            } else {
                formattedProvider = provider.capitalized;
            }
            accuracyLabel.text = String(format: "%@ ± %.02fm", formattedProvider, accuracy);
        }
    }
    
    override func setValue(_ value: Any?) {
        self.setValue(value as? SFGeometry);
    }
    
    func setValue(_ value: SFGeometry?, accuracy: Double? = nil, provider: String? = "manual") {
        self.value = value;
        if (value != nil) {
            latitudeLongitudeButton.isEnabled = true;
            setAccuracy(accuracy, provider: provider);
//            if (self.observation == nil) {
                addToMap();
//            } else {
//                self.observation?.geometry = value;
//                addToMapAsObservation();
//            }
            
            if let point: SFPoint = (self.value as? SFGeometry)!.centroid() {
                let coordinate = CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
                latitudeLongitudeButton.coordinate = coordinate
                if (editMode) {
                    textField.text = "\(latitudeLongitudeButton.title(for: .normal) ?? "") \(accuracyLabel.text ?? "")"
                }
                mapView.isHidden = false;
                
            }
        } else {
            if (editMode) {
                textField.text = ""
            }
            latitudeLongitudeButton.coordinate = nil
            mapView.isHidden = true;
        }
    }
    
    override func setValid(_ valid: Bool) {
        if let scheme = scheme {
            if (valid) {
                textField.applyTheme(withScheme: scheme);
                textField.leadingAssistiveLabel.text = nil
                textField.sizeToFit()
                applyTheme(withScheme: scheme);
            } else {
                textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
                textField.leadingAssistiveLabel.text = "\(field[FieldKey.title.key] as? String ?? "") is required"
                textField.sizeToFit()
                latitudeLongitudeButton.applyTheme(withScheme: globalErrorContainerScheme());
                fieldNameLabel.textColor = scheme.colorScheme.errorColor;
            }
        }
    }
}
