//
//  ImageryLayer+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/1/19.
//  Copyright © 2019 National Geospatial-Intelligence Agency. All rights reserved.
//
//

import Foundation
import CoreData
import Layer
import Persistence

extension ImageryLayer {
    @objc public override func populate(_ json: [AnyHashable : Any], eventId: NSNumber) {
        super.populate(json, eventId: eventId)
        self.format = json[LayerKey.format.key] as? String
        self.options = json[LayerKey.wms.key] as? [AnyHashable : Any]
        self.isSecure = self.url?.hasPrefix("https") ?? false
    }
}
