//
//  ObservationViewerViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationViewerViewController.h"

@interface ObservationViewerViewController ()

@end

@implementation ObservationViewerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    UIGraphicsBeginImageContext(self.view.bounds.size);
//    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, startPoint, 0, startPoint, 5000, 0);
//    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    
    //this is the anchor point for our gradient, in our case top left. setting it in the middle (.5, .5) will produce a radial gradient. our startPoint and endPoints are based off the anchorPoint
    
    maskLayer.anchorPoint = CGPointZero;

    
    //setting our colors - since this is a mask the color itself is irrelevant - all that matters is the alpha. A clear color will completely hide the layer we're masking, an alpha of 1.0 will completely show the masked view.
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:1.0];

    
//android:startColor="#DD111111"
//android:endColor="#00CCCCCC"
    
    //an array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)outerColor.CGColor, (id)outerColor.CGColor, (id)innerColor.CGColor, (id)innerColor.CGColor];
    
    //these are percentage points along the line defined by our startPoint and endPoint and correspond to our colors array. The gradient will shift between the colors between these percentage points.
    maskLayer.locations = @[@0.0, @0.0, @1.0, @1.0f];
    maskLayer.bounds = CGRectMake(self.map.frame.origin.x, self.map.frame.origin.y, CGRectGetWidth(self.map.bounds), CGRectGetHeight(self.map.bounds));
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(self.map.frame.origin.x, self.map.frame.origin.y, CGRectGetWidth(self.map.bounds), CGRectGetHeight(self.map.bounds))];

    view.backgroundColor = [UIColor blackColor];
    
    
    [self.view insertSubview:view belowSubview:self.map];
    self.map.layer.mask = maskLayer;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
