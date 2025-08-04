//
//  MAGEStyle.swift
//  MAGE
//
//  Created by Daniel Barela on 6/14/22.
//

import Foundation
import SwiftUI
import QuickLook

public extension Font {
    static var overline: Font {
        return Font.system(size: 12, weight: .medium)
    }
    static var body1: Font {
        return Font.system(size: 16, weight: .regular)
    }
    static var body2: Font {
        return Font.system(size: 14, weight: .regular)
    }
    static var headline1: Font {
        return Font.system(size: 96, weight: .light)
    }
    static var headline2: Font {
        return Font.system(size: 60, weight: .light)
    }
    static var headline3: Font {
        return Font.system(size: 48, weight: .regular)
    }
    static var headline4: Font {
        return Font.system(size: 34, weight: .regular)
    }
    static var headline5: Font {
        return Font.system(size: 24, weight: .regular)
    }
    static var headline6: Font {
        return Font.system(size: 20, weight: .medium)
    }
    static var subtitle1: Font {
        return Font.system(size: 16, weight: .regular)
    }
    static var subtitle2: Font {
        return Font.system(size: 14, weight: .regular)
    }
}

public extension Color {
    static var primaryUIColorVariant: UIColor {
        return UIColor(named: "primaryVariant") ?? .systemBackground
    }

    static var primaryColorVariant: Color {
        return Color("primaryVariant")
    }

    static var primaryUIColor: UIColor {
        return UIColor(named: "primary") ?? .systemBackground
    }

    static var primaryColor: Color {
        return Color("primary")
    }

    static var onPrimaryUIColor: UIColor {
        return UIColor(named: "onPrimary") ?? .label
    }

    static var onPrimaryColor: Color {
        return Color("onPrimary")
    }

    static var mapButtonColor: Color {
        return Color("mapButton")
    }

    static var secondaryUIColor: UIColor {
        return UIColor(named: "secondary") ?? .systemBackground
    }

    static var secondaryColor: Color {
        return Color("secondary")
    }

    static var onSecondaryUIColor: UIColor {
        return UIColor(named: "onSecondary") ?? .secondaryLabel
    }

    static var onSecondaryColor: Color {
        return Color("onSecondary")
    }

    static var surfaceUIColor: UIColor {
        return UIColor(named: "surface") ?? .secondarySystemFill
    }

    static var surfaceColor: Color {
        return Color("surface")
    }

    static var onSurfaceColor: Color {
        return Color(uiColor: UIColor.label)
    }

    static var backgroundUIColor: UIColor {
        return UIColor(named: "background") ?? .systemBackground
    }

    static var backgroundColor: Color {
        return Color("background")
    }
    
    static var gradientDarkBlue: Color {
        return Color("gradientDarkBlue")
    }
    
    static var gradientLightBlue: Color {
        return Color("gradientLightBlue")
    }

    static var onBackgroundUIColor: UIColor {
        return UIColor.label
    }

    static var onBackgroundColor: Color {
        return Color(uiColor: UIColor.label)
    }

    static var errorColor: Color {
        return Color.red
    }

    static var disabledColor: Color {
        return Color(uiColor: UIColor(rgbValue: 0x9E9E9E))
    }

    static var disabledBackground: Color {
        return Color(uiColor: UIColor(argbValue: 0x77FFFFFF))
    }

    static let dynamicOceanColor = UIColor { (traits) -> UIColor in
        // Return one of two colors depending on light or dark mode
        return traits.userInterfaceStyle == .dark ?
        UIColor(red: 0.21, green: 0.27, blue: 0.40, alpha: 1.00) :
        UIColor(red: 0.64, green: 0.87, blue: 0.93, alpha: 1.00)
    }

    static let dynamicLandColor = UIColor { (traits) -> UIColor in
        // Return one of two colors depending on light or dark mode
        return traits.userInterfaceStyle == .dark ?
        UIColor(red: 0.72, green: 0.67, blue: 0.54, alpha: 1.00) :
        UIColor(red: 0.91, green: 0.87, blue: 0.80, alpha: 1.00)
    }

    static var oceanColor: Color {
        return Color(uiColor: dynamicOceanColor)
    }

