//
//  MageInitialViewController.m
//  Mage
//
//  Created by Dan Barela on 7/15/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MageInitialViewController.h"
#import <UserUtility.h>
#import <HttpManager.h>

@interface MageInitialViewController ()

@end

@implementation MageInitialViewController

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
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    UIImageView *gradientView = [[UIImageView alloc] initWithFrame:self.view.frame];
    gradientView.image = gradientImage;
    [self.view insertSubview:gradientView atIndex:0];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // if the token is not expired skip the login module
    if (![UserUtility isTokenExpired]) {
        [[HttpManager singleton].manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [defaults stringForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
		[self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:nil];
    } else {
		[self performSegueWithIdentifier:@"DisplayDisclaimerViewSegue" sender:nil];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"DisplayDisclaimerViewSegue"]) {
        id destinationController = [segue destinationViewController];
		[destinationController setManagedObjectContext:_managedObjectContext];
    } else if ([segueIdentifier isEqualToString:@"DisplayRootViewSegue"]) {
        id destinationController = [segue destinationViewController];
		[destinationController setManagedObjectContext:_managedObjectContext];
    }
}

- (IBAction)unwindToInitial:(UIStoryboardSegue *)unwindSegue {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"token"];
    [defaults removeObjectForKey:@"tokenExpirationDate"];
    [defaults removeObjectForKey:@"disclaimerAccepted"];
}

@end
