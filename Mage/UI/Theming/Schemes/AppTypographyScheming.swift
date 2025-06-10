//
//  AppTypographyScheming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public protocol AppTypographyScheming: AnyObject {
    var headline1Font: UIFont { get }
    var headline2Font: UIFont { get }
    var headline3Font: UIFont { get }
    var headline4Font: UIFont { get }
    var headline5Font: UIFont { get }
    var headline6Font: UIFont { get }
    
    var subtitle1Font: UIFont { get }
    var subtitle2Font: UIFont { get }

    var bodyFont: UIFont { get }
    var buttonFont: UIFont { get }
    var captionFont: UIFont { get }
}
