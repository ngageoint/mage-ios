//
//  EmailBuilder.h
//  MAGE
//
//  Created by Kevin Gilland on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmailBuilder : NSObject

/**
 *  Message
 */
@property (nonatomic, strong) NSString *message;

/**
 *  Username
 */
@property (nonatomic, strong) NSString *username;

/**
 *  Strategy
 */
@property (nonatomic, strong) NSString *strategy;

/**
 *  Subject
 */
@property (nonatomic, strong) NSString *subject;

/**
 *  Body
 */
@property (nonatomic, strong) NSString *body;

-(instancetype) initWithMessage: (NSString *)message andUsername: (NSString *)username andStrategy: (NSString *)strategy;

-(void) build;

@end

NS_ASSUME_NONNULL_END

