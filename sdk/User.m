//
//  User.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User.h"
#import "Location.h"
#import "Observation.h"
#import "Role.h"
#import "Team.h"

#import "MageSessionManager.h"
#import "MageServer.h"

@implementation User

static User *currentUser = nil;

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    User *user = [User MR_createEntityInContext:context];
    [user updateUserForJson:json];
    
    return user;
}

+ (User *) fetchCurrentUserInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId = %@", [defaults valueForKey:@"currentUserId"]] inContext:managedObjectContext];
}

+ (User *) fetchUserForId:(NSString *) userId inManagedObjectContext: (NSManagedObjectContext *) context {
    return [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId = %@", userId] inContext:context];
}

- (void) updateUserForJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setUsername:[json objectForKey:@"username"]];
    [self setEmail:[json objectForKey:@"email"]];
    [self setName:[json objectForKey:@"displayName"]];
    
    NSArray *phones = [json objectForKey:@"phones"];
    if (phones != nil && [phones count] > 0) {
        NSDictionary *phone = [phones objectAtIndex:0];
        [self setPhone:[phone objectForKey:@"number"]];
    }
    
    [self setIconUrl:[json objectForKey:@"iconUrl"]];
    [self setAvatarUrl:[json objectForKey:@"avatarUrl"]];
    [self setRecentEventIds:[json objectForKey:@"recentEventIds"]];
}

+ (void) pullUserIcon: (User *) user {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *userIconRelativePath = [NSString stringWithFormat:@"userIcons/%@", user.remoteId];
    NSString *userIconPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, userIconRelativePath];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    
    NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:user.iconUrl parameters: nil error: nil];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:userIconPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        if(!error){
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                User *localUser = [user MR_inContext:localContext];
                localUser.iconUrl = userIconRelativePath;
            }];
        }else{
            NSLog(@"Error: %@", error);
            //delete the file
            NSError *deleteError;
            NSString * fileString = [filePath path];
            [[NSFileManager defaultManager] removeItemAtPath:fileString error:&deleteError];
        }
        
    }];
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[userIconPath stringByDeletingLastPathComponent]]) {
        NSLog(@"Creating directory %@", [userIconPath stringByDeletingLastPathComponent]);
        [[NSFileManager defaultManager] createDirectoryAtPath:[userIconPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    [manager addTask:task];
};

+ (void) pullUserAvatar: (User *) user {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *userAvatarRelativePath = [NSString stringWithFormat:@"userAvatars/%@", user.remoteId];
    NSString *userAvatarPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, userAvatarRelativePath];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    
    NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:user.avatarUrl parameters: nil error: nil];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:userAvatarPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        if(!error){
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                User *localUser = [user MR_inContext:localContext];
                localUser.avatarUrl = userAvatarRelativePath;
                NSLog(@"set the avatar url on the user to: %@", localUser.avatarUrl);
            }];
        }else{
            NSLog(@"Error: %@", error);
            //delete the file
            NSError *deleteError;
            NSString * fileString = [filePath path];
            [[NSFileManager defaultManager] removeItemAtPath:fileString error:&deleteError];
        }
        
    }];
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[userAvatarPath stringByDeletingLastPathComponent]]) {
        NSLog(@"Creating directory %@", [userAvatarPath stringByDeletingLastPathComponent]);
        [[NSFileManager defaultManager] createDirectoryAtPath:[userAvatarPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    [manager addTask:task];
}

+ (NSURLSessionDataTask *) operationToFetchUsersWithSuccess: (void (^)(void))success
                                           failure:(void (^)(NSError *error))failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users"];
    
    NSLog(@"Trying to fetch users from server %@", url);
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    
    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id users) {
        
        if ([users isKindOfClass:[NSData class]]) {
            if (((NSData *)users).length == 0) {
                NSLog(@"Users are empty");
                if (success) {
                    success();
                }
                return;
            }
        }
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            // Get roles
            NSMutableDictionary *roleIdMap = [[NSMutableDictionary alloc] init];
            for (Role *role in [Role MR_findAllInContext:localContext]) {
                [roleIdMap setObject:role forKey:role.remoteId];
            }
            
            // Get the user ids to query
            NSMutableArray *userIds = [[NSMutableArray alloc] init];
            for (NSDictionary *userJson in users) {
                [userIds addObject:[userJson objectForKey:@"id"]];
            }
            
            NSArray *usersMatchingIDs = [User MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", userIds] inContext:localContext];
            NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
            for (User* user in usersMatchingIDs) {
                [userIdMap setObject:user forKey:user.remoteId];
            }
            
            for (NSDictionary *userJson in users) {
                // pull from query map
                NSString *userId = [userJson objectForKey:@"id"];
                User *user = [userIdMap objectForKey:userId];
                if (user == nil) {
                    // not in core data yet need to create a new managed object
                    NSLog(@"Inserting new user into database");
                    user = [User insertUserForJson:userJson inManagedObjectContext:localContext];
                    
                    
                    // go pull their icon and avatar if they have one
                    if (user.iconUrl != nil) {
                        [User pullUserIcon:user];
                    }
                    if (user.avatarUrl != nil) {
                        [User pullUserAvatar:user];
                    }
                } else {
                    // already exists in core data, lets update the object we have
                    NSLog(@"Updating user location in the database");
                    NSString *oldIcon = user.iconUrl;
                    NSString *oldAvatar = user.avatarUrl;
                    
                    [user updateUserForJson:userJson];
                    // go pull their icon and avatar if they got one
                    if ([[oldIcon lowercaseString] hasPrefix:@"http"] || (oldIcon == nil && user.iconUrl != nil)) {
                        [User pullUserIcon:user];
                    } else {
                        user.iconUrl = oldIcon;
                    }
                    if ([[oldAvatar lowercaseString] hasPrefix:@"http"] || (oldAvatar == nil && user.avatarUrl != nil)) {
                        [User pullUserAvatar:user];
                    } else {
                        user.avatarUrl = oldAvatar;
                    }
                }
                
                // grap and assign role to user
                Role *role = [roleIdMap objectForKey:[userJson objectForKey:@"roleId"]];
                if (role) {
                    user.role = role;
                    [role addUsersObject:user];
                }
            }
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
                success();
            }
        }];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        failure(error);
    }];
    
    return task;
}

