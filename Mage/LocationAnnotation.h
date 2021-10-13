//
//  Location.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "User.h"
#import "Location.h"
#import "MAGE-Swift.h"

@interface LocationAnnotation : MapAnnotation

@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, weak) User *user;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

- (id)initWithLocation:(Location *) location;
- (id)initWithGPSLocation:(GPSLocation *) location user: (User *) user;

@end
