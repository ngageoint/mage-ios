//
//  FadeTransitionSegue.m
//  MAGE
//
//  Created by Dan Barela on 9/8/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FadeTransitionSegue.h"

@implementation FadeTransitionSegue

+ (void) addFadeTransitionToView: (UIView *) view {
    CATransition *transition = [CATransition animation];
    transition.duration = .3f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [view.layer addAnimation:transition forKey:nil];
}

@end
