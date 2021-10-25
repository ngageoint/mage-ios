//
//  Location.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"

@class User;
@class Location;
@class GPSLocation;

@interface LocationAnnotation : MapAnnotation

@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, strong) User *user;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

- (id)initWithLocation:(Location *) location;
- (id)initWithGPSLocation:(GPSLocation *) location user: (User *) user;

@end
