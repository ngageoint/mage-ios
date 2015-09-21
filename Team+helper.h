//
//  Team+helper.h
//  mage-ios-sdk
//
//

#import "Team.h"

@interface Team (helper)

- (void) updateTeamForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;
+ (Team *) insertTeamForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;

@end
