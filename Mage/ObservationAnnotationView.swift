//
//  ObservationAnnotationView.m
//  MAGE
//
//  Created by William Newman on 1/19/16.
//

import Foundation
import MapKit

@objc class ObservationAnnotationView : MKAnnotationView {
    
    var mapView: MKMapView
    var dragCallback: AnnotationDragCallback?
    
    @objc public init(annotation: MKAnnotation?, reuseIdentifier: String, mapView: MKMapView, dragCallback: AnnotationDragCallback?) {
        self.mapView = mapView
        self.dragCallback = dragCallback
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var center: CGPoint {
        set {
            super.center = newValue
            if let dragCallback = dragCallback {
                let point = CGPoint(x: newValue.x, y: newValue.y - centerOffset.y)
                let coordinate = mapView.convert(point, toCoordinateFrom: superview)
                dragCallback.dragging(self, at: coordinate)
            }
        }
        get {
            return super.center
        }
    }
    
    override func setDragState(_ newDragState: MKAnnotationView.DragState, animated: Bool) {
        super.setDragState(newDragState, animated: animated)
        if newDragState == .starting {
            UIView.animate(withDuration: 0.3) {
                var imageFrame = self.frame
                imageFrame.origin.y = imageFrame.origin.y - (self.image?.size.height ?? 0.0)
                self.frame = imageFrame
            } completion: { finished in
                self.dragState = .dragging
            }
        } else if newDragState == .ending {
            UIView.animate(withDuration: 0.2) {
                var imageFrame = self.frame
                imageFrame.origin.y = imageFrame.origin.y - ((self.image?.size.height ?? 0.0) / 2)
                self.frame = imageFrame
            } completion: { finished in
                UIView.animate(withDuration: 0.2) {
                    var imageFrame = self.frame
                    imageFrame.origin.y = imageFrame.origin.y + ((self.image?.size.height ?? 0.0) / 2)
                    self.frame = imageFrame
                } completion: { finished in
                    self.dragState = .none
                }
            }
        } else if newDragState == .canceling {
            UIView.animate(withDuration: 0.2) {
                var imageFrame = self.frame
                imageFrame.origin.y = imageFrame.origin.y + (self.image?.size.height ?? 0.0)
                self.frame = imageFrame
            } completion: { finished in
                self.dragState = .none
            }
        }
    }
}
