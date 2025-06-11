//
//  AuthenticationButton.h
//  MAGE
//
//  Created by William Newman on 6/25/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AuthenticationButtonDelegate

- (void) onAuthenticationButtonTapped:(id) sender;

@end

@interface AuthenticationButton : UIView

@property (strong, nonatomic) NSDictionary *strategy;
@property (weak, nonatomic) id<AuthenticationButtonDelegate> delegate;

- (void) applyThemeWithScheme:(id<AppContainerScheming>)containerScheme;

@end

NS_ASSUME_NONNULL_END
