//
//  Team.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event, User;

@interface Team : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSString * teamDescription;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *users;
@end

@interface Team (CoreDataGeneratedAccessors)

- (void)addEventsObject:(Event *)value;
- (void)removeEventsObject:(Event *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
