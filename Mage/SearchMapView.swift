//
//  SearchMapView.swift
//  MAGE
//
//  Created by William Newman on 1/11/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol SearchMapViewDelegate {
    func onSearchResultSelected(result: GeocoderResult);
}

class SearchMapView: MageMapView, HasMapSearch {
    
    weak var viewController: UIViewController?
    weak var navigationController: UINavigationController?
    
    var delegate: SearchMapViewDelegate?
    var hasMapSearchMixin: HasMapSearchMixin?

    private lazy var buttonStack: UIStackView = {
        let buttonStack = UIStackView.newAutoLayout()
        buttonStack.alignment = .fill
        buttonStack.distribution = .fill
        buttonStack.spacing = 10
        buttonStack.axis = .vertical
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.isLayoutMarginsRelativeArrangement = true
        return buttonStack
    }()
    
    public init(navigationController: UINavigationController?, scheme: AppContainerScheming?) {
        super.init(scheme: scheme)
        self.navigationController = navigationController
        self.scheme = scheme
        
        hasMapSearchMixin = HasMapSearchMixin(hasMapSearch: self, rootView: buttonStack, indexInView: 0, navigationController: self.navigationController, scheme: self.scheme)
        mapMixins.append(hasMapSearchMixin!)
        initiateMapMixins()
        hasMapSearchMixin?.showSearchBottomSheet()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutView() {
        super.layoutView()
        
        if let mapView = mapView {
            self.insertSubview(buttonStack, aboveSubview: mapView)
            buttonStack.autoPinEdge(.top, to: .top, of: mapView, withOffset: 25)
            buttonStack.autoPinEdge(toSuperviewMargin: .left)
        }
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
        hasMapSearchMixin = nil
    }
    
    override func applyTheme(scheme: AppContainerScheming?) {
        super.applyTheme(scheme: scheme)
    }
    
    func onSearchResultSelected(result: GeocoderResult) {
        delegate?.onSearchResultSelected(result: result)
    }
    
}
