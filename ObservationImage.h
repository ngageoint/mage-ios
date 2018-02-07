//
//  ObservationImage.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Observation.h>

@interface ObservationImage : NSObject

+ (NSString *) imageNameForObservation:(Observation *) observation;
+ (UIImage *) imageForObservation:(Observation *) observation;
+ (UIImage *) imageForObservation:(Observation *) observation inMapView: (MKMapView *) mapView;
+ (UIImage *) scaledImageForObservation: (Observation *) observation;

@end
