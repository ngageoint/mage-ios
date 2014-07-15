//
//  DisclaimerNavigationController.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import "DisclaimerNavigationController.h"

@implementation DisclaimerNavigationController

-(void) viewDidAppear:(BOOL)animate {
    [super viewDidAppear:animate];
    
//    NSArray *colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:82.0/255.0 green:120.0/255.0 blue:162.0/255.0 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:27.0/255.0 green:64.0/255.0 blue:105.0/25.0 alpha:1.0] CGColor], nil];
//    
//    CGGradientRef gradient;
//    gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), (CFArrayRef)colors, NULL);
//    CGPoint startPoint;
//    startPoint.x = self.view.frame.size.width/2;
//    startPoint.y = self.view.frame.size.height/2;
//    UIGraphicsBeginImageContext(self.view.bounds.size);
//    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, startPoint, 0, startPoint, 5000, 0);
//    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    UIImageView *gradientView = [[UIImageView alloc] initWithFrame:self.view.frame];
//    gradientView.image = gradientImage;
//    [self.view insertSubview:gradientView atIndex:0];
}

@end
