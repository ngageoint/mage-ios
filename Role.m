//
//  Role.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Role.h"
#import "MageServer.h"
#import "HttpManager.h"

@implementation Role

+ (Role *) insertRoleForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    Role *role = [Role MR_createEntityInContext:context];
    [role updateRoleForJson:json];
    
    return role;
}

- (void) updateRoleForJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setPermissions:[json objectForKey:@"permissions"]];
}

+ (NSURLSessionDataTask *) operationToFetchRolesWithSuccess:(void (^ _Nullable)()) success
                                           failure:(void (^ _Nullable)(NSError *error)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/roles"];
    
    NSLog(@"Trying to fetch users from server %@", url);
    
    HttpManager *http = [HttpManager singleton];
    NSURLSessionDataTask *task = [http.manager GET:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id roles) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            // Get the user ids to query
            NSMutableArray *roleIds = [[NSMutableArray alloc] init];
            for (NSDictionary *roleJson in roles) {
                [roleIds addObject:[roleJson objectForKey:@"id"]];
            }
            
            NSArray *rolesMatchingIds = [Role MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", roleIds] inContext:localContext];
            NSMutableDictionary *roleIdMap = [[NSMutableDictionary alloc] init];
            for (Role* role in rolesMatchingIds) {
                [roleIdMap setObject:role forKey:role.remoteId];
            }
            
            for (NSDictionary *roleJson in roles) {
                // pull from query map
                NSString *roleId = [roleJson objectForKey:@"id"];
                Role *role = [roleIdMap objectForKey:roleId];
                if (role == nil) {
                    // not in core data yet need to create a new managed object
                    NSLog(@"Inserting new role into database");
                    [Role insertRoleForJson:roleJson inManagedObjectContext:localContext];
                } else {
                    // already exists in core data, lets update the object we have
                    NSLog(@"Updating role in the database");
                    [role updateRoleForJson:roleJson];
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
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}
@end
