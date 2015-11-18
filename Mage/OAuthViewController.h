//
//  OAuthViewController.h
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MageServer.h"
#import "OAuthAuthentication.h"

@interface OAuthViewController : UIViewController

@property (weak, nonatomic) NSString *url;
@property (weak, nonatomic) MageServer *server;
@property (assign, nonatomic) AuthenticationType authenticationType;
@property (assign, nonatomic) OAuthRequestType requestType;
@end
