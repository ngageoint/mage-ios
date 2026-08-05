//
//  ObservationFavorite+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

import Persistence

extension ObservationFavorite {
    @objc public static func favorite(userId: String, context: NSManagedObjectContext) -> ObservationFavorite? {
        let favorite = ObservationFavorite.mr_createEntity(in: context);
        favorite?.dirty = false
        favorite?.favorite = true;
        favorite?.userId = userId;
        return favorite;
    }
}
