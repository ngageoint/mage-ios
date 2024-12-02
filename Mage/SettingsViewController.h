//
//  MainSettingsViewController.h
//  MAGE
//
//  Created by William Newman on 11/7/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@interface SettingsViewController : UISplitViewController

@property (nonatomic, assign) BOOL dismissable;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;

@end
