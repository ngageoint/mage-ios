//
//  LoginViewController.m
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "LoginViewController.h"
#import "LocalAuthentication.h"
#import "User+helper.h"
#import <Observation+helper.h>
#import <LocationResource.h>
#import <UserResource.h>


#import <Location+helper.h>
#import <Layer+helper.h>
#import <Form.h>
#import "AppDelegate.h"
#import <HttpManager.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

id<Authentication> _authentication;

- (NSManagedObjectContext *) managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
	
    return context;
}

- (void) authenticationWasSuccessful:(User *) user {
    [self communicationTesting];
	[self performSegueWithIdentifier:@"LoginSegue" sender:nil];
}

- (void) communicationTesting {
    HttpManager *http = [HttpManager singleton];
	NSManagedObjectContext *context = ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    
    NSOperation* layerOp = [Layer fetchFeatureLayersFromServerWithManagedObjectContext:context];
    
//    NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"block operation going");
//        NSOperation* formOp = [Form fetchFormInUseOperation];
//        NSOperation* observationOp = [Observation fetchObservationsFromServerWithManagedObjectContext:context];
//        [observationOp addDependency:formOp];
//        [http.manager.operationQueue addOperations:@[formOp, observationOp] waitUntilFinished: NO];
//    }];
    
//    NSBlockOperation *blockOp = [NSBlockOperation new];
//    
//    [blockOp addExecutionBlock:^{
//        NSLog(@"block operation going");
//        NSOperation* formOp = [Form fetchFormInUseOperation];
//        NSOperation* observationOp = [Observation fetchObservationsFromServerWithManagedObjectContext:context];
//        [observationOp addDependency:formOp];
//        [http.manager.operationQueue addOperations:@[formOp, observationOp] waitUntilFinished: NO];
//    }];
    
    //NSOperation *op = [[NSOperation alloc] init];
    
    
//    [blockOp addDependency:layerOp];
    
    
//    [layerOp setCompletionBlock:^{
//        NSLog(@"block operation going");
//        NSOperation* formOp = [Form fetchFormInUseOperation];
//        NSOperation* observationOp = [Observation fetchObservationsFromServerWithManagedObjectContext:context];
//        [observationOp addDependency:formOp];
//        [http.manager.operationQueue addOperations:@[formOp, observationOp] waitUntilFinished: NO];
//    }];

    [http.manager.operationQueue setSuspended:YES];
    NSLog(@"add the operations");

//    [http.manager.operationQueue addOperations:@[layerOp, blockOp] waitUntilFinished:NO];
    [http.manager.operationQueue addOperation:layerOp];
//    [http.manager.operationQueue addOperation:blockOp];
    [http.manager.operationQueue setSuspended:NO];
    
    NSLog(@"Told them to go");
//    
//    [UserResource fetchUsersWithManagedObjectContext:self.managedObjectContext];
//	[LocationResource fetchLocationsWithManagedObjectContext:self.managedObjectContext];
}

- (void) authenticationHadFailure {
	// do something on failed login
	UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Login failure"
                          message:@"The username or password you entered is incorrect"
                          delegate:nil
                          cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil];
	
	[alert show];
}

- (void) verifyLogin {
	// setup authentication
	// TODO this is the right way to grab device uid, but we do not have registration stuff done yet
	// so for now just use hardcoded uid of 12345.
//	NSUUID *uid = [[UIDevice currentDevice] identifierForVendor];
//	NSString *uidString = uid.UUIDString;
	NSString *uidString = @"12345";
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
														 _usernameField.text, @"username",
														 _passwordField.text, @"password",
														 uidString, @"uid",
														 nil];

	
	// TODO might want to mask here or put a spinner on the login button
	[_authentication loginWithParameters: parameters];
}

- (void) focusOnCorrectField: (id)sender {
    if ([[_usernameField text] isEqualToString:@""]) {
        [_usernameField becomeFirstResponder];
    } else {
        [_passwordField becomeFirstResponder];
    }
}

- (IBAction)toggleUrlField:(id)sender {
    UIButton * button = (UIButton *)sender;
    if (_serverField.enabled) {
        [_serverField setEnabled:NO];
        button.selected = NO;
		
		// TODO need a better way to reset url
		// Problem here is that a url reset could mean a lot of things, like the authentication type changed
		NSURL *url = [NSURL URLWithString:_serverField.text];
		_authentication = [Authentication authenticationWithType:LOCAL url:url inManagedObjectContext:self.managedObjectContext];
		_authentication.delegate = self;
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setURL:url forKey:@"serverUrl"];
    } else {
        [_serverField setEnabled:YES];
        button.selected = YES;
    }
}

//  When we are done editing on the keyboard
- (IBAction)resignAndLogin:(id)sender
{
    [self focusOnCorrectField: sender];
		[self verifyLogin];
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    [self focusOnCorrectField: sender];
	[self verifyLogin];
	
	return NO;
}

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *url = [defaults URLForKey:@"serverUrl"];
	NSString *urlText = url != nil ? [url absoluteString] : @"";
	
    [_usernameField setText:@""];
    [_passwordField setText:@""];
    [_serverField setText:urlText];
	
	_authentication = [Authentication
					   authenticationWithType:LOCAL url:[NSURL URLWithString:_serverField.text]
					   inManagedObjectContext:self.managedObjectContext];
	_authentication.delegate = self;
}

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

-(void)viewDidAppear:(BOOL)animated
{
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
