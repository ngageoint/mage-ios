//
//  LeftToRightSeque.m
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "LeftToRightSeque.h"
#import <QuartzCore/QuartzCore.h>

@implementation LeftToRightSeque

-(void)perform {
    
    UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
    UIViewController *destinationController = (UIViewController*)[self destinationViewController];
    
    CATransition* transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom

    [sourceViewController.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    
    [sourceViewController.navigationController pushViewController:destinationController animated:NO];
    
}

@end
