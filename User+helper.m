//
//  User+helper.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User+helper.h"

@implementation User (helper)

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
	User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];

	[user updateUserForJson:json inManagedObjectContext:context];
		
	return user;
}

+ (User *) fetchUserForId:(NSString *) userId  inManagedObjectContext: (NSManagedObjectContext *) context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:context]];
	[request setPredicate: [NSPredicate predicateWithFormat:@"(remoteId = %@)", userId]];
	[request setFetchLimit:1];
	
	NSError *error;
	NSArray *users = [context executeFetchRequest:request error:&error];
	
	if (error || users.count < 1) {
		NSLog(@"Error getting user from database for id: %@", userId);
		return nil;
	}
		
	return [users objectAtIndex:0];
}

- (void) updateUserForJson: (NSDictionary *) json  inManagedObjectContext:(NSManagedObjectContext *) context {
	[self setRemoteId:[json objectForKey:@"_id"]];
	[self setUsername:[json objectForKey:@"username"]];
	[self setEmail:[json objectForKey:@"email"]];
	[self setName:[NSString stringWithFormat:@"%@ %@", [json objectForKey:@"firstname"], [json objectForKey:@"lastname"]]];
	
	NSError *error = nil;
	if (! [context save:&error]) {
		NSLog(@"Error updating User: %@", error);
	}
}




@end
