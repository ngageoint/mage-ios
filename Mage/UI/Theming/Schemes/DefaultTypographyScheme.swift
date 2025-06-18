//
//  DefaultTypographyScheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

@objc public final class DefaultTypographyScheme: NSObject, AppTypographyScheming {
    public var headline1Font: UIFont!
    
    public var headline2Font: UIFont!
    
    public var headline3Font: UIFont!
    
    public var headline4Font: UIFont!
    
    public var headline5Font: UIFont!
    
    public var headline6Font: UIFont!
    
    public var subtitle1Font: UIFont!
    
    public var subtitle2Font: UIFont!
    
    public var captionFont: UIFont!
    
    public let headlineFont: UIFont = UIFont.preferredFont(forTextStyle: .headline)
    public let bodyFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    public let buttonFont: UIFont = UIFont.preferredFont(forTextStyle: .callout)
}
