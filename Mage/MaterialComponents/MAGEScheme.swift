//
//  MAGEScheme.swift
//  MAGE
//
//  Created by Daniel Barela on 10/20/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents
import UIKit

func applicationAppearance(scheme: MDCContainerScheming?) {
    guard let scheme = scheme else {
        return
    }

    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground();
    appearance.backgroundColor = scheme.colorScheme.primaryColorVariant;
    appearance.titleTextAttributes = [
        NSAttributedString.Key.foregroundColor: scheme.colorScheme.onSecondaryColor,
        NSAttributedString.Key.backgroundColor: scheme.colorScheme.primaryColorVariant
    ];
    appearance.largeTitleTextAttributes = [
        NSAttributedString.Key.foregroundColor: scheme.colorScheme.onSecondaryColor,
        NSAttributedString.Key.backgroundColor: scheme.colorScheme.primaryColorVariant
    ];
    
    UINavigationBar.appearance().barTintColor = scheme.colorScheme.primaryColorVariant;
    UINavigationBar.appearance().isTranslucent = false;
    UINavigationBar.appearance().tintColor = scheme.colorScheme.onSecondaryColor;
    
    UINavigationBar.appearance().standardAppearance = appearance;
    UINavigationBar.appearance().scrollEdgeAppearance = appearance;
    UINavigationBar.appearance().compactAppearance = appearance;
    if #available(iOS 15.0, *) {
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
    
    let tabBarAppearance = UITabBarAppearance();
    tabBarAppearance.selectionIndicatorTintColor = scheme.colorScheme.primaryColor.withAlphaComponent(0.87)
    tabBarAppearance.backgroundColor = scheme.colorScheme.surfaceColor
    setTabBarItemColors(tabBarAppearance.stackedLayoutAppearance, scheme: scheme)
    setTabBarItemColors(tabBarAppearance.inlineLayoutAppearance, scheme: scheme)
    setTabBarItemColors(tabBarAppearance.compactInlineLayoutAppearance, scheme: scheme)
    
    UITabBar.appearance().standardAppearance = tabBarAppearance;
    if #available(iOS 15.0, *) {
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance, scheme: MDCContainerScheming) {
    itemAppearance.normal.iconColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
    itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)]
    
    itemAppearance.selected.iconColor = scheme.colorScheme.primaryColor.withAlphaComponent(0.87)
    itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: scheme.colorScheme.primaryColor.withAlphaComponent(0.87)]
}

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
    containerScheme.colorScheme.onPrimaryColor = UIColor(named: "onPrimary") ?? .white;
    
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
    @objc class func setupApplicationAppearance(scheme : MDCContainerScheming?) { return applicationAppearance(scheme: scheme) }
}

// This is for access in Objective-c land
@objc class MAGEErrorScheme: NSObject {
    @objc class func scheme() -> MDCContainerScheming { return globalErrorContainerScheme() }
}
