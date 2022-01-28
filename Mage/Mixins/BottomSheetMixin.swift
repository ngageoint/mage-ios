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
                var bottomSheetItems: [BottomSheetItem] = []
                bottomSheetItems += self?.handleTappedAnnotations(annotations: notification.annotations) ?? []
                bottomSheetItems += self?.handleTappedItems(items: notification.items) ?? []
                if bottomSheetItems.count == 0 {
                    return
                }
                
                let mageBottomSheet = MageBottomSheetViewController(items: bottomSheetItems, scheme: self?.scheme)
                let bottomSheet = MDCBottomSheetController(contentViewController: mageBottomSheet)
                bottomSheet.navigationController?.navigationBar.isTranslucent = true
                bottomSheet.delegate = self
                bottomSheet.trackingScrollView = mageBottomSheet.scrollView
                self?.navigationController?.present(bottomSheet, animated: true, completion: nil)
                self?.bottomSheet = bottomSheet
                self?.mageBottomSheet = mageBottomSheet
                NotificationCenter.default.addObserver(forName: .MapViewDisappearing, object: nil, queue: .main) { [weak self] notification in
                    self?.bottomSheet?.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: .BottomSheetDismissed, object: nil)
                    })
                }
                NotificationCenter.default.addObserver(forName: .DismissBottomSheet, object: nil, queue: .main) { [weak self] notification in
                    self?.bottomSheet?.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: .BottomSheetDismissed, object: nil)
                    })
                }
            }
        }
    }
    
    func handleTappedItems(items: [Any]?) -> [BottomSheetItem] {
        var bottomSheetItems: [BottomSheetItem] = []
        if let items = items {
            for item in items {
                let bottomSheetItem = BottomSheetItem(item: item, actionDelegate: self, annotationView: nil)
                bottomSheetItems.append(bottomSheetItem)
            }
        }
        return bottomSheetItems
    }
    
    func handleTappedAnnotations(annotations: Set<AnyHashable>?) -> [BottomSheetItem] {
        var dedup: Set<AnyHashable> = Set()
        let bottomSheetItems: [BottomSheetItem] = createBottomSheetItems(annotations: annotations, dedup: &dedup)
        return bottomSheetItems
    }
    
    func createBottomSheetItems(annotations: Set<AnyHashable>?, dedup: inout Set<AnyHashable>) -> [BottomSheetItem] {
        var items: Set<BottomSheetItem> = Set()
        
        guard let annotations = annotations else {
            return Array(items)
        }

        for annotation in annotations {
            if let annotation = annotation as? ObservationAnnotation {
                if let observation = annotation.observation, !dedup.contains(observation) {
                    _ = dedup.insert(observation)
                    let bottomSheetItem = BottomSheetItem(item: observation, actionDelegate: nil, annotationView: annotation.view)
                    items.insert(bottomSheetItem)
                }
            } else if let annotation = annotation as? LocationAnnotation {
                if let user = annotation.user, !dedup.contains(user) {
                    _ = dedup.insert(user)
                    let bottomSheetItem = BottomSheetItem(item: user, actionDelegate: nil, annotationView: annotation.view)
                    items.insert(bottomSheetItem)
                }
            } else if let annotation = annotation as? StaticPointAnnotation {
                let featureItem = FeatureItem(annotation: annotation)
                if !dedup.contains(featureItem) {
                    _ = dedup.insert(featureItem)
                    let bottomSheetItem = BottomSheetItem(item: featureItem, actionDelegate: nil, annotationView: mapView?.view(for: annotation))
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
    func bottomSheetControllerDidDismissBottomSheet(_ controller: MDCBottomSheetController) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.removeObserver(self, name: .MapViewDisappearing, object: nil)
    }
}
