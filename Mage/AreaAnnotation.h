//
//  AreaAnnotation.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AreaAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView;
- (void) setTitle:(NSString *)title;

@end
