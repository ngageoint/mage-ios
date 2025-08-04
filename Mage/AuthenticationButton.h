//
//  AuthenticationButton.h
//  MAGE
//
//  Created by William Newman on 6/25/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDPLoginView.h"
@import MaterialComponents;

NS_ASSUME_NONNULL_BEGIN

@interface AuthenticationButton : UIView

@property (strong, nonatomic) NSDictionary *strategy;
@property (weak, nonatomic) id<IDPButtonDelegate> delegate;

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end

NS_ASSUME_NONNULL_END
