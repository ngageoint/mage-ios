//
//  OnlineMapTableViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MDCContainerScheme.h>

NS_ASSUME_NONNULL_BEGIN

@interface OnlineMapTableViewController : UITableViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end

NS_ASSUME_NONNULL_END
