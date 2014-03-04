//
//  LoginViewController.m
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (BOOL) verifyLogin {
    NSString *username = [_usernameField text];
    NSString *password = [_passwordField text];
    
    if ([username isEqualToString:@"drbarela"] && [password isEqualToString:@"derp"]) {
        // good to go
        return TRUE;
    }
    return FALSE;
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
    if ([self verifyLogin]) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:sender];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    [self focusOnCorrectField: sender];
    return [self verifyLogin];
}

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated
{
    [_usernameField setText:@""];
    [_passwordField setText:@""];
    [_serverField setText:@"http://***REMOVED***"];
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
