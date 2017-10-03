//
//  ObservationAnnotationView.h
//  MAGE
//
//  Created by William Newman on 1/19/16.
//

#import <MapKit/MapKit.h>
#import "AnnotationDragCallback.h"

@interface ObservationAnnotationView : MKAnnotationView

- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier andMapView: (MKMapView *) mapView andDragCallback: (NSObject<AnnotationDragCallback> *) dragCallback;

@end
