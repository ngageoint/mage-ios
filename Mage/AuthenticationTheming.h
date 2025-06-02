//
//  AuthenticationTheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/2/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AuthenticationTheming <NSObject>
@property (nonatomic, strong, readonly) UIColor *surfaceColor;
@property (nonatomic, strong, readonly) UIColor *onSurfaceColor;
@end
