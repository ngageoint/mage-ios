//
//  Layer.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Layer : NSManagedObject

@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) NSString * formId;
@property (nonatomic, retain) NSNumber * loaded;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;

@end
