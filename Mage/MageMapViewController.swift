//
//  MageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import geopackage_ios

class MageMapViewController: UIViewController, GeoPackageBaseMap, MKMapViewDelegate {
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?;
    var mapMixins: [MapMixin] = []
    var geoPackageBaseMapMixin: GeoPackageBaseMapMixin?

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public init(scheme: MDCContainerScheming?) {
        super.init(nibName: nil, bundle: nil)
        self.scheme = scheme
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MKMapView.newAutoLayout()
        guard let mapView = mapView else {
            return
        }

        self.view.addSubview(mapView)
        mapView.autoPinEdgesToSuperviewEdges()
        mapView.delegate = self
        
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
        for mixin in mapMixins {
            mixin.setupMixin()
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for mixin in mapMixins {
            mixin.traitCollectionUpdated(previous: previousTraitCollection)
        }
    }
    
    @objc func singleTapGensture(tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state == .ended {
            mapTap(tapPoint: tapGestureRecognizer.location(in: mapView))
        }
    }
    
    func mapTap(tapPoint:CGPoint) {
        print("Map tap \(tapPoint)")
        
        guard let tapCoord = self.mapView?.convert(tapPoint, toCoordinateFrom: mapView) else {
            return
        }
        let mapPoint = MKMapPoint(tapCoord)
        let tolerance = GPKGMapUtils.tolerance(with: tapPoint, andMapView: mapView!, andScreenPercentage: 0.02).screen
        let annotationsTapped = mapView?.annotations(in: MKMapRect(x: mapPoint.x - (tolerance / 2), y: mapPoint.y - (tolerance / 2), width: tolerance, height: tolerance))
        
        var items: [Any] = []
        for mixin in mapMixins {
            if let matchedItems = mixin.items(at: tapCoord) {
                items.append(contentsOf: matchedItems)
            }
        }

        let notification = MapItemsTappedNotification(annotations: annotationsTapped, items: items)
        NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
    }
}

extension MageMapViewController : UIGestureRecognizerDelegate {
    
}
