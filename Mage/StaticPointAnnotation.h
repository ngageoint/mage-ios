//
//  StaticPointAnnotation.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface StaticPointAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (weak, nonatomic) NSDictionary *feature;
@property (weak, nonatomic) NSString *iconUrl;

- (id)initWithFeature:(NSDictionary *) feature;
- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView;

@end
