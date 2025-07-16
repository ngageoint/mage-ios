//
//  MageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import GeoPackage
import MapKit
import MapFramework

class MageMapView: UIView, GeoPackageBaseMap {
    @Injected(\.bottomSheetRepository)
    var bottomSheetRepository: BottomSheetRepository
    
    @Injected(\.mapStateRepository)
    var mapStateRepository: MapStateRepository
    
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
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action:nil)
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        self.mapView?.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTapGensture(tapGestureRecognizer:)))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.delaysTouchesBegan = true
        singleTapGestureRecognizer.cancelsTouchesInView = true
        singleTapGestureRecognizer.delegate = self
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
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
        var annotationsTapped: [any MKAnnotation] = []
        let visibleMapRect = mapView.visibleMapRect
        let annotationsVisible = mapView.annotations(in: visibleMapRect)
        
        var itemKeys: [String: [String]] = [:]
        
        for annotation in annotationsVisible {
            if let mkAnnotation = annotation as? MKAnnotation, let view = mapView.view(for: mkAnnotation) {
                
                let location = gesture.location(in: view)
                if view.bounds.contains(location) {
                    if let annotation = mkAnnotation as? DataSourceAnnotation {
                        itemKeys[annotation.dataSource.key, default: [String]()].append(annotation.itemKey)
                    } else if let annotation = mkAnnotation as? LocationAnnotation {
                        if let user = annotation.user {
                            itemKeys[DataSources.user.key, default: [String]()].append(user.objectID.uriRepresentation().absoluteString)
                        }
                    } else {
                        annotationsTapped.append(mkAnnotation)
                    }
                }
            }
        }
        
        // need to search visible overlays mkpolygon and mklines
        let screenPercentage = UserDefaults.standard.shapeScreenClickPercentage
        let distanceTolerance = (mapView.visibleMapRect.size.width) * Double(screenPercentage)
        for overlay in mapView.overlays.compactMap({ overlay in
            overlay as? DataSourceIdentifiable
        }) {
            if let polygon = overlay as? MKPolygon {
                if polygon.hitTest(location: tapCoord) {
                    itemKeys[overlay.dataSource.key, default: [String]()].append(overlay.itemKey)
                }
            } else if let polyline = overlay as? MKPolyline {
                if polyline.hitTest(location: tapCoord, distanceTolerance: distanceTolerance) {
                    itemKeys[overlay.dataSource.key, default: [String]()].append(overlay.itemKey)
                }
            }
        }
        Task {
            for mixin in mapMixins {
                let matchedItemKeys = await mixin.itemKeys(at: tapCoord, mapView: mapView, touchPoint: tapPoint)
                itemKeys.merge(matchedItemKeys) { current, new in
                    Array(Set(current + new))
                }
            }
            bottomSheetRepository.setItemKeys(itemKeys: itemKeys)
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
