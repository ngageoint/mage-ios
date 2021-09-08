//
//  UserActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol UserActionsDelegate {
    @objc optional func getDirectionsToUser(_ user: User, sourceView: UIView?);
    @objc optional func viewUser(_ user: User);
}
