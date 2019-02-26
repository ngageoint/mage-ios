//
//  UITableViewCell+Setting.m
//  MAGE
//
//  Created by William Newman on 2/7/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UITableViewCell+Setting.h"
#import <objc/runtime.h>

@implementation UITableViewCell (Setting)

- (void) setType:(NSNumber *) type {
    objc_setAssociatedObject(self, "_type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *) type {
    return objc_getAssociatedObject(self, "_type");
}

- (void) setInfo:(id) info {
    objc_setAssociatedObject(self, "_info", info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id) info {
    return objc_getAssociatedObject(self, "_info");
}

@end
