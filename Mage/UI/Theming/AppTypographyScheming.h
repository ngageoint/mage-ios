//
//  AppTypographyScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppTypographyScheming <NSObject>
@property (nonatomic, strong, readonly) UIFont *headlineFont;
@property (nonatomic, strong, readonly) UIFont *bodyFont;
@property (nonatomic, strong, readonly) UIFont *subtitleFont;
@property (nonatomic, strong, readonly) UIFont *buttonFont;
@end
