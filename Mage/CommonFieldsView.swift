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
    var observation: Observation;
    var eventForms: [[String:Any]]?;
    
    lazy var dateField: [String: Any] = {
        let dateField: [String: Any] =
            [FieldKey.title.key: "Date",
             FieldKey.required.key: true,
             FieldKey.name.key: "timestamp"
        ];
        return dateField;
    }()
    
    lazy var locationField: [String: Any] = {
        let locationField: [String: Any] =
            [FieldKey.title.key: "Location",
             FieldKey.required.key: true,
             FieldKey.name.key: "geometry"
        ];
        return locationField;
    }()
    
    lazy var dateView: EditDateView = {
        let dateView = EditDateView(field: dateField);
        return dateView;
    }()
    
    lazy var geometryView: EditGeometryView = {
        let geometryView = EditGeometryView(field: locationField, observation: observation, eventForms: eventForms);
        return geometryView;
    }()
    
    init(observation: Observation) {
        self.observation = observation;
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        buildView();
    }

    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func buildView() {
        let wrapper = UIView(forAutoLayout: ());
        self.addSubview(wrapper);
        wrapper.autoPinEdgesToSuperviewEdges();
        wrapper.addSubview(dateView);
        dateView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 8, bottom: 0, right: 8), excludingEdge: .bottom);
        wrapper.addSubview(geometryView);
        geometryView.autoPinEdge(.top, to: .bottom, of: dateView);
        geometryView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8), excludingEdge: .top);
        
        if let observationProperties: NSDictionary = observation.properties as? NSDictionary {
            dateView.setValue(observationProperties.object(forKey: dateField[FieldKey.name.key] as! String) as? String);
        }
    }
}
