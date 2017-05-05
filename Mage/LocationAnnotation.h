//
//  Location.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "Location.h"

@interface LocationAnnotation : MapAnnotation

@property (weak, nonatomic) Location *location;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

- (id)initWithLocation:(Location *) location;

@end
