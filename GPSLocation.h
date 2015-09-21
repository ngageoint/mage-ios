//
//  GPSLocation.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GPSLocation : NSManagedObject

@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) id geometry;
@property (nonatomic, retain) id properties;
@property (nonatomic, retain) NSDate * timestamp;

@end
