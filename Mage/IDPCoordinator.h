//
//  IDPCoordinator.h
//  MAGE
//
//  Created by William Newman on 5/18/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdpAuthentication.h"
#import "LoginViewController.h"
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface IDPCoordinator : NSObject<SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate>

- (instancetype) initWithViewController: (UIViewController *) viewController url: (NSString *) url strategy: (NSDictionary *) strategy delegate: (id<LoginDelegate>) delegate;
- (void) start;

@end

NS_ASSUME_NONNULL_END
