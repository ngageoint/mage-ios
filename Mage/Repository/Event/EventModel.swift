//
//  EventModel.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct EventModel {
    var remoteId: NSNumber?
    var acl: [AnyHashable: Any]?
}

extension EventModel {
    init(event: Event) {
        remoteId = event.remoteId
        acl = event.acl
    }
}
