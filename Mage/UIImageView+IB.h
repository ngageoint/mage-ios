//
//  UIImageView+IB.h
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (IB)

-(UIImageRenderingMode) imageRenderingMode;
- (void) setImageRenderingMode:(UIImageRenderingMode) imageRenderingMode;

@end
