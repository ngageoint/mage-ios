//
//  MAGEScheme.swift
//  MAGE
//
//  Created by Daniel Barela on 10/20/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents

func globalContainerScheme() -> MDCContainerScheming {
    let containerScheme = MDCContainerScheme();
    // this will be used for the navbar
    containerScheme.colorScheme.primaryColorVariant = UIColor(named: "primaryVariant") ?? MDCPalette.blue.tint600;
    containerScheme.colorScheme.primaryColor = UIColor(named: "primary") ?? MDCPalette.blue.tint600;
    containerScheme.colorScheme.secondaryColor = UIColor(named: "secondary") ?? (MDCPalette.orange.accent700 ?? .systemFill);
    containerScheme.colorScheme.onSecondaryColor = UIColor(named: "onSecondary") ?? .label;
    containerScheme.colorScheme.surfaceColor = UIColor(named: "surface") ?? UIColor.systemBackground;
    containerScheme.colorScheme.onSurfaceColor = UIColor.label;
    containerScheme.colorScheme.backgroundColor = UIColor.systemGroupedBackground;
    containerScheme.colorScheme.onBackgroundColor = UIColor.label;
    containerScheme.colorScheme.errorColor = .systemRed;
    containerScheme.colorScheme.onPrimaryColor = .white;
    
    return containerScheme;
}

func globalErrorContainerScheme() -> MDCContainerScheming {
    let containerScheme = MDCContainerScheme();
    containerScheme.colorScheme.primaryColorVariant = .systemRed;
    containerScheme.colorScheme.primaryColor = .systemRed;
    containerScheme.colorScheme.secondaryColor = .systemRed;
    containerScheme.colorScheme.onSecondaryColor = .white;
    containerScheme.colorScheme.surfaceColor = UIColor(named: "surface") ?? UIColor.systemBackground;
    containerScheme.colorScheme.onSurfaceColor = UIColor.label;
    containerScheme.colorScheme.backgroundColor = UIColor.systemGroupedBackground;
    containerScheme.colorScheme.onBackgroundColor = UIColor.label;
    containerScheme.colorScheme.errorColor = .systemRed;
    containerScheme.colorScheme.onPrimaryColor = .white;
    return containerScheme;
}

func globalDisabledScheme() -> MDCContainerScheming {
    let containerScheme = MDCContainerScheme();
    containerScheme.colorScheme.primaryColorVariant = MDCPalette.grey.tint300;
    containerScheme.colorScheme.primaryColor = MDCPalette.grey.tint300;
    containerScheme.colorScheme.secondaryColor = MDCPalette.grey.tint300;
    containerScheme.colorScheme.onSecondaryColor = MDCPalette.grey.tint500;
    containerScheme.colorScheme.surfaceColor = MDCPalette.grey.tint300;
    containerScheme.colorScheme.onSurfaceColor = MDCPalette.grey.tint500;
    containerScheme.colorScheme.backgroundColor = MDCPalette.grey.tint300;
    containerScheme.colorScheme.onBackgroundColor = MDCPalette.grey.tint500;
    containerScheme.colorScheme.errorColor = .systemRed;
    containerScheme.colorScheme.onPrimaryColor = MDCPalette.grey.tint500;
    
    return containerScheme;
}

// This is for access in Objective-c land
@objc class MAGEScheme: NSObject {
    @objc class func scheme() -> MDCContainerScheming { return globalContainerScheme() }
}

// This is for access in Objective-c land
@objc class MAGEErrorScheme: NSObject {
    @objc class func scheme() -> MDCContainerScheming { return globalErrorContainerScheme() }
}
