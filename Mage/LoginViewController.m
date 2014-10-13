//
//  LoginViewController.m
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//

#import "LoginViewController.h"
#import "LocalAuthentication.h"
#import "User+helper.h"
#import <Observation+helper.h>

#import <Location+helper.h>
#import <Layer+helper.h>
#import <Form.h>
#import "AppDelegate.h"
#import <HttpManager.h>
#import "MageRootViewController.h"
#import <UserUtility.h>
#import "DeviceUUID.h"
#import "MageServer.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

id<Authentication> _authentication;

- (void) authenticationWasSuccessful:(User *) user {
	[self performSegueWithIdentifier:@"LoginSegue" sender:nil];
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

- (void) registrationWasSuccessful {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Registration Sent"
                          message:@"Your device has been registered.  \nAn administrator has been notified to approve this device."
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
	
	[alert show];
}

- (void) verifyLogin {
	// setup authentication

    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
	NSString *uidString = deviceUUID.UUIDString;
    NSLog(@"uid: %@", uidString);
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
														 _usernameField.text, @"username",
														 _passwordField.text, @"password",
														 uidString, @"uid",
														 nil];
	
	// TODO might want to mask here or put a spinner on the login button
	[_authentication loginWithParameters: parameters];
}

- (BOOL) changeTextViewFocus: (id)sender {
    if ([[_usernameField text] isEqualToString:@""]) {
        [_usernameField becomeFirstResponder];
		return YES;
    } else if ([[_passwordField text] isEqualToString:@""]) {
        [_passwordField becomeFirstResponder];
		return YES;
    } else {
		return NO;
	}
}

- (IBAction)toggleUrlField:(id)sender {
    UIButton * button = (UIButton *)sender;
    if (_serverField.enabled) {
        [_serverField setEnabled:NO];
        button.selected = NO;
		
		// TODO need a better way to reset url
		// Problem here is that a url reset could mean a lot of things, like the authentication type changed
		NSURL *url = [NSURL URLWithString:self.serverField.text];
		_authentication = [Authentication authenticationWithType:LOCAL url:url inManagedObjectContext:self.contextHolder.managedObjectContext];
		_authentication.delegate = self;
		
        [MageServer setBaseServerUrl:[url absoluteString]];
    } else {
        [self.serverField setEnabled:YES];
        button.selected = YES;
    }
}

//  When we are done editing on the keyboard
- (IBAction)resignAndLogin:(id) sender {
    if (![self changeTextViewFocus: sender]) {
		[sender resignFirstResponder];
		[self verifyLogin];
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"LoginSegue"]) {
		if (![self changeTextViewFocus: sender]) {
			[sender resignFirstResponder];
			if ([_usernameField isFirstResponder]) {
				[_usernameField resignFirstResponder];
			} else if([_passwordField isFirstResponder]) {
				[_passwordField resignFirstResponder];
			}
			
			[self verifyLogin];
		}
		return NO;
	}

	return YES;
}

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated {
	
    [self.usernameField setText:@""];
    [self.passwordField setText:@""];
    [self.serverField setText:[[MageServer baseServerUrl] absoluteString]];
    [self.passwordField setDelegate:self];
	
	_authentication = [Authentication
					   authenticationWithType:LOCAL url:[NSURL URLWithString:_serverField.text]
					   inManagedObjectContext:self.contextHolder.managedObjectContext];
	_authentication.delegate = self;
    
}

- (void) viewDidLoad {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)showPasswordSwitchAction:(id)sender {
    [self.passwordField setSecureTextEntry:!self.passwordField.secureTextEntry];
    self.passwordField.clearsOnBeginEditing = NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *updatedString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
	// if we override this we need to check if its \n
	if ([string isEqualToString:@"\n"]) {
		[textField resignFirstResponder];
	} else {
		textField.text = updatedString;
	}
    
    return NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
