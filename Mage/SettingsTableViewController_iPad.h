//
//  SettingsTableViewController_iPad.h
//  MAGE
//
//  Created by William Newman on 10/6/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ManagedObjectContextHolder.h"

@protocol SettingSelectionDelegate <NSObject>
@required
-(void) selectedSetting:(NSString *) storyboardId;
@end

@interface SettingsTableViewController_iPad : UITableViewController<CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;

@property(nonatomic, weak) id<SettingSelectionDelegate> settingSelectionDelegate;

@end
