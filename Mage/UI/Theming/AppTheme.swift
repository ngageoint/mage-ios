//
//  AppTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public class AppThemeManager: NSObject {
    @objc public static func applyAppearance(with scheme: AppContainerScheming?) {
        guard let colorScheme = scheme?.colorScheme else { return }

        // Table view tint color
        UITableViewCell.appearance().tintColor = colorScheme.primaryColorVariant!

        // UINavigationBar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = colorScheme.primaryColor!
        appearance.titleTextAttributes = [
            .foregroundColor: colorScheme.onPrimaryColor!
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: colorScheme.onPrimaryColor!
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().barTintColor = colorScheme.primaryColor!
        UINavigationBar.appearance().tintColor = colorScheme.onPrimaryColor!
        UINavigationBar.appearance().isTranslucent = false

        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        }

        // UIDocumentBrowserViewController-specific nav appearance
        let docAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [UIDocumentBrowserViewController.self])
        docAppearance.isTranslucent = false
        docAppearance.tintColor = colorScheme.onPrimaryColor!
        docAppearance.barTintColor = colorScheme.primaryColor!
        docAppearance.backgroundColor = colorScheme.primaryColor!
        docAppearance.titleTextAttributes = [.foregroundColor: colorScheme.onPrimaryColor!]
        docAppearance.largeTitleTextAttributes = [.foregroundColor: colorScheme.onPrimaryColor!]

        // UITabBar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.selectionIndicatorTintColor = colorScheme.primaryColorVariant!.withAlphaComponent(0.87)
        tabAppearance.backgroundColor = colorScheme.surfaceColor!

        setTabBarItemColors(tabAppearance.stackedLayoutAppearance, scheme: colorScheme)
        setTabBarItemColors(tabAppearance.inlineLayoutAppearance, scheme: colorScheme)
        setTabBarItemColors(tabAppearance.compactInlineLayoutAppearance, scheme: colorScheme)

        UITabBar.appearance().standardAppearance = tabAppearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
    }

    private static func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance, scheme: AppColorScheming) {
        itemAppearance.normal.iconColor = scheme.onBackgroundColor!.withAlphaComponent(0.6)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: scheme.onBackgroundColor!.withAlphaComponent(0.6)
        ]

        itemAppearance.selected.iconColor = scheme.primaryColorVariant!.withAlphaComponent(0.87)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: scheme.primaryColorVariant!.withAlphaComponent(0.87)
        ]
    }
}
