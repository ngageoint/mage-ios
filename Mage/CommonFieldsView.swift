//
//  CommonFieldsView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/7/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import PureLayout

class CommonFieldsView: MDCCard {
    var didSetupConstraints = false;
    var observation: Observation;
    var eventForms: [[String:Any]]?;
    var fieldSelectionDelegate: FieldSelectionDelegate?;
    
    lazy var dateField: [String: Any] = {
        let dateField: [String: Any] =
            [FieldKey.title.key: "Date",
             FieldKey.required.key: true,
             FieldKey.name.key: "timestamp",
             FieldKey.type.key: "date"
        ];
        return dateField;
    }()
    
    lazy var locationField: [String: Any] = {
        let locationField: [String: Any] =
            [FieldKey.title.key: "Location",
             FieldKey.required.key: true,
             FieldKey.name.key: "geometry",
             FieldKey.type.key: "geometry"
        ];
        return locationField;
    }()
    
    lazy var dateView: DateView = {
        let dateView = DateView(field: dateField, delegate: self);
        return dateView;
    }()
    
    lazy var geometryView: GeometryView = {
        let geometryView = GeometryView(field: locationField, delegate: self, observation: observation, eventForms: eventForms);
        return geometryView;
    }()
    
    init(observation: Observation, fieldSelectionDelegate: FieldSelectionDelegate? = nil) {
        self.observation = observation;
        self.fieldSelectionDelegate = fieldSelectionDelegate;
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        buildView();
    }

    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        geometryView.applyTheme(withScheme: scheme);
        dateView.applyTheme(withScheme: scheme);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            dateView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 8, bottom: 0, right: 8), excludingEdge: .bottom);
            geometryView.autoPinEdge(.top, to: .bottom, of: dateView);
            geometryView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8), excludingEdge: .top);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    func buildView() {
        self.addSubview(dateView);
        self.addSubview(geometryView);
        if let observationProperties: [String : Any] = observation.properties as? [String : Any] {
            dateView.setValue(observationProperties[dateField[FieldKey.name.key] as! String] as? String?);
        }
    }
    
    public func checkValidity() -> Bool {
        let valid = geometryView.isValid() && dateView.isValid();
        geometryView.setValid(geometryView.isValid());
        dateView.setValid(dateView.isValid());
        return valid;
    }
}

extension CommonFieldsView: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
        fieldSelectionDelegate?.launchFieldSelectionViewController(viewController: viewController);
    }
}

extension CommonFieldsView: ObservationFormFieldListener {
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        var newProperties = self.observation.properties as? [String: Any];
        
        if (field[FieldKey.name.key] as! String == dateField[FieldKey.name.key] as! String) {
            let formatter = ISO8601DateFormatter();
            formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
            if (value == nil) {
                newProperties?.removeValue(forKey: dateField[FieldKey.name.key] as! String)
                self.observation.timestamp = nil;
            } else {
                newProperties?[dateField[FieldKey.name.key] as! String] = value as! String;
                self.observation.timestamp = dateView.value as? Date;
            }
        } else if (field[FieldKey.name.key] as! String == locationField[FieldKey.name.key] as! String) {
            self.observation.setGeometry(value as! SFGeometry);
        }
        self.observation.properties = newProperties;
    }
}
