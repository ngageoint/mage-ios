//
//  MockUIImagePickerController.swift
//  MAGETests
//
//  Created by Daniel Barela on 2/23/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

class MockUIImagePickerController: UIImagePickerController {
    private var _overriddenSourceType: SourceType = .camera;

    override public var sourceType: SourceType {
        get {
            return _overriddenSourceType;
        }
        set {
            self._overriddenSourceType = newValue;
        }
    }

}
