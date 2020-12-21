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
    containerScheme.colorScheme.primaryColor = MDCPalette.blue.tint600;// UIColor(named: "primary") ?? .systemFill;
    containerScheme.colorScheme.secondaryColor = MDCPalette.orange.accent400 ?? .label;// UIColor(named: "secondary") ?? .label;
    containerScheme.colorScheme.onSecondaryColor = UIColor.label;
    return containerScheme;
}

func globalErrorContainerScheme() -> MDCContainerScheming {
    let containerScheme = MDCContainerScheme();
    containerScheme.colorScheme.primaryColor = .systemRed;
    return containerScheme;
}