+ (NSURLSessionDataTask *) operationToFetchMyselfWithSuccess: (void (^)(void))success
                                            failure:(void (^)(NSError *error))failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users/myself"];
    
    NSLog(@"Fetching myself from server %@", url);
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    
    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id myself) {
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            
            User *user = [User MR_findFirstByAttribute:@"remoteId" withValue:[myself objectForKey:@"id"] inContext:localContext];
            if (user == nil) {
                user = [User insertUserForJson:myself inManagedObjectContext:localContext];
                if (user.iconUrl != nil) {
                    [User pullUserIcon:user];
                }
                if (user.avatarUrl != nil) {
                    [User pullUserAvatar:user];
                }
            } else {
                NSString *oldIcon = user.iconUrl;
                NSString *oldAvatar = user.avatarUrl;
                
                [user updateUserForJson:myself];
                // go pull their icon and avatar if they got one
                if ([[oldIcon lowercaseString] hasPrefix:@"http"] || (oldIcon == nil && user.iconUrl != nil)) {
                    [User pullUserIcon:user];
                } else {
                    user.iconUrl = oldIcon;
                }
                if ([[oldAvatar lowercaseString] hasPrefix:@"http"] || (oldAvatar == nil && user.avatarUrl != nil)) {
                    [User pullUserAvatar:user];
                } else {
                    user.avatarUrl = oldAvatar;
                }
                NSDictionary *myRole = [myself objectForKey:@"role"];
                if (myRole != nil) {
                    Role *role = [Role MR_findFirstByAttribute:@"remoteId" withValue:[myRole objectForKey:@"id"] inContext:localContext];
                    if (role == nil) {
                        role = [Role insertRoleForJson:myRole inManagedObjectContext:localContext];
                    }

                    if (role) {
                        user.role = role;
                        [role addUsersObject:user];
                    }
                }
                
            }
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
                success();
            }
        }];

    } failure:^(NSURLSessionTask *operation, NSError *error) {
        failure(error);
    }];
    
    return task;
}

- (BOOL) hasEditPermission {
    return [self.role.permissions containsObject:@"UPDATE_OBSERVATION_ALL"] || [self.role.permissions containsObject:@"UPDATE_OBSERVATION_EVENT"];
}

@end
