//
//  AttachmentProgressViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 8/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class AttachmentProgressViewController: UIViewController {
    var scheme: AppContainerScheming?
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    private lazy var progressDescription: UILabel = {
        let description = UILabel.newAutoLayout()
        description.textAlignment = .center
        return description
    }()
    
    public convenience init(scheme: AppContainerScheming?) {
        self.init(nibName: nil, bundle: nil)
        self.scheme = scheme
    }
    
    public func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme
        
        self.view.backgroundColor = containerScheme.colorScheme.surfaceColor?.withAlphaComponent(0.87)
        self.progressDescription.textColor = containerScheme.colorScheme.onSurfaceColor
        self.progressDescription.font = containerScheme.typographyScheme.headline5Font
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(activityIndicator)
        view.addSubview(progressDescription)
        
        activityIndicator.autoCenterInSuperview()
        progressDescription.autoPinEdge(toSuperviewEdge: .left)
        progressDescription.autoPinEdge(toSuperviewEdge: .right)
        progressDescription.autoPinEdge(.top, to: .bottom, of: activityIndicator, withOffset: 16)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activityIndicator.startAnimating()
    }
    
    func setProgressMessage(message: String) {
        progressDescription.text = message
    }
}
