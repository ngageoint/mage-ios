//
//  DocumentViewer.swift
//  MAGE
//
//  Created by Daniel Barela on 2/3/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents
import QuickLook

class DocumentViewer : UIViewController {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView.newAutoLayout()
        imageView.image = UIImage(systemName: "eye.slash.fill")
        return imageView
    }()
    
    private lazy var notAvailable: UILabel = {
        let notAvailable = UILabel.newAutoLayout()
        notAvailable.text = "Preview Not Available"
        notAvailable.textAlignment = .center
        return notAvailable
    }()
    
    private lazy var notAvailableDescription: UILabel = {
        let notAvailableDescription = UILabel.newAutoLayout()
        notAvailableDescription.text = "You may be able to view this content in another app"
        notAvailableDescription.textAlignment = .center
        return notAvailableDescription
    }()
    
    private lazy var openInButton: MDCButton = {
        let openInButton = MDCButton()
        openInButton.setTitle("Open In", for: .normal)
        openInButton.addTarget(self, action: #selector(self.presentShareSheet(_ :)), for: .touchUpInside);
        return openInButton
    }()
    
    private var tempFile: String = NSTemporaryDirectory();
    
    var documentInteractionController:UIDocumentInteractionController?
    var data: Data?
    var info: [String : Any]?
    var contentType: String?
    var scheme: MDCContainerScheming?

    public convenience init(data: Data, contentType: String, info: [String : Any]?, scheme: MDCContainerScheming?) {
        self.init(nibName: nil, bundle: nil);
        self.data = data
        self.info = info
        self.contentType = contentType
        self.scheme = scheme
        
        if let info = info {
            if let name = info["title"] as? String {
                tempFile.append(name)
                title = name
            } else if let name = info["name"] as? String {
                tempFile.append(name)
                title = name
            } else {
                tempFile.append("media")
            }
        }
        
        let uttype = UTType(mimeType: contentType)
        
        if let ext = uttype?.preferredFilenameExtension {
            tempFile.append(contentsOf: ".\(ext)")
        }
        if title == nil {
            title = "GeoPackage Media"
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }
        
        self.scheme = scheme
        view.backgroundColor = scheme.colorScheme.surfaceColor
        imageView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
        notAvailable.font = scheme.typographyScheme.headline5
        notAvailable.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
        notAvailableDescription.font = scheme.typographyScheme.subtitle2
        notAvailableDescription.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
        openInButton.applyOutlinedTheme(withScheme: scheme)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        view.addSubview(notAvailable)
        view.addSubview(notAvailableDescription)
        view.addSubview(openInButton)
        
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageView.autoSetDimensions(to: CGSize(width: 164, height: 164))
        imageView.autoAlignAxis(.horizontal, toSameAxisOf: view, withOffset: -82)
        
        notAvailable.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
        notAvailable.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
        notAvailable.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 16)
        notAvailableDescription.autoPinEdge(.top, to: .bottom, of: notAvailable, withOffset: 8)
        notAvailableDescription.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
        notAvailableDescription.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
        openInButton.autoPinEdge(.top, to: .bottom, of: notAvailableDescription, withOffset: 32)
        openInButton.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
        openInButton.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
        
        applyTheme(withScheme: scheme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(presentShareSheet(_ :)));
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
    }
    
    @objc func dismiss(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func presentShareSheet(_ sender: UIButton) {
        do {
            let imageURL: URL = URL(fileURLWithPath: tempFile)
            try data?.write(to: imageURL)
            
            documentInteractionController = UIDocumentInteractionController(url: imageURL)
            documentInteractionController?.annotation = info
            documentInteractionController?.delegate = self
            documentInteractionController?.presentOptionsMenu(from: sender.frame, in: view, animated: true)
        } catch {
            MageLogger.misc.error("Error writing the file: \(error.localizedDescription)")
        }
    }
}

extension DocumentViewer : UIDocumentInteractionControllerDelegate {
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return navigationController!
    }
}
