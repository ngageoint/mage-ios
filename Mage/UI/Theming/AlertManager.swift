//
//  AlertManager.swift
//  MAGE
//
//  Created by Brent Michalski on 6/27/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public class AlertManager: NSObject {

    /// Shared singleton instance
    @objc public static let shared = AlertManager()

    private override init() {}

    /// Shows a basic snackbar-style alert (no title)
    @objc public func show(message: String, duration: TimeInterval = 2.0, in viewController: UIViewController? = nil) {
        show(title: nil, message: message, duration: duration, in: viewController)
    }
    
    /// Shows a snackbar-style alert with title
    @objc public func show(title: String?, message: String, duration: TimeInterval = 2.0, in viewController: UIViewController? = nil) {
        guard let presentingVC = viewController ?? Self.topViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        presentingVC.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alert.dismiss(animated: true)
        }
    }
    
    /// Shows an alert with any number of custom actions
    @objc public func showAlert(
        title: String?,
        message: String?,
        actions: [UIAlertAction],
        preferredStyle: UIAlertController.Style = .alert,
        in viewController: UIViewController? = nil
    ) {
        guard let presentingVC = viewController ?? Self.topViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        actions.forEach { alert.addAction($0) }

        presentingVC.present(alert, animated: true)
    }
    
    // Convenience for Objective-C
    @objc public func showAlertWithTitle(
        _ title: String?,
        message: String?,
        okTitle: String = "OK",
        handler: (() -> Void)? = nil
    ) {
        let okAction = UIAlertAction(title: okTitle, style: .default) { _ in handler?() }
        showAlert(title: title, message: message, actions: [okAction])
    }
    
    
    /// Display a brief alert (snackbar-style) message
    /// - Parameters:
    ///   - message: The message to display.
    ///   - duration: How long the alert should stay visible (in seconds).
    ///   - viewController: The view controller to present from. Optional; attempts to auto-detect if nil.
    @objc public func show(message: String, duration: TimeInterval = 2.0, in viewController: UIViewController? = nil) {
        guard let presentingVC = viewController ?? Self.topViewController() else { return }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        presentingVC.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alert.dismiss(animated: true)
        }
    }

    /// Display a brief alert with a title and message
    /// - Parameters:
    ///   - title: The alert title (optional).
    ///   - message: The message to display.
    ///   - duration: How long the alert should stay visible (in seconds).
    ///   - viewController: The view controller to present from. Optional; attempts to auto-detect if nil.
    @objc public func show(title: String?, message: String, duration: TimeInterval = 2.0, in viewController: UIViewController? = nil) {
        guard let presentingVC = viewController ?? Self.topViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        presentingVC.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alert.dismiss(animated: true)
        }
    }
    
    /// Try to automatically find the top-most view controller
    private static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
    
    @objc public func showUndoAlert(message: String, undoHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "UNDO", style: .default) { _ in undoHandler() })
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))

        topViewController()?.present(alert, animated: true)
    }
}
