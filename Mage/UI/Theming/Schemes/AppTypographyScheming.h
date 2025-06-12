//
//  AppTypographyScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppTypographyScheming <NSObject>

@property (nonatomic, strong, readonly) UIFont *headline1Font;
@property (nonatomic, strong, readonly) UIFont *headline2Font;
@property (nonatomic, strong, readonly) UIFont *headline3Font;
@property (nonatomic, strong, readonly) UIFont *headline4Font;
@property (nonatomic, strong, readonly) UIFont *headline5Font;
@property (nonatomic, strong, readonly) UIFont *headline6Font;

@property (nonatomic, strong, readonly) UIFont *subtitle1Font;
@property (nonatomic, strong, readonly) UIFont *subtitle2Font;

@property (nonatomic, strong, readonly) UIFont *bodyFont;
@property (nonatomic, strong, readonly) UIFont *buttonFont;
@property (nonatomic, strong, readonly) UIFont *captionFont;

@end
