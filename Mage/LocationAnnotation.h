//
//  Location.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"

@interface LocationAnnotation : MapAnnotation

@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, strong) NSManagedObject *user;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

- (id)initWithLocation:(NSManagedObject *) location;
- (id)initWithGPSLocation:(NSManagedObject *) location user: (NSManagedObject *) user;

@end
