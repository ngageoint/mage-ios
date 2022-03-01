//
//  StaticLayerMap.swift
//  MAGE
//
//  Created by Daniel Barela on 1/27/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import geopackage_ios

protocol StaticLayerMap {
    var mapView: MKMapView? { get set }
    var staticLayerMapMixin: StaticLayerMapMixin? { get set }
}

class StaticLayerMapMixin: NSObject, MapMixin {
    var mapAnnotationFocusedObserver: AnyObject?

    var staticLayerMap: StaticLayerMap?
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?
    var staticLayers: [NSNumber:[Any]] = [:]
    var enlargedAnnotationView: MKAnnotationView?
    
    init(staticLayerMap: StaticLayerMap, scheme: MDCContainerScheming?) {
        self.staticLayerMap = staticLayerMap
        self.mapView = staticLayerMap.mapView
        self.scheme = scheme
    }
    
    deinit {
        if let mapAnnotationFocusedObserver = mapAnnotationFocusedObserver {
            NotificationCenter.default.removeObserver(mapAnnotationFocusedObserver, name: .MapAnnotationFocused, object: nil)
        }
        mapAnnotationFocusedObserver = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: "selectedStaticLayers")
    }
    
    func setupMixin() {
        mapAnnotationFocusedObserver = NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            if let notificationObject = (notification.object as? MapAnnotationFocusedNotification), notificationObject.mapView == self?.mapView {
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
                            mapView?.addAnnotation(annotation)
                            annotations.append(annotation)
                        }
                    } else if featureType == "Polygon" {
                        if let coordinates = StaticLayer.featureCoordinates(feature: feature) {
                            let polygon = StyledPolygon.generate(coordinates)
                            let fillOpacity = StaticLayer.featureFillOpacity(feature: feature)
                            let fillAlpha = fillOpacity / 255.0
                            polygon.fillColor(withHexString: StaticLayer.featureFillColor(feature: feature), andAlpha: fillAlpha)
                            
                            let lineOpacity = staticLayer.featureLineOpacity(feature: feature)
                            let lineAlpha = lineOpacity / 255.0
                            polygon.lineColor(withHexString: StaticLayer.featureLineColor(feature: feature), andAlpha: lineAlpha)
                            
                            polygon.lineWidth = StaticLayer.featureLineWidth(feature: feature)
                            
                            polygon.title = StaticLayer.featureName(feature: feature)
                            polygon.subtitle = StaticLayer.featureDescription(feature: feature)
                            
                            annotations.append(polygon)
                            mapView?.addOverlay(polygon)
                        }
                    } else if featureType == "LineString" {
                        if let coordinates = StaticLayer.featureCoordinates(feature: feature) {
                            let polyline = StyledPolyline.generate(coordinates)
                            
                            let lineOpacity = staticLayer.featureLineOpacity(feature: feature)
                            let lineAlpha = lineOpacity / 255.0
                            polyline.lineColor(withHexString: StaticLayer.featureLineColor(feature: feature), andAlpha: lineAlpha)
                            
                            polyline.lineWidth = StaticLayer.featureLineWidth(feature: feature)
                            
                            polyline.title = StaticLayer.featureName(feature: feature)
                            polyline.subtitle = StaticLayer.featureDescription(feature: feature)
                            
                            annotations.append(polyline)
                            mapView?.addOverlay(polyline)
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
                        mapView?.removeOverlay(overlay)
                    } else if let annotation = staticItem as? MKAnnotation {
                        mapView?.removeAnnotation(annotation)
                    }
                }
                staticLayers.removeValue(forKey: unselectedStaticLayerId)
            }
        }
    }
    
    func items(at location: CLLocationCoordinate2D) -> [Any]? {
        let screenPercentage = UserDefaults.standard.shapeScreenClickPercentage
        let tolerance = (self.mapView?.visibleMapRect.size.width ?? 0) * Double(screenPercentage)
        
        var annotations: [Any] = []
        
        for (layerId, features) in staticLayers {
            for feature in features {
                if let polyline = feature as? StyledPolyline {
                    if lineHitTest(lineObservation: polyline, location: location, tolerance: tolerance) {
                        if let currentEventId = Server.currentEventId(), let staticLayer = StaticLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", layerId, currentEventId), in: NSManagedObjectContext.mr_default()) {
                            annotations.append(FeatureItem(featureId: 0, featureDetail: polyline.subtitle, coordinate: location, featureTitle: polyline.title, layerName: staticLayer.name, iconURL: nil, images: nil))
                        }
                    }
                } else if let polygon = feature as? StyledPolygon {
                    if polygonHitTest(polygonObservation: polygon, location: location) {
                        if let currentEventId = Server.currentEventId(), let staticLayer = StaticLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", layerId, currentEventId), in: NSManagedObjectContext.mr_default()) {
                            annotations.append(FeatureItem(featureId: 0, featureDetail: polygon.subtitle, coordinate: location, featureTitle: polygon.title, layerName: staticLayer.name, iconURL: nil, images: nil))
                        }
                    }
                }
            }
        }
        return annotations
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let annotation = annotation as? StaticPointAnnotation else {
            return nil
        }
        
        return annotation.viewForAnnotation(on: mapView, scheme: scheme)
    }
    
    func focusAnnotation(annotation: MKAnnotation?) {
        guard let annotation = annotation as? StaticPointAnnotation,
              let annotationView = mapView?.view(for: annotation) else {
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
