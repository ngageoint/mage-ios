//
//  ObservationAnnotation.m
//  Mage
//
//

import Foundation
import CoreLocation
import MapKit
import DateTools

@objc class ObservationAnnotation : MapAnnotation {
    
    let OBSERVATION_ANNOTATION_VIEW_REUSE_ID = "OBSERVATION_ICON"
    
    @objc public var timestamp: Date?
    @objc public var name: String?
    @objc public var _observation: Observation?
    @objc public var selected: Bool = false
    @objc public var animateDrop: Bool = false
    var point: Bool = false
    var observationId: String?
    
    @objc public var observation: Observation? {
        get {
            guard let observationId = observationId else {
                return _observation
            }

            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            
            guard let context = context else { return nil }
            return Observation.mr_findFirst(byAttribute: "remoteId", withValue: observationId, in: context)
        }
    }
    
    @objc public convenience init(observation: Observation, geometry: SFGeometry? = nil) {
        
        let geometry: SFGeometry? = geometry ?? observation.geometry
        guard let geometry = geometry else {
            self.init()
            return;
        }
        let point = SFGeometryUtils.centroid(of: geometry)
        if let y = point?.y, let x = point?.x {
            let location = CLLocationCoordinate2D(latitude: y.doubleValue, longitude: x.doubleValue)
            self.init(observation: observation, location: location)
            self.point = true
        } else {
            self.init()
        }
    }
    
    @objc public convenience init(observation: Observation, location: CLLocationCoordinate2D) {
        self.init()
      
        observationId = observation.remoteId
        if observationId == nil {
            self._observation = observation
        }
      
        // If observation is locally modified but not yet saved, annotation uses the modified copy.
        if observation.isDirty {
          observationId = nil
          self._observation = observation
        }
      
        self.coordinate = location
//        self.title = observation.primaryFeedFieldText
        if self.title == nil || self.title.count == 0 {
            self.title = "Observation"
        }
        if let dateTimestamp = observation.timestamp as NSDate? {
            self.subtitle = dateTimestamp.timeAgoSinceNow()
        }
        
        self.accessibilityLabel = "Observation Annotation"
        self.accessibilityValue = "Observation Annotation"
    }
    
    @objc public override func viewForAnnotation(on: MKMapView, scheme: MDCContainerScheming) -> MKAnnotationView {
        return viewForAnnotation(on: on, with: nil, scheme: scheme)
    }
    
    @objc public override func viewForAnnotation(on: MKMapView, with: AnnotationDragCallback?, scheme: MDCContainerScheming) -> MKAnnotationView {
        var annotationView = on.dequeueReusableAnnotationView(withIdentifier: OBSERVATION_ANNOTATION_VIEW_REUSE_ID)
        
        if let annotationView = annotationView {
            annotationView.annotation = self
        } else {
            annotationView = ObservationAnnotationView(annotation: self, reuseIdentifier: OBSERVATION_ANNOTATION_VIEW_REUSE_ID, mapView: on, dragCallback: with)
            annotationView?.isEnabled = true
        }
        
        if point {
            if let observation = observation {
                @Injected(\.observationImageRepository)
                var imageRepository: ObservationImageRepository
                
                let image = imageRepository.image(observation: observation);
                annotationView?.image = image;
                annotationView?.centerOffset = CGPoint(x: 0, y: -(image.size.height/2.0))
            }
        } else {
            annotationView?.image = nil
            annotationView?.frame = .zero
            annotationView?.centerOffset = .zero
        }
        if let annotationView = annotationView {
            annotationView.accessibilityLabel = "Observation"
            annotationView.accessibilityValue = "Observation"
            annotationView.displayPriority = .required
            view = annotationView
            return annotationView
        } else {
            return MKAnnotationView(annotation: self, reuseIdentifier: OBSERVATION_ANNOTATION_VIEW_REUSE_ID)
        }
    }
}
