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
    var mageBottomSheet: UIViewController?
    
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
            .sink { [weak self] bottomSheetItems in
                Task { [weak self] in
                    if let bottomSheetItems = bottomSheetItems, !bottomSheetItems.isEmpty {
                        await self?.showBottomSheet(bottomSheetItems: bottomSheetItems, mapView: mapView)
                    } else {
                        await self?.dismissBottomSheet()
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    @MainActor
    func showBottomSheet(bottomSheetItems: [BottomSheetItem], mapView: MKMapView) {
        let mageBottomSheet = SwiftUIViewController(swiftUIView: MageBottomSheet())
        mageBottomSheet.modalPresentationStyle = .pageSheet
        if let sheet = mageBottomSheet.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        self.bottomSheetEnabled.navigationController?.present(mageBottomSheet, animated: true, completion: nil)
        
        self.mageBottomSheet = mageBottomSheet
        self.mageBottomSheet?.presentationController?.delegate = self
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
        self.mageBottomSheet?.dismiss(animated: true, completion: {
            self.finishDismiss()
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
    
    func finishDismiss() {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        self.mageBottomSheet = nil
        Task { [weak self] in
            await self?.bottomSheetRepository.setItemKeys(itemKeys: nil)
        }
        if let mapViewDisappearingObserver = self.mapViewDisappearingObserver {
            NotificationCenter.default.removeObserver(mapViewDisappearingObserver, name: .MapViewDisappearing, object: nil)
        }
        NotificationCenter.default.post(name: .BottomSheetDismissed, object: nil)
    }
}

extension BottomSheetMixin: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if self.mageBottomSheet != nil {
            finishDismiss()
        }
    }
}
