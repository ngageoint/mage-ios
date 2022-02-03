//
//  FileViewerCoordinator.swift
//  MAGE
//
//  Created by Daniel Barela on 2/2/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

protocol FileViewerCoordinatorDelegate {
    func doneViewing(coordinator: NSObject);
}

class FileViewerCoordinator: NSObject {
    var scheme: MDCContainerScheming?
    var data: Data
    var contentType: String
    var rootViewController: UINavigationController
    
    public init(rootViewController: UINavigationController, data: Data, contentType: String, scheme: MDCContainerScheming?) {
        self.scheme = scheme
        self.data = data
        self.contentType = contentType
        self.rootViewController = rootViewController
    }
    
    public func start(animated: Bool = true, withCloseButton: Bool = false) {
        if contentType.hasPrefix("image") {
            rootViewController.pushViewController(ImageViewer(data: data, contentType: contentType, info: nil), animated: true)
        } else if contentType.hasPrefix("video") {
            rootViewController.pushViewController(ExportableVideoViewController(), animated: true)
            rootViewController.pushViewController(DocumentViewer(data: data, contentType: contentType, info: nil), animated: true)
        } else if contentType.hasPrefix("audio") {
            
        } else {
            rootViewController.pushViewController(DocumentViewer(data: data, contentType: contentType, info: nil), animated: true)
        }
    }
}
