//
//  DisclaimerNavigationController.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import "DisclaimerNavigationController.h"

@implementation DisclaimerNavigationController

-(void) viewWillAppear:(BOOL)animate {
    [super viewWillAppear:animate];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:82.0/255.0 green:120.0/255.0 blue:162.0/255.0 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:27.0/255.0 green:64.0/255.0 blue:105.0/25.0 alpha:1.0] CGColor], nil];
    
    CGGradientRef gradient;
    gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), (CFArrayRef)colors, NULL);
    CGPoint startPoint;
    startPoint.x = self.view.frame.size.width/2;
    startPoint.y = self.view.frame.size.height/2;
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, startPoint, 0, startPoint, 5000, 0);
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	int largestSide = self.view.frame.size.height > self.view.frame.size.width ? self.view.frame.size.height : self.view.frame.size.width;
	UIImageView *gradientView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, largestSide, largestSide)];
    gradientView.image = gradientImage;
    [self.view insertSubview:gradientView atIndex:0];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"DisplayLoginSegue"]) {
        id destinationController = [segue destinationViewController];
		[destinationController setManagedObjectContext:_managedObjectContext];
        [destinationController setLocationFetchService:_locationFetchService];
    }
}

@end
