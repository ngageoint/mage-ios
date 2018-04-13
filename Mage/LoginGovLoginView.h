//
//  LoginGovLoginView.h
//  MAGE
//
//  Created by Dan Barela on 4/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthLoginView.h"

@interface LoginGovLoginView : UIView

@property (strong, nonatomic) NSDictionary *strategy;
@property (strong, nonatomic) id<OAuthButtonDelegate> delegate;

@end
