//
//  ContactInfo.h
//  MAGE
//
//  Created by Kevin Gilland on 9/22/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContactInfo : NSObject

/**
 *  Message
 */
@property (nonatomic, strong) NSString *title;

/**
 *  Message
 */
@property (nonatomic, strong) NSString *message;

/**
 *  Identifier
 */
@property (nonatomic, strong) NSString *identifier;

/**
 *  strategy
 */
@property (nonatomic, strong) NSString *strategy;

- (instancetype) initWithTitle: (NSString *)title andMessage: (NSString *) message;

- (NSAttributedString *) messageWithContactInfo;

@end

NS_ASSUME_NONNULL_END
