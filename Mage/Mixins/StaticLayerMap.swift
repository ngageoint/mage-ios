//
//  StaticLayerMap.swift
//  MAGE
//
//  Created by Daniel Barela on 1/27/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework
import CoreData
import geopackage_ios

protocol StaticLayerMap {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var staticLayerMapMixin: StaticLayerMapMixin? { get set }
}

class StaticLayerMapMixin: NSObject, MapMixin {
    var mapAnnotationFocusedObserver: AnyObject?

    var staticLayerMap: StaticLayerMap
    var staticLayers: [NSNumber:[Any]] = [:]
    var enlargedAnnotationView: MKAnnotationView?
    
    init(staticLayerMap: StaticLayerMap) {
        self.staticLayerMap = staticLayerMap
    }
    
    func cleanupMixin() {
        if let mapAnnotationFocusedObserver = mapAnnotationFocusedObserver {
            NotificationCenter.default.removeObserver(mapAnnotationFocusedObserver, name: .MapAnnotationFocused, object: nil)
        }
        mapAnnotationFocusedObserver = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: "selectedStaticLayers")
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        mapAnnotationFocusedObserver = NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            if let notificationObject = (notification.object as? MapAnnotationFocusedNotification), notificationObject.mapView == self?.staticLayerMap.mapView {
                self?.focusAnnotation(annotation: notificationObject.annotation)
            } else if notification.object == nil {
                self?.focusAnnotation(annotation: nil)
            }
        }
        UserDefaults.standard.addObserver(self, forKeyPath: "selectedStaticLayers", options: [.new], context: nil)
        updateStaticLayers()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateStaticLayers()
    }
    
    func updateStaticLayers() {
        var unselectedStaticLayerIds: [NSNumber] = staticLayers.map({ $0.key })
        
        guard let staticLayersPerEvent = UserDefaults.standard.selectedStaticLayers, let currentEvent = Server.currentEventId() else {
            return
        }
        
        let staticLayersInEvent = staticLayersPerEvent[currentEvent.stringValue] ?? []
        for staticLayerId in staticLayersInEvent {
            guard let staticLayer = StaticLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", staticLayerId, currentEvent), in: NSManagedObjectContext.mr_default()) else {
                continue
            }
            if !unselectedStaticLayerIds.contains(staticLayerId) {
                print("Adding the static layer \(staticLayer.name ?? "No Name") to the map")
                guard let features = staticLayer.features else {
                    continue
                }
                var annotations: [Any] = []
                for feature in features {
                    guard let featureType = StaticLayer.featureType(feature: feature) else {
                        continue
                    }
                    if featureType == "Point" {
                        if let annotation = StaticPointAnnotation(feature: feature) {
                            annotation.layerName = staticLayer.name
                            annotation.title = StaticLayer.featureName(feature: feature)
                            annotation.subtitle = StaticLayer.featureDescription(feature: feature)
                            staticLayerMap.mapView?.addAnnotation(annotation)
                            annotations.append(annotation)
                        }
                    } else if featureType == "Polygon" {
                        if let coordinates = StaticLayer.featureCoordinates(feature: feature) {
                            let polygon = StyledPolygon.generate(coordinates: coordinates as? [[[NSNumber]]] ?? [])
                            let fillOpacity = StaticLayer.featureFillOpacity(feature: feature)
                            let fillAlpha = fillOpacity / 255.0
                            polygon.setFillColor(hex: StaticLayer.featureFillColor(feature: feature), alpha: fillAlpha)
                            
                            let lineOpacity = staticLayer.featureLineOpacity(feature: feature)
                            let lineAlpha = lineOpacity / 255.0
                            polygon.setLineColor(hex: StaticLayer.featureLineColor(feature: feature), alpha: lineAlpha)
                            
                            polygon.lineWidth = StaticLayer.featureLineWidth(feature: feature)
                            
                            polygon.title = StaticLayer.featureName(feature: feature)
                            polygon.subtitle = StaticLayer.featureDescription(feature: feature)
                            
                            annotations.append(polygon)
                            staticLayerMap.mapView?.addOverlay(polygon)
                        }
                    } else if featureType == "LineString" {
                        if let coordinates = StaticLayer.featureCoordinates(feature: feature) {
                            let polyline = StyledPolyline.generate(path: coordinates as? [[NSNumber]] ?? [])
                            
                            let lineOpacity = staticLayer.featureLineOpacity(feature: feature)
                            let lineAlpha = lineOpacity / 255.0
                            polyline.setLineColor(hex: StaticLayer.featureLineColor(feature: feature), alpha: lineAlpha)
                            polyline.lineWidth = StaticLayer.featureLineWidth(feature: feature)
                            
                            polyline.title = StaticLayer.featureName(feature: feature)
                            polyline.subtitle = StaticLayer.featureDescription(feature: feature)
                            
                            annotations.append(polyline)
                            staticLayerMap.mapView?.addOverlay(polyline)
                        }
                    }
                }
                staticLayers[staticLayerId] = annotations
            }
            
            if let index = unselectedStaticLayerIds.firstIndex(of: staticLayerId) {
                unselectedStaticLayerIds.remove(at: index)
            }
        }
        
        for unselectedStaticLayerId in unselectedStaticLayerIds {
            if let unselectedStaticLayer = StaticLayer.mr_findFirst(byAttribute: "remoteId", withValue: unselectedStaticLayerId), let staticItems = staticLayers[unselectedStaticLayerId] {
                print("removing the layer \(unselectedStaticLayer.name ?? "No Name") from the map")
                for staticItem in staticItems {
                    if let overlay = staticItem as? MKOverlay {
                        staticLayerMap.mapView?.removeOverlay(overlay)
                    } else if let annotation = staticItem as? MKAnnotation {
                        staticLayerMap.mapView?.removeAnnotation(annotation)
                    }
                }
                staticLayers.removeValue(forKey: unselectedStaticLayerId)
            }
        }
    }
    
    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String : [String]] {
        let screenPercentage = UserDefaults.standard.shapeScreenClickPercentage
        let tolerance = await (self.staticLayerMap.mapView?.visibleMapRect.size.width ?? 0) * Double(screenPercentage)
        
        var annotations: [FeatureItem] = []
        
        for (layerId, features) in staticLayers {
            for feature in features {
                if let polyline = feature as? StyledPolyline {
                    if lineHitTest(lineObservation: polyline, location: location, tolerance: tolerance) {
                        if let currentEventId = Server.currentEventId(), let staticLayer = StaticLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", layerId, currentEventId), in: NSManagedObjectContext.mr_default()) {
                            annotations.append(FeatureItem(featureId: 0, featureDetail: polyline.subtitle, coordinate: location, featureTitle: polyline.title, layerName: staticLayer.name, iconURL: nil))
                        }
                    }
                } else if let polygon = feature as? StyledPolygon {
                    if polygonHitTest(polygonObservation: polygon, location: location) {
                        if let currentEventId = Server.currentEventId(), let staticLayer = StaticLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", layerId, currentEventId), in: NSManagedObjectContext.mr_default()) {
                            annotations.append(FeatureItem(featureId: 0, featureDetail: polygon.subtitle, coordinate: location, featureTitle: polygon.title, layerName: staticLayer.name, iconURL: nil))
                        }
                    }
                }
            }
        }
        return [DataSources.featureItem.key: annotations.map({ featureItem in
            featureItem.toKey()
        })]
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let annotation = annotation as? StaticPointAnnotation else {
            return nil
        }
        
        return annotation.viewForAnnotation(on: mapView, scheme: staticLayerMap.scheme)
    }
    
    func focusAnnotation(annotation: MKAnnotation?) {
        guard let annotation = annotation as? StaticPointAnnotation,
              let annotationView = staticLayerMap.mapView?.view(for: annotation) else {
                  if let enlargedAnnotationView = enlargedAnnotationView {
                      // shrink the old focused view
                      UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                          enlargedAnnotationView.transform = enlargedAnnotationView.transform.scaledBy(x: 0.5, y: 0.5)
                          enlargedAnnotationView.centerOffset = CGPoint(x: 0, y: enlargedAnnotationView.centerOffset.y / 2.0)
                      } completion: { success in
                      }
                      self.enlargedAnnotationView = nil
                  }
                  return
              }
        
        if annotationView == enlargedAnnotationView {
            // already focused ignore
            return
        } else if let enlargedLocationView = enlargedAnnotationView {
            // shrink the old focused view
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                enlargedLocationView.transform = enlargedLocationView.transform.scaledBy(x: 0.5, y: 0.5)
                enlargedLocationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y / 2.0)
            } completion: { success in
            }
        }
        
        enlargedAnnotationView = annotationView
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            annotationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y * 2.0)
        } completion: { success in
        }
    }
}