    static var landColor: Color {
        return Color(uiColor: dynamicLandColor)
    }

    static var ngaGreen: Color {
        return Color(uiColor: UIColor(rgbValue: 0x2999A0))
    }

    static var ngaBlue: Color {
        return Color(uiColor: UIColor(rgbValue: 0x154572))
    }
    
    static var favoriteColor: Color {
        return Color(uiColor: UIColor(rgbValue: 0x00C853))
    }
    
    static var importantColor: Color {
        return Color(uiColor: UIColor(rgbValue: 0xFF9100))
    }

}

public class MAGEStyle: ObservableObject {

    init() {
        setNavigationBarAppearance()
        setTabBarAppearance()
        setPreviewAppearance()
        setDocumentBrowserAppearance()

        UITableView.appearance().backgroundColor = Color.backgroundUIColor

        UITextField.appearance(
            whenContainedInInstancesOf: [UINavigationBar.self]
        ).backgroundColor = Color.backgroundUIColor

        let toolbarAppearance = UIToolbar.appearance(whenContainedInInstancesOf: [QLPreviewController.self])
        toolbarAppearance.tintColor = UIColor.label
    }

    private func setPreviewAppearance() {
        // this is used when we preview a file
        let qlPreviewNavBarAppearance = UINavigationBar.appearance(
            whenContainedInInstancesOf: [QLPreviewController.self]
        )
        qlPreviewNavBarAppearance.isTranslucent = true
        qlPreviewNavBarAppearance.tintColor = UIColor.label
        qlPreviewNavBarAppearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.backgroundColor: Color.primaryUIColor
        ]
        qlPreviewNavBarAppearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.backgroundColor: Color.primaryUIColor
        ]
    }

    private func setDocumentBrowserAppearance() {
        // this is used when we save a file, even though we really use UIDocumentPickerViewController
        let documentBrowserNavBarAppearance = UINavigationBar.appearance(
            whenContainedInInstancesOf: [UIDocumentBrowserViewController.self]
        )
        documentBrowserNavBarAppearance.isTranslucent = false
        documentBrowserNavBarAppearance.tintColor = Color.onPrimaryUIColor
        documentBrowserNavBarAppearance.barTintColor = Color.primaryUIColor
        documentBrowserNavBarAppearance.backgroundColor = Color.primaryUIColor
        documentBrowserNavBarAppearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Color.onPrimaryUIColor,
            NSAttributedString.Key.backgroundColor: Color.primaryUIColor
        ]
        documentBrowserNavBarAppearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Color.onPrimaryUIColor,
            NSAttributedString.Key.backgroundColor: Color.primaryUIColor
        ]
    }

    private func setTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.selectionIndicatorTintColor = Color.primaryUIColorVariant.withAlphaComponent(0.87)
        tabBarAppearance.backgroundColor = Color.surfaceUIColor
        setTabBarItemColors(tabBarAppearance.stackedLayoutAppearance)
        setTabBarItemColors(tabBarAppearance.inlineLayoutAppearance)
        setTabBarItemColors(tabBarAppearance.compactInlineLayoutAppearance)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    private func setNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Color.primaryUIColor

        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Color.onPrimaryUIColor,
            NSAttributedString.Key.backgroundColor: Color.primaryUIColor
        ]
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Color.onPrimaryUIColor,
            NSAttributedString.Key.backgroundColor: Color.primaryUIColor
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        UINavigationBar.appearance().barTintColor = Color.onPrimaryUIColor
        UINavigationBar.appearance().tintColor = Color.onPrimaryUIColor
        UINavigationBar.appearance().prefersLargeTitles = false
    }

    private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance) {
        itemAppearance.normal.iconColor = Color.onBackgroundUIColor.withAlphaComponent(0.6)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: Color.onBackgroundUIColor.withAlphaComponent(0.6),
            .paragraphStyle: NSParagraphStyle.default
        ]

        itemAppearance.selected.iconColor = Color.primaryUIColorVariant.withAlphaComponent(0.87)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: Color.primaryUIColorVariant.withAlphaComponent(0.87),
            .paragraphStyle: NSParagraphStyle.default
        ]
    }

}
