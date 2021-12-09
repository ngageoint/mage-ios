//
//  MainMageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

class MainMageMapViewController: MageMapViewController, FilteredObservationsMap, BottomSheetEnabled {
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var bottomSheetMixin: BottomSheetMixin?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let mapView = mapView {
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, scheme: scheme)
            bottomSheetMixin = BottomSheetMixin(mapView: mapView, navigationController: self.navigationController, scheme: scheme)
            mapMixins.append(filteredObservationsMapMixin!)
            mapMixins.append(bottomSheetMixin!)
        }
        initiateMapMixins()
    }
}
