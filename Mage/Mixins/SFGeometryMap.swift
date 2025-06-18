//
//  SFGeometryMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/17/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework
import sf_ios
import sf_geojson_ios

protocol SFGeometryMap {
    var mapView: MKMapView? { get set }
    var scheme: AppContainerScheming? { get set }
    var sfGeometryMapMixin: SFGeometryMapMixin? { get set }
}

class SFGeometryMapMixin: NSObject, MapMixin {
    var sfGeometryMap: SFGeometryMap
    var _sfGeometry: SFGeometry?
    var sfGeometry: SFGeometry? {
        get {
            return _sfGeometry
        }
        set {
            replaceSFGeometry(sfGeometry: newValue)
            _sfGeometry = newValue
        }
    }
    var geometryToShape: [SFGeometry : GPKGMapShape] = [:]
    
    init(sfGeometryMap: SFGeometryMap, sfGeometry: SFGeometry?) {
        self.sfGeometryMap = sfGeometryMap
        self._sfGeometry = sfGeometry
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        addSFGeometry(sfGeometry: sfGeometry)
    }
    
    func addSFGeometry(sfGeometry: SFGeometry?) {
        guard let sfGeometry = sfGeometry, let mapView = sfGeometryMap.mapView else {
            return
        }
        let shapeConverter: GPKGMapShapeConverter = GPKGMapShapeConverter()
        let shape = shapeConverter.add(sfGeometry, to: mapView)
        shapeConverter.close()
        geometryToShape[sfGeometry] = shape
    }
    
    func removeSFGeometry(sfGeometry: SFGeometry?) {
        if let sfGeometry = sfGeometry, let shape = geometryToShape[sfGeometry], let mapView = sfGeometryMap.mapView {
            shape.remove(from: mapView)
            geometryToShape.removeValue(forKey: sfGeometry)
        }
    }
    
    func replaceSFGeometry(sfGeometry: SFGeometry?) {
        removeSFGeometry(sfGeometry: self.sfGeometry)
        addSFGeometry(sfGeometry: sfGeometry)
        setMapRegion(sfGeometry: sfGeometry)
    }
    
    func setMapRegion(sfGeometry: SFGeometry?) {
        var latitudeMeters = 2500.0
        var longitudeMeters = 2500.0
        if let geometry = sfGeometry {

            let envelope = SFGeometryEnvelopeBuilder.buildEnvelope(with: geometry)
            let boundingBox = GPKGBoundingBox(envelope: envelope)
            if let size = boundingBox?.sizeInMeters() {
                latitudeMeters = size.height + (2 * (size.height * 0.1))
                longitudeMeters = size.width + (2 * (size.width * 0.1))
                
            }
            
            if let centroid = geometry.centroid() {
                let mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue), latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters)
                sfGeometryMap.mapView?.setRegion(mapRegion, animated: true)
                return
            }
        }
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let polygon = overlay as? GPKGPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            if let options = polygon.options {
                renderer.fillColor = options.fillColor
                renderer.strokeColor = options.strokeColor
                renderer.lineWidth = options.lineWidth
            } else {
                renderer.fillColor = (sfGeometryMap.scheme?.colorScheme.primaryColor ?? .label).withAlphaComponent(0.2)
                renderer.strokeColor = sfGeometryMap.scheme?.colorScheme.primaryColor ?? .label
                renderer.lineWidth = 1
            }
            return renderer
        } else if let polyline = overlay as? GPKGPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            if let options = polyline.options {
                renderer.strokeColor = options.strokeColor
                renderer.lineWidth = options.lineWidth
            } else {
                renderer.strokeColor = sfGeometryMap.scheme?.colorScheme.primaryColor ?? .label
                renderer.lineWidth = 1
            }
            return renderer
        }
        return nil
    }
}
