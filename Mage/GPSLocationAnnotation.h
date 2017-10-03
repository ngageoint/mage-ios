//
//  GPSLocationAnnotation.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <GPSLocation.h>
#import <User.h>
#import "MapAnnotation.h"

@interface GPSLocationAnnotation : MapAnnotation

@property (weak, nonatomic) GPSLocation *gpsLocation;
@property (weak, nonatomic) User *user;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

- (id)initWithGPSLocation:(GPSLocation *) location andUser: (User *) user;

@end
