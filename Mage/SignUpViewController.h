//
//  SignUpViewController.h
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MageServer.h"
#import "SignUpDelegate.h"

@interface SignUpViewController : UIViewController

- (instancetype) initWithServer: (MageServer *) server andDelegate: (id<SignUpDelegate>) delegate;

@end
