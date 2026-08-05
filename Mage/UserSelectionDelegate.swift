//
//  UserSelectionDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 8/5/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


import Foundation
import MapKit
import Persistence

public protocol UserSelectionDelegate: AnyObject {
    func selectedUser(_ user: User)

    func selectedUser(
        _ user: User,
        region: MKCoordinateRegion
    )

    func userDetailSelected(_ user: User)
}
