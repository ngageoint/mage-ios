//
//  AppShapeScheming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public protocol AppShapeScheming: AnyObject {
    var cornerRadius: CGFloat { get }
    var borderWidth: CGFloat { get }
}
