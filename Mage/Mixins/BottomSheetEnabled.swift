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
    var navigationController: UINavigationController?  { get set }
    var scheme: MDCContainerScheming? { get set }
    var bottomSheetMixin: BottomSheetMixin? { get set }
}

class BottomSheetMixin: NSObject, MapMixin {
    var bottomSheetEnabled: BottomSheetEnabled
    var mapItemsTappedObserver: Any?
    var mapViewDisappearingObserver: Any?
    var mageBottomSheet: MageBottomSheetViewController?
    var bottomSheet:MDCBottomSheetController?
    
    init(bottomSheetEnabled: BottomSheetEnabled) {
        self.bottomSheetEnabled = bottomSheetEnabled
    }
    
    func cleanupMixin() {
        if let mapItemsTappedObserver = mapItemsTappedObserver {
            NotificationCenter.default.removeObserver(mapItemsTappedObserver, name: .MapItemsTapped, object: nil)
        }
        mapItemsTappedObserver = nil
    }
    
    func setupMixin() {
        mapItemsTappedObserver = NotificationCenter.default.addObserver(forName: .MapItemsTapped, object: nil, queue: .main) { [weak self] notification in
            if let mapView = self?.bottomSheetEnabled.mapView, self?.isVisible(view: mapView) == true, let notification = notification.object as? MapItemsTappedNotification, notification.mapView == mapView {
                var bottomSheetItems: [BottomSheetItem] = []
                bottomSheetItems += self?.handleTappedAnnotations(annotations: notification.annotations) ?? []
                bottomSheetItems += self?.handleTappedItems(items: notification.items) ?? []
                if bottomSheetItems.count == 0 {
                    return
                }
                
                let mageBottomSheet = MageBottomSheetViewController(items: bottomSheetItems, mapView: mapView, scheme: self?.bottomSheetEnabled.scheme)
                let bottomSheetNav = UINavigationController(rootViewController: mageBottomSheet)
                let bottomSheet = MDCBottomSheetController(contentViewController: bottomSheetNav)
                bottomSheet.navigationController?.navigationBar.isTranslucent = true
                bottomSheet.delegate = self
                bottomSheet.trackingScrollView = mageBottomSheet.scrollView
                self?.bottomSheetEnabled.navigationController?.present(bottomSheet, animated: true, completion: nil)
                self?.bottomSheet = bottomSheet
                self?.mageBottomSheet = mageBottomSheet
                self?.mapViewDisappearingObserver = NotificationCenter.default.addObserver(forName: .MapViewDisappearing, object: nil, queue: .main) { [weak self] notification in
                    self?.bottomSheet?.dismiss(animated: true, completion: {
                        self?.mageBottomSheet = nil
                        self?.bottomSheet = nil
                        NotificationCenter.default.post(name: .BottomSheetDismissed, object: nil)
                    })
                }
                NotificationCenter.default.addObserver(forName: .DismissBottomSheet, object: nil, queue: .main) { [weak self] notification in
                    self?.bottomSheet?.dismiss(animated: true, completion: {
                        self?.mageBottomSheet = nil
                        self?.bottomSheet = nil
                        NotificationCenter.default.post(name: .BottomSheetDismissed, object: nil)
                    })
                }
            }
        }
    }
    
    func isVisible(view: UIView) -> Bool {
        func isVisible(view: UIView, inView: UIView?) -> Bool {
            guard let inView = inView else { return true }
            let viewFrame = inView.convert(view.bounds, from: view)
            if viewFrame.intersects(inView.bounds) {
                return isVisible(view: view, inView: inView.superview)
            }
            return false
        }
        return isVisible(view: view, inView: view.superview)
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
    
    func handleTappedAnnotations(annotations: [Any]?) -> [BottomSheetItem] {
        var dedup: Set<AnyHashable> = Set()
        let bottomSheetItems: [BottomSheetItem] = createBottomSheetItems(annotations: annotations, dedup: &dedup)
        return bottomSheetItems
    }
    
    func createBottomSheetItems(annotations: [Any]?, dedup: inout Set<AnyHashable>) -> [BottomSheetItem] {
        var items: [BottomSheetItem] = []
        
        guard let annotations = annotations else {
            return items
        }

        for annotation in annotations {
            if let annotation = annotation as? ObservationAnnotation {
                if let observation = annotation.observation, !dedup.contains(observation) {
                    _ = dedup.insert(observation)
                    let bottomSheetItem = BottomSheetItem(item: observation, actionDelegate: nil, annotationView: annotation.view)
                    items.append(bottomSheetItem)
                }
            } else if let annotation = annotation as? LocationAnnotation {
                if let user = annotation.user, !dedup.contains(user) {
                    _ = dedup.insert(user)
                    let bottomSheetItem = BottomSheetItem(item: user, actionDelegate: nil, annotationView: annotation.view)
                    items.append(bottomSheetItem)
                }
            } else if let annotation = annotation as? StaticPointAnnotation {
                let featureItem = FeatureItem(annotation: annotation)
                if !dedup.contains(featureItem) {
                    _ = dedup.insert(featureItem)
                    let bottomSheetItem = BottomSheetItem(item: featureItem, actionDelegate: nil, annotationView: bottomSheetEnabled.mapView?.view(for: annotation))
                    items.append(bottomSheetItem)
                }
            } else if let annotation = annotation as? FeedItem {
                if !dedup.contains(annotation) {
                    _ = dedup.insert(annotation)
                    let bottomSheetItem = BottomSheetItem(item: annotation, actionDelegate: nil, annotationView: bottomSheetEnabled.mapView?.view(for: annotation))
                    items.append(bottomSheetItem)
                }
            }
        }
        
        return Array(items)
    }
}

extension BottomSheetMixin : MDCBottomSheetControllerDelegate {
    func bottomSheetControllerDidDismissBottomSheet(_ controller: MDCBottomSheetController) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        mageBottomSheet = nil
        bottomSheet = nil
        if let mapViewDisappearingObserver = mapViewDisappearingObserver {
            NotificationCenter.default.removeObserver(mapViewDisappearingObserver, name: .MapViewDisappearing, object: nil)
        }
    }
}
