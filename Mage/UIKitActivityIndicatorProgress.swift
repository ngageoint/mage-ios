//
//  UIKitActivityIndicatorProgress.swift
//  MAGE
//
//  Created by Brent Michalski on 6/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import Kingfisher

/// Wrapper to simulate an `Indicator` using `UIActivityIndicatorView`
class UIKitActivityIndicatorProgress: Indicator {
    private let progressIndicatorView: UIView = UIView()
    private var parent: UIView?
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    var view: IndicatorView {
        return progressIndicatorView
    }
    
    func startAnimatingView() {
        view.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    func stopAnimatingView() {
        view.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func setProgress(progress: Float) {
        // UIActivityIndicatorView doesn't support progress, so this is a no-op
    }
    
    init(parent: UIView) {
        self.parent = parent
        progressIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        progressIndicatorView.isUserInteractionEnabled = false
        
        progressIndicatorView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: progressIndicatorView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: progressIndicatorView.centerYAnchor)
        ])
    }
}
