//
//  ImageViewer.swift
//  MAGE
//
//  Created by Daniel Barela on 2/3/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

class ImageViewer : UIViewController {
    
    private var imageView: UIImageView = UIImageView()
    private var tempFile: String = NSTemporaryDirectory() + "image";
    
    var documentInteractionController:UIDocumentInteractionController?
    var data: Data?
    var info: [String : String]?
    var contentType: String?
    
    public convenience init(data: Data, contentType: String, info: [String : String]?) {
        self.init(nibName: nil, bundle: nil);
        self.data = data
        self.info = info
        self.contentType = contentType
        
        let uttype = UTType(mimeType: contentType)
        if let ext = uttype?.preferredFilenameExtension {
            tempFile.append(contentsOf: ".\(ext)")
        }
//        if contentType.contains("jpeg") {
//            tempFile.append(contentsOf: ".jpeg")
//        } else if contentType.contains("png") {
//            tempFile.append(contentsOf: ".png")
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        imageView.contentMode = .scaleAspectFit
        showImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(presentShareSheet(_ :)));
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
    }
    
    @objc func dismiss(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func showImage() {
        guard let data = data else {
            return
        }
        let image = UIImage(data: data)
        imageView.image = image
    }
    
    @objc func presentShareSheet(_ sender: UIBarButtonItem) {
        do {
            let imageURL: URL = URL(fileURLWithPath: tempFile)
            try data?.write(to: imageURL)

            documentInteractionController = UIDocumentInteractionController(url: imageURL)
            if let contentType = contentType {
                documentInteractionController?.uti = UTTypeCopyPreferredTagWithClass(contentType as CFString, kUTTagClassMIMEType)?.takeRetainedValue() as String?
            }
            documentInteractionController?.annotation = info
            documentInteractionController?.presentOptionsMenu(from: sender, animated: true)
            
        } catch {
            // Prints the localized description of the error from the do block
            print("Error writing the file: \(error.localizedDescription)")
        }
    }
}
