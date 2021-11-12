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

@objc public class ImageryLayer: Layer {
    @objc public override func populate(_ json: [AnyHashable : Any], eventId: NSNumber) {
        self.remoteId = json[LayerKey.id.key] as? NSNumber
        self.name = json[LayerKey.name.key] as? String
        self.layerDescription = json[LayerKey.description.key] as? String
        self.type = json[LayerKey.type.key] as? String
        self.url = json[LayerKey.url.key] as? String
        self.eventId = eventId;
        self.format = json[LayerKey.format.key] as? String
        self.options = json[LayerKey.wms.key] as? [AnyHashable : Any]
        self.isSecure = self.url?.hasPrefix("https") ?? false
    }
}
