//
//  Event.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Team;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) id form;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * recentSortOrder;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSSet *teams;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addTeamsObject:(Team *)value;
- (void)removeTeamsObject:(Team *)value;
- (void)addTeams:(NSSet *)values;
- (void)removeTeams:(NSSet *)values;

@end
