//
//  IDPCoordinator.swift
//  MAGE
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SafariServices
import UIKit

final class IDPCoordinator: NSObject, SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    private weak var presenter: UIViewController?
    private let url: String
    private let strategy: [String: Any]
    private weak var delegate: IDPCoordinatorDelegate?
    
    private var safariVC: SFSafariViewController?
    private var notificationObserver: NSObjectProtocol?
    
    init(presenter: UIViewController, url: String, strategy: [String: Any], delegate: IDPCoordinatorDelegate?) {
        self.presenter = presenter
        self.url = url
        self.strategy = strategy
        self.delegate = delegate
        super.init()
    }
    
    deinit {
        cleanup()
    }

    func start() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("MageAppLink"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLink(notification: notification)
        }
        
        let urlWithState = "\(url)?state=mobile"
        guard let safariURL = URL(string: urlWithState) else { return }
        
        let safariVC = SFSafariViewController(url: safariURL)
        safariVC.modalPresentationStyle = .pageSheet
        safariVC.delegate = self
        safariVC.presentationController?.delegate = self
        self.safariVC = safariVC
        
        presenter?.present(safariVC, animated: true)
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        cleanup()
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        cleanup()
    }
    
    private func cleanup() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }
    
    private func handleAppLink(notification: Notification) {
        cleanup()
        
        guard let url = notification.object as? URL else { return }
        if url.path.contains("authentication") {
            // Get the token
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let tokenItem = components.queryItems?.first(where: { $0.name == "token" }),
                  let token = tokenItem.value else { return }
            
            completeSignIn(token: token)
        } else {
            completeSignUp()
        }
    }
        
    private func completeSignIn(token: String) {
        let infoDict = Bundle.main.infoDictionary
        let appVersion = infoDict?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = infoDict?["CFBundleVersion"] as? String ?? ""
        let parameters: [String: Any] = [
            "strategy": strategy,
            "token": token,
            "uid": DeviceUUID.retrieveDeviceUUID()?.uuidString ?? "",
            "appVersion": "\(appVersion)-\(buildNumber)"
        ]
        
        safariVC?.dismiss(animated: true) { [weak self] in
            self?.delegate?.idpCoordinatorDidCompleteSignIn(parameters: parameters)
        }
    }
    
    private func completeSignUp() {
        safariVC?.dismiss(animated: true) { [weak self] in
            self?.delegate?.idpCoordinatorDidCompleteSignUp()
        }
    }
}
