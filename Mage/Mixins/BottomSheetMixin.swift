//
//  BottomSheetMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/9/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol BottomSheetEnabled {
    var mapView: MKMapView? { get set }
    var bottomSheetMixin: BottomSheetMixin? { get set }
}

class BottomSheetMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?
    var navigationController: UINavigationController?
    var mageBottomSheet: MageBottomSheetViewController?
    var bottomSheet:MDCBottomSheetController?
    
    init(mapView: MKMapView, navigationController: UINavigationController?, scheme: MDCContainerScheming?) {
        self.mapView = mapView
        self.scheme = scheme
        self.navigationController = navigationController
    }
    
    func setupMixin() {
        NotificationCenter.default.addObserver(forName: .MapItemsTapped, object: nil, queue: .main) { [weak self] notification in
            if let notification = notification.object as? MapItemsTappedNotification {
                self?.handleTappedAnnotations(annotations: notification.annotations)
            }
        }
    }
    
    func handleTappedAnnotations(annotations: Set<AnyHashable>?) {
        var dedup: Set<AnyHashable> = Set()
        let bottomSheetItems: [BottomSheetItem] = createBottomSheetItems(annotations: annotations, dedup: &dedup)
        if bottomSheetItems.count == 0 {
            return
        }
        mageBottomSheet = MageBottomSheetViewController(items: bottomSheetItems, scheme: scheme, bottomSheetDelegate: self)
        bottomSheet = MDCBottomSheetController(contentViewController: mageBottomSheet!)
        bottomSheet?.navigationController?.navigationBar.isTranslucent = true
        bottomSheet?.delegate = self
        bottomSheet?.trackingScrollView = mageBottomSheet?.scrollView
        navigationController?.present(bottomSheet!, animated: true, completion: nil)
    }
    
    func createBottomSheetItems(annotations: Set<AnyHashable>?, dedup: inout Set<AnyHashable>) -> [BottomSheetItem] {
        var items: Set<BottomSheetItem> = Set()
        
        guard let annotations = annotations else {
            return Array(items)
        }

        for annotation in annotations {
            if let annotation = annotation as? ObservationAnnotation {
//                if self.hideObservations {
//                    continue
//                }
                if let observation = annotation.observation, !dedup.contains(observation) {
                    _ = dedup.insert(observation)
                    let bottomSheetItem = BottomSheetItem(item: observation, actionDelegate: nil, annotationView: annotation.view)
                    items.insert(bottomSheetItem)
                }
            }
        }
        
        return Array(items)
    }
}

extension BottomSheetMixin : BottomSheetDelegate {
    
}

extension BottomSheetMixin : MDCBottomSheetControllerDelegate {
    
}
