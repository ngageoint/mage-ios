//
//  CacheActiveSwitch.h
//  MAGE
//
//  Created by Brian Osborn on 1/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CacheOverlay.h"

@interface CacheActiveSwitch : UISwitch

@property (nonatomic, strong) CacheOverlay * overlay;

@end
