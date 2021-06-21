//
//  ViewLoader.swift
//  MAGE
//
//  Created by Daniel Barela on 6/11/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc class ViewLoader: NSObject {

    @objc static func createRootViewController() -> UIViewController {
        class MockGeometryEditCoordinator : GeometryEditCoordinator {
            var _currentGeometry: SFGeometry! = SFPoint(x: 1.0, andY: 1.0);
            var _fieldName: String! = "Field Name"
            var _pinImage: UIImage! = UIImage(named: "observations")

            override func start() {

            }

            override func update(_ geometry: SFGeometry!) {
                _currentGeometry = geometry;
            }

            override var currentGeometry: SFGeometry! {
                get {
                    return _currentGeometry
                }
                set {
                    _currentGeometry = newValue
                }
            }

            override var pinImage: UIImage! {
                get {
                    return _pinImage
                }
                set {
                    _pinImage = newValue
                }
            }

            override func fieldName() -> String! {
                return _fieldName
            }

        }
        
        class MockGeometryEditDelegate: GeometryEditDelegate {
            func geometryEditComplete(_ geometry: SFGeometry!, fieldDefintion field: [AnyHashable : Any]!, coordinator: Any!, wasValueChanged changed: Bool) {
                
            }
            
            func geometryEditCancel(_ coordinator: Any!) {
                
            }
            
            
        }
        
        let delegate = MockGeometryEditDelegate();

        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        let field: [String: AnyHashable] = [
            "title": "Field Title",
            "name": "field8",
            "type": "geometry",
            "id": 8
        ];

        let mockGeometryEditCoordinator = MockGeometryEditCoordinator();
        mockGeometryEditCoordinator._fieldName = "Field";
        mockGeometryEditCoordinator.currentGeometry = point;
        
        let coordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: nil, andPinImage: UIImage(named: "marker"), andDelegate: delegate, andNavigationController: nil, scheme: MAGEScheme.scheme())
    
        return UINavigationController(rootViewController: (coordinator?.createViewController())!);
    }
}
