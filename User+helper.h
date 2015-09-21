//
//  User+helper.h
//  mage-ios-sdk
//
//

#import "User.h"

@interface User (helper)

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;
+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;
+ (User *) fetchUserForId:(NSString *) userId inManagedObjectContext: (NSManagedObjectContext *) context;
+ (User *) fetchCurrentUserInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
+ (NSOperation *) operationToFetchMyselfWithSuccess: (void(^)()) success failure: (void(^)(NSError *)) failure;
+ (NSOperation *) operationToFetchUsersWithSuccess: (void(^)()) success failure: (void(^)(NSError *)) failure;

- (void) updateUserForJson: (NSDictionary *) json;

@end
