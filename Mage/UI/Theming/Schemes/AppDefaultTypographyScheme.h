//
//  AppDefaultTypographyScheme.h
//  MAGE
//
//  Created by Brent Michalski on 6/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol AppTypographyScheming

@property (nonatomic, readonly) UIFont *headline1Font;
@property (nonatomic, readonly) UIFont *headline2Font;
@property (nonatomic, readonly) UIFont *headline3Font;
@property (nonatomic, readonly) UIFont *headline4Font;
@property (nonatomic, readonly) UIFont *headline5Font;
@property (nonatomic, readonly) UIFont *headline6Font;
@property (nonatomic, readonly) UIFont *subtitle1Font;
@property (nonatomic, readonly) UIFont *subtitle2Font;
@property (nonatomic, readonly) UIFont *captionFont;
@property (nonatomic, readonly) UIFont *headlineFont;
@property (nonatomic, readonly) UIFont *bodyFont;
@property (nonatomic, readonly) UIFont *buttonFont;

@end


@interface AppDefaultTypographyScheme : NSObject <AppTypographyScheming>
@end

