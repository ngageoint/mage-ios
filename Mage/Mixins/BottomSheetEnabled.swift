//
//  BottomSheetMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/9/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapFramework
import Combine

protocol BottomSheetEnabled {
    var mapView: MKMapView? { get set }
    var navigationController: UINavigationController?  { get set }
    var scheme: MDCContainerScheming? { get set }
    var bottomSheetMixin: BottomSheetMixin? { get set }
}

class BottomSheetMixin: NSObject, MapMixin {
    @Injected(\.observationLocationRepository)
    var observationLocationRepository: ObservationLocationRepository
    
    @Injected(\.bottomSheetRepository)
    var bottomSheetRepository: BottomSheetRepository
    
    var cancellable = Set<AnyCancellable>()
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {
        
    }
    
    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }
    
    var bottomSheetEnabled: BottomSheetEnabled
    var mapViewDisappearingObserver: Any?
    var mageBottomSheet: MageBottomSheetViewController?
    var bottomSheet:MDCBottomSheetController?
    
    init(bottomSheetEnabled: BottomSheetEnabled) {
        self.bottomSheetEnabled = bottomSheetEnabled
        super.init()

    }
    
    func cleanupMixin() {
        cancellable.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    func setupMixin(mapView: MKMapView, mapState: MapState) {
        self.bottomSheetRepository.$bottomSheetItems
            .receive(on: DispatchQueue.main)
            .sink { bottomSheetItems in
                Task {
                    if let bottomSheetItems = bottomSheetItems, !bottomSheetItems.isEmpty {
                        await self.showBottomSheet(bottomSheetItems: bottomSheetItems, mapView: mapView)
                    } else {
                        await self.dismissBottomSheet()
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    @MainActor
    func showBottomSheet(bottomSheetItems: [BottomSheetItem], mapView: MKMapView) {
        
        let mageBottomSheet = MageBottomSheetViewController(items: bottomSheetItems, mapView: mapView, scheme: self.bottomSheetEnabled.scheme)
        let bottomSheetNav = UINavigationController(rootViewController: mageBottomSheet)
        let bottomSheet = MDCBottomSheetController(contentViewController: bottomSheetNav)
        bottomSheet.navigationController?.navigationBar.isTranslucent = true
        bottomSheet.scrimColor = .clear
        bottomSheet.delegate = self
        bottomSheet.trackingScrollView = mageBottomSheet.scrollView
        self.bottomSheetEnabled.navigationController?.present(bottomSheet, animated: true, completion: nil)
        self.bottomSheet = bottomSheet
        self.mageBottomSheet = mageBottomSheet
        self.mapViewDisappearingObserver = NotificationCenter.default.addObserver(forName: .MapViewDisappearing, object: nil, queue: .main) { [weak self] notification in
            Task { [weak self] in
                await self?.dismissBottomSheet()
            }
        }
        NotificationCenter.default.addObserver(forName: .DismissBottomSheet, object: nil, queue: .main) { [weak self] notification in
            Task { [weak self] in
                await self?.dismissBottomSheet()
            }
        }
    }
    
    @MainActor
    func dismissBottomSheet() {
        self.bottomSheet?.dismiss(animated: true, completion: {
            self.mageBottomSheet = nil
            self.bottomSheet = nil
            NotificationCenter.default.post(name: .BottomSheetDismissed, object: nil)
        })
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
}

extension BottomSheetMixin : MDCBottomSheetControllerDelegate {
    func bottomSheetControllerDidDismissBottomSheet(_ controller: MDCBottomSheetController) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        mageBottomSheet = nil
        bottomSheet = nil
        Task {
            await bottomSheetRepository.setItemKeys(itemKeys: nil)
        }
        if let mapViewDisappearingObserver = mapViewDisappearingObserver {
            NotificationCenter.default.removeObserver(mapViewDisappearingObserver, name: .MapViewDisappearing, object: nil)
        }
    }
}
