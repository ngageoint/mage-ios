//
//  DefaultTypographyScheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

@objc public final class DefaultTypographyScheme: NSObject, AppTypographyScheming {
    public let headlineFont: UIFont = UIFont.preferredFont(forTextStyle: .headline)
    public let bodyFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    public let buttonFont: UIFont = UIFont.preferredFont(forTextStyle: .callout)
}
