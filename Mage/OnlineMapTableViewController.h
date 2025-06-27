//
//  OnlineMapTableViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

NS_ASSUME_NONNULL_BEGIN

@interface OnlineMapTableViewController : UITableViewController

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme;

@end

NS_ASSUME_NONNULL_END
