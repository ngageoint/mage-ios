//
//  MediaPreviewController.swift
//  MAGE
//
//  Created by Daniel Barela on 2/4/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import QuickLook

protocol MediaLoaderDelegate {
    func mediaLoadComplete(filePath: String, newFile: Bool)
}

class MediaPreviewController : QLPreviewController {
    var scheme: AppContainerScheming?
    
    var documentInteractionController: UIDocumentInteractionController?

    var didSetUpConstraints = false
    var fileName: String = "media"
    var mediaTitle: String = "Media"
    var url: URL?
    var data: Data?
    var mediaLoaderDelegate: MediaLoaderDelegate?
    
    private var previewItem : PreviewItem!
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    private let mask: UIView = {
        let mask = UIView.newAutoLayout()
        return mask
    }()
    
    private let couldNotLoad: UIView = {
        let couldNotLoad = UIView.newAutoLayout()
        return couldNotLoad
    }()
    
    private lazy var notVisibleImage: UIImageView = {
        let notVisibleImage = UIImageView.newAutoLayout()
        notVisibleImage.image = UIImage(systemName: "eye.slash.fill")
        return notVisibleImage
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
    
    private lazy var openInButton: UIButton = {
        let openInButton = UIButton()
        openInButton.setTitle("Open In", for: .normal)
        openInButton.addTarget(self, action: #selector(self.presentShareSheet(_ :)), for: .touchUpInside);
        return openInButton
    }()
    
    public convenience init(fileName: String, mediaTitle: String, data: Data? = nil, url: URL? = nil, mediaLoaderDelegate: MediaLoaderDelegate? = nil, scheme: AppContainerScheming?) {
        self.init()
        self.scheme = scheme
        self.fileName = fileName
        self.mediaTitle = mediaTitle
        self.data = data
        self.url = url
        self.mediaLoaderDelegate = mediaLoaderDelegate
        applyTheme(withScheme: scheme)
    }

    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else {
            return
        }
        self.scheme = scheme
        mask.backgroundColor = scheme.colorScheme.surfaceColor
        couldNotLoad.backgroundColor = scheme.colorScheme.surfaceColor
        notVisibleImage.tintColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.4)
        notAvailable.font = scheme.typographyScheme.headline5Font
        notAvailable.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.4)
        notAvailableDescription.font = scheme.typographyScheme.subtitle2Font
        notAvailableDescription.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.4)
        
//        openInButton.applyOutlinedTheme(withScheme: scheme)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        couldNotLoad.addSubview(notVisibleImage)
        couldNotLoad.addSubview(notAvailable)
        couldNotLoad.addSubview(notAvailableDescription)
        couldNotLoad.addSubview(openInButton)
        
        mask.addSubview(activityIndicator)
        
        self.title = fileName;
        self.downloadfile()
        
        self.maskQuickLookError();
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
    }
    
    @objc func dismiss(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func presentShareSheet(_ sender: UIButton) {
        guard let imageURL: URL = self.previewItem.previewItemURL else {
            return
        }
        
        documentInteractionController = UIDocumentInteractionController(url: imageURL)
        documentInteractionController?.delegate = self
        documentInteractionController?.presentOptionsMenu(from: sender.frame, in: view, animated: true)
    }
    
    override func updateViewConstraints() {
        if (!didSetUpConstraints) {
            mask.autoPinEdgesToSuperviewEdges()
            activityIndicator.autoCenterInSuperview()
            
            notVisibleImage.autoAlignAxis(toSuperviewAxis: .vertical)
            notVisibleImage.autoSetDimensions(to: CGSize(width: 164, height: 164))
            notVisibleImage.autoAlignAxis(.horizontal, toSameAxisOf: couldNotLoad, withOffset: -82)
            
            notAvailable.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            notAvailable.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            notAvailable.autoPinEdge(.top, to: .bottom, of: notVisibleImage, withOffset: 16)
            notAvailableDescription.autoPinEdge(.top, to: .bottom, of: notAvailable, withOffset: 8)
            notAvailableDescription.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            notAvailableDescription.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            openInButton.autoPinEdge(.top, to: .bottom, of: notAvailableDescription, withOffset: 32)
            openInButton.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            openInButton.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
        }
        didSetUpConstraints = true
        super.updateViewConstraints()
    }
    
    @objc
    func maskQuickLookError() {
        view.addSubview(mask)
    }
    
    private func downloadfile(){
        
        self.previewItem = PreviewItem()
        self.previewItem.previewItemTitle = mediaTitle
        if let itemUrl = url, itemUrl.isFileURL, FileManager.default.fileExists(atPath: itemUrl.path) {
            // file already exists
            self.previewItem.previewItemURL = itemUrl;
            self.loadFile()
            return
        }
        
        if let data = data {
            let itemUrl = url ?? {
                return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            }()
            do {
                try data.write(to: itemUrl)
                self.previewItem.previewItemURL = itemUrl
                self.loadFile()
                return
            } catch {
                MageLogger.misc.error("Error writing the file: \(error.localizedDescription)")
            }
        }
        
        let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // if there is a url, load the data from there regardless of if there is a file at the temporary path
        if let itemUrl = self.url {
            DispatchQueue.main.async(execute: {
                URLSession.shared.downloadTask(with: itemUrl, completionHandler: { (location, response, error) -> Void in
                    if error != nil {
                        self.showCouldNotLoad()
                    } else {
                        guard let tempLocation = location, error == nil else { return }
                        try? FileManager.default.removeItem(at: destinationUrl)
                        try? FileManager.default.moveItem(at: tempLocation, to: destinationUrl)
                        self.previewItem.previewItemURL = destinationUrl;
                        self.loadFile()
                        if let mediaLoaderDelegate = self.mediaLoaderDelegate {
                            mediaLoaderDelegate.mediaLoadComplete(filePath: destinationUrl.path, newFile: true)
                        }
                    }
                }).resume()
            })
            return
        }
        
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            self.previewItem.previewItemURL = destinationUrl;
            self.loadFile()
        }
    }
    
    func showCouldNotLoad() {
        DispatchQueue.main.async {
            self.view.addSubview(self.couldNotLoad)
            self.couldNotLoad.autoPinEdgesToSuperviewEdges()
        }
    }
    
    func loadFile() {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.mask.isHidden = true
            if let previewItemUrl = self.previewItem.previewItemURL, QLPreviewController.canPreview(previewItemUrl as NSURL) {
                self.reloadData()
                if let toolbar = self.navigationController?.toolbar {
                    toolbar.tintColor = self.scheme?.colorScheme.primaryColor
                }
            } else {
                self.showCouldNotLoad()
            }
        }
    }
    
}

extension MediaPreviewController : QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return previewItem == nil ? 0 : 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem
    }
    
}

extension MediaPreviewController : QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .disabled
    }
}

extension MediaPreviewController : UIDocumentInteractionControllerDelegate {
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return navigationController ?? self
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
}
