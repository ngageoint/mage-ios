//
//  FileViewerCoordinator.swift
//  MAGE
//
//  Created by Daniel Barela on 2/2/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

protocol FileViewerCoordinatorDelegate {
    func doneViewing(coordinator: NSObject);
}

class FileViewerCoordinator: NSObject {
    var scheme: MDCContainerScheming?
    var data: Data
    var contentType: String
    var info: [String: Any]?
    var presentingViewController: UIViewController
    
    var quickLookController: MediaPreviewController?
    var documentTitle = "GeoPackage Media"

    public init(presentingViewController: UIViewController, data: Data, contentType: String, info: [String: Any]? = nil, scheme: MDCContainerScheming?) {
        self.scheme = scheme
        self.data = data
        self.contentType = contentType
        self.info = info
        self.presentingViewController = presentingViewController
    }
    
    public func start(animated: Bool = true, withCloseButton: Bool = false) {
        var fileName = ""
        if let info = info {
            if let name = info["title"] as? String {
                fileName = name
                documentTitle = name
            } else if let name = info["name"] as? String {
                fileName = name
                documentTitle = name
            } else {
                fileName = "media"
            }
        }
        
        let uttype = UTType(mimeType: contentType)
        
        if let ext = uttype?.preferredFilenameExtension {
            fileName.append(contentsOf: ".\(ext)")
        }
        
        quickLookController = MediaPreviewController(fileName: fileName, mediaTitle: documentTitle, data: data, url: nil, scheme: scheme)
        if withCloseButton {
            quickLookController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
        }
        
        let nav = UINavigationController(rootViewController: quickLookController!)
        nav.view.backgroundColor = .black
        
        presentingViewController.present(nav, animated: true, completion: nil)
    }
    
    @objc func dismiss(_ sender: UIBarButtonItem) {
        self.presentingViewController.dismiss(animated: true, completion: nil)
    }
}
