//
//  MockGeometryEditDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/16/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MockGeometryEditDelegate: GeometryEditDelegate {
    var geometryEditCompleteCalled = false;
    var geometryEditCancelCalled = false;
    var geometryEditCompleteGeometry: SFGeometry?;
    var geometryEditCompleteFieldDefinition: [AnyHashable : Any]?;
    var geometryEditCompleteWasValueChanged = false;
    
    func geometryEditComplete(_ geometry: SFGeometry!, fieldDefintion field: [AnyHashable : Any]!, coordinator: Any!, wasValueChanged changed: Bool) {
        geometryEditCompleteCalled = true;
        geometryEditCompleteGeometry = geometry;
        geometryEditCompleteFieldDefinition = field;
        geometryEditCompleteWasValueChanged = changed;
    }
    
    func geometryEditCancel(_ coordinator: Any!) {
        geometryEditCancelCalled = true;
    }
}
