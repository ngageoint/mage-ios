//
//  Location.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "Location.h"

@interface LocationAnnotation : NSObject <MKAnnotation>

@property (weak, nonatomic) Location *location;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *name;

- (id)initWithLocation:(Location *) location;

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView;

-(void) setSubtitle:(NSString *)subtitle;

@end
