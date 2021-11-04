//
//  LinkGenerator.h
//  MAGE
//
//  Created by Kevin Gilland on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LinkGenerator : NSObject

+(NSString *) emailLinkWithMessage: (NSString *)message andIdentifier: (NSString *)ident andStrategy: (NSString *) strategy;
+(NSString *) phoneLink;

@end

NS_ASSUME_NONNULL_END
