//
//  LoginViewController.m
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "LoginViewController.h"
#import "LocalAuthentication.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

LocalAuthentication *authentication;

- (void) loginSuccess:(User *)token {
	[self performSegueWithIdentifier:@"LoginSegue" sender:nil];
}

- (void) loginFailure {
	// do something on failed login
}

- (void) verifyLogin {
	// setup authentication
	// TODO this is the right way to grab device uid, but we do not have registration stuff done yet
	// so for now jsut use hardcoded uid of 12345.
//	NSUUID *uid = [[UIDevice currentDevice] identifierForVendor];
//	NSString *uidString = uid.UUIDString;
	NSString *uidString = @"12345";
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
														 _usernameField.text, @"username",
														 _passwordField.text, @"password",
														 uidString, @"uid",
														 nil];
	authentication = [[LocalAuthentication alloc] initWithURL:[NSURL URLWithString:_serverField.text] andParameters:parameters];
	authentication.delegate = self;
	
	// TODO might want to mask here or put a spinner on the login button
	[authentication login];
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    [self focusOnCorrectField: sender];
	[self verifyLogin];
	
	return NO;
}

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated
{
    [_usernameField setText:@""];
    [_passwordField setText:@""];
    [_serverField setText:@"https://***REMOVED***"];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
