//
//  MAGEScheme.swift
//  MAGE
//
//  Created by Daniel Barela on 10/20/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

func applicationAppearance(scheme: AppContainerScheming?) {
    guard let scheme = scheme else {
        return
    }
    
    let color = scheme.colorScheme
    let primary = color.color(\.primaryColor, fallback: .systemBlue)
    let onPrimary = color.color(\.onPrimaryColor, fallback: .white)
    let surface = color.color(\.surfaceColor, fallback: .systemBackground)
    let onSurface = color.color(\.onSurfaceColor, fallback: .label)

    let tableViewCellAppearance = UITableViewCell.appearance()
    tableViewCellAppearance.tintColor = color.color(\.primaryColorVariant, fallback: .systemBlue)

    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = primary
    
    appearance.titleTextAttributes = [
        .foregroundColor: onPrimary,
        .backgroundColor: primary
    ];
    
    appearance.largeTitleTextAttributes = [
        .foregroundColor: onPrimary,
        .backgroundColor: primary
    ];
    
    UINavigationBar.appearance().standardAppearance = appearance;
    UINavigationBar.appearance().scrollEdgeAppearance = appearance;
    UINavigationBar.appearance().compactAppearance = appearance;
    UINavigationBar.appearance().barTintColor = primary;
    UINavigationBar.appearance().tintColor = onPrimary;
    UINavigationBar.appearance().isTranslucent = false;
    
    if #available(iOS 15.0, *) {
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
    
    // this is used when we browse for a file to attach, even though we really use UIDocumentPickerViewController
    let documentBrowserNavBarAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [UIDocumentBrowserViewController.self])
    documentBrowserNavBarAppearance.isTranslucent = false
    documentBrowserNavBarAppearance.tintColor = onPrimary
    documentBrowserNavBarAppearance.barTintColor = primary
    documentBrowserNavBarAppearance.backgroundColor = primary
    documentBrowserNavBarAppearance.titleTextAttributes = [
        .foregroundColor: onPrimary,
        .backgroundColor: primary
    ];
    documentBrowserNavBarAppearance.largeTitleTextAttributes = [
        .foregroundColor: onPrimary,
        .backgroundColor: primary
    ];
    
    let tabBarAppearance = UITabBarAppearance();
    tabBarAppearance.selectionIndicatorTintColor = primary.withAlphaComponent(0.87)
    tabBarAppearance.backgroundColor = surface
    
    setTabBarItemColors(tabBarAppearance.stackedLayoutAppearance, scheme: scheme)
    setTabBarItemColors(tabBarAppearance.inlineLayoutAppearance, scheme: scheme)
    setTabBarItemColors(tabBarAppearance.compactInlineLayoutAppearance, scheme: scheme)
    
    UITabBar.appearance().standardAppearance = tabBarAppearance;
    if #available(iOS 15.0, *) {
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance, scheme: AppContainerScheming) {
    let color = scheme.colorScheme
    let primary = color.color(\.primaryColor, fallback: .systemBlue)
    let onPrimary = color.color(\.onPrimaryColor, fallback: .white)
    let surface = color.color(\.surfaceColor, fallback: .systemBackground)
    let onSurface = color.color(\.onSurfaceColor, fallback: .label)

    itemAppearance.normal.iconColor = onSurface.withAlphaComponent(0.6);
    itemAppearance.normal.titleTextAttributes = [.foregroundColor: onSurface.withAlphaComponent(0.6)]
    
    itemAppearance.selected.iconColor = primary.withAlphaComponent(0.87)
    itemAppearance.selected.titleTextAttributes = [.foregroundColor: primary.withAlphaComponent(0.87)]
}

func globalContainerScheme() -> AppContainerScheming {
    return NamedColorTheme()
}

func globalErrorContainerScheme() -> AppContainerScheming {
    return ErrorColorTheme()
}

func globalDisabledScheme() -> AppContainerScheming {
    return DisabledColorTheme()
}

// This is for access in Objective-c land
@objc class MAGEScheme: NSObject {
    @objc class func scheme() -> AppContainerScheming { return globalContainerScheme() }
    @objc class func setupApplicationAppearance(scheme : AppContainerScheming?) { return applicationAppearance(scheme: scheme) }
}

// This is for access in Objective-c land
@objc class MAGEErrorScheme: NSObject {
    @objc class func scheme() -> AppContainerScheming { return globalErrorContainerScheme() }
}
