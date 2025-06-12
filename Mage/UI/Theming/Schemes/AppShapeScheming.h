//
//  AppShapeScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppShapeScheming <NSObject>

@property (nonatomic, readonly) CGFloat cornerRadius;
@property (nonatomic, readonly) CGFloat borderWidth;

@end
