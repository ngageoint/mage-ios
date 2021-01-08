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
    containerScheme.colorScheme.secondaryColor = UIColor(named: "secondary") ?? (MDCPalette.orange.accent400 ?? .systemFill);
    containerScheme.colorScheme.onSecondaryColor = UIColor(named: "onSecondary") ?? .label;
    containerScheme.colorScheme.surfaceColor = UIColor(named: "surface") ?? UIColor.systemBackground;
    containerScheme.colorScheme.onSurfaceColor = UIColor.label;
    containerScheme.colorScheme.backgroundColor = UIColor.systemGroupedBackground;
    containerScheme.colorScheme.errorColor = .systemRed;
    containerScheme.colorScheme.onPrimaryColor = .white;
    
    return containerScheme;
}

func globalErrorContainerScheme() -> MDCContainerScheming {
    let containerScheme = MDCContainerScheme();
    containerScheme.colorScheme.primaryColor = .systemRed;
    return containerScheme;
}

// This is for access in Objective-c land
@objc class MAGEScheme: NSObject {
    @objc class func scheme() -> MDCContainerScheming { return globalContainerScheme() }
}
