//
//  SignupDelegate2.h
//  MAGE
//
//  Created by William Newman on 3/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SignupDelegate <NSObject>

- (void) getCaptcha: (NSString *) username completion:(void (^)(NSString* captcha)) completion;
- (void) signupWithParameters: (NSDictionary *) parameters completion:(void (^)(NSHTTPURLResponse *response)) completion;
- (void) signupCanceled;

@end

NS_ASSUME_NONNULL_END
