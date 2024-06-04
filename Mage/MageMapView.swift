//
//  MageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import geopackage_ios
import MapKit
import MapFramework

class MageMapView: UIView, GeoPackageBaseMap {
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?;
    var mapMixins: [MapMixin] = []
    var geoPackageBaseMapMixin: GeoPackageBaseMapMixin?
    var mapState: MapState = MapState()

    lazy var mapStack: UIStackView = {
        let mapStack = UIStackView.newAutoLayout()
        mapStack.axis = .vertical
        mapStack.alignment = .fill
        mapStack.spacing = 0
        mapStack.distribution = .fill
        return mapStack
    }()

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public init(scheme: MDCContainerScheming?) {
        super.init(frame: .zero)
        self.configureForAutoLayout()
        self.scheme = scheme
        layoutView()
    }

    func layoutView() {
        mapView = MKMapView.newAutoLayout()
        guard let mapView = mapView else {
            return
        }

        self.addSubview(mapView)
        mapView.autoPinEdgesToSuperviewEdges()
        mapView.delegate = self
        
        self.addSubview(mapStack)
        if UIDevice.current.userInterfaceIdiom == .pad {
            mapStack.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        } else {
            mapStack.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        }
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTapGensture(tapGestureRecognizer:)))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.delaysTouchesBegan = true
        singleTapGestureRecognizer.cancelsTouchesInView = true
        singleTapGestureRecognizer.delegate = self
        self.mapView?.addGestureRecognizer(singleTapGestureRecognizer)
        geoPackageBaseMapMixin = GeoPackageBaseMapMixin(mapView: mapView)
        mapMixins.append(geoPackageBaseMapMixin!)
    }
    
    func initiateMapMixins() {
        guard let mapView = mapView else {
            return
        }
        for mixin in mapMixins {
            mixin.setupMixin(mapView: mapView, mapState: mapState)
//            mixin.applyTheme(scheme: scheme)
        }
    }
    
    func cleanupMapMixins() {
        for mixin in mapMixins {
            mixin.cleanupMixin()
        }
        mapMixins.removeAll()
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        self.scheme = scheme
        for mixin in mapMixins {
//            mixin.applyTheme(scheme: scheme)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for mixin in mapMixins {
            mixin.traitCollectionUpdated(previous: previousTraitCollection)
        }
    }
    
    @objc func singleTapGensture(tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state == .ended {
            mapTap(tapPoint: tapGestureRecognizer.location(in: mapView), gesture: tapGestureRecognizer)
        }
    }

    func mapTap(tapPoint:CGPoint, gesture: UITapGestureRecognizer) {
        guard let mapView = mapView else {
            return
        }

        let tapCoord = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        var annotationsTapped: [Any] = []
        let visibleMapRect = mapView.visibleMapRect
        let annotationsVisible = mapView.annotations(in: visibleMapRect)

        for annotation in annotationsVisible {
            if let mkAnnotation = annotation as? MKAnnotation, let view = mapView.view(for: mkAnnotation) {
                if mkAnnotation is DataSourceAnnotation {
                    continue
                }
                let location = gesture.location(in: view)
                if view.bounds.contains(location) {
                    annotationsTapped.append(annotation)
                }
            }
        }
        Task {
            var items: [Any] = []
            var itemKeys: [String: [String]] = [:]
            for mixin in mapMixins {
                if let matchedItems = await mixin.items(at: tapCoord, mapView: mapView, touchPoint: tapPoint) {
                    items.append(contentsOf: matchedItems)
                }
                let matchedItemKeys = await mixin.itemKeys(at: tapCoord, mapView: mapView, touchPoint: tapPoint)
                itemKeys.merge(matchedItemKeys) { current, new in
                    current + new
                }
            }

            let notification = MapItemsTappedNotification(annotations: annotationsTapped, items: items, itemKeys: itemKeys, mapView: mapView)
            NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
        }
    }
}

extension MageMapView : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let renderableOverlay = overlay as? OverlayRenderable {
            return renderableOverlay.renderer
        }
        for mixin in mapMixins {
            if let renderer = mixin.renderer(overlay: overlay) {
                return renderer
            }
        }
        return MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        for mixin in mapMixins {
            if let view = mixin.viewForAnnotation(annotation: annotation, mapView: mapView){
                return view
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSLog("Mage map view region did change")
        for mixin in mapMixins {
            mixin.regionDidChange(mapView: mapView, animated: animated)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        NSLog("Mage map view region will change")
        for mixin in mapMixins {
            mixin.regionWillChange(mapView: mapView, animated: animated)
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        for mixin in mapMixins {
            mixin.didChangeUserTrackingMode(mapView: mapView, animated: animated)
        }
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {

            guard let annotation = view.annotation as? DataSourceAnnotation else {
                continue
            }
            if annotation.shouldEnlarge {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                        annotation.enlargeAnnoation()
                    }
                }
            }

            if annotation.shouldShrink {
                // have to enlarge it without animmation because it is added to the map at the original size
                annotation.enlargeAnnoation()
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                    annotation.shrinkAnnotation()
                    mapView.removeAnnotation(annotation)
                }
            }
        }

    }
}

extension MageMapView : UIGestureRecognizerDelegate {
    
}
