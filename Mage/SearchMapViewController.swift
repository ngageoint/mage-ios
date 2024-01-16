//
//  SearchMapViewController.swift
//  MAGE
//
//  Created by William Newman on 1/11/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol SearchMapViewControllerDelegate {
    func apply(coordinate: CLLocationCoordinate2D)
    func cancel()
}

class SearchMapViewController: UIViewController, SearchMapViewDelegate {
    var mapView: SearchMapView?
    var scheme: MDCContainerScheming?
    var result: GeocoderResult?
    @objc weak var delegate: SearchMapViewControllerDelegate?
    
    @objc public init(scheme: MDCContainerScheming?) {
        super.init(nibName: nil, bundle: nil)
        self.scheme = scheme
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        mapView = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = SearchMapView(navigationController: self.navigationController, scheme: self.scheme)
        mapView?.delegate = self
        view.addSubview(mapView!)
        mapView?.autoPinEdgesToSuperviewEdges()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel(_:)));
        self.navigationItem.leftBarButtonItem?.accessibilityLabel = "Cancel";
        
        self.navigationItem.setTitle("Search", subtitle: nil, scheme: scheme)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(apply(_:)))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
        
    @objc func apply(_ sender: UIBarButtonItem) {
        if let location = result?.location {
            if let delegate = delegate {
                delegate.apply(coordinate: location)
                mapView?.removeFromSuperview()
            }
        }
    }
    
    @objc func cancel(_ sender: UIBarButtonItem) {
        mapView?.removeFromSuperview()
        delegate?.cancel()
    }
    
    func onSearchResultSelected(result: GeocoderResult) {
        self.result = result
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
}
