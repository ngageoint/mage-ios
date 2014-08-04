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

@interface LoginViewController ()

@end

@implementation LoginViewController

id<Authentication> _authentication;

- (void) authenticationWasSuccessful:(User *) user {
	[self performSegueWithIdentifier:@"LoginSegue" sender:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"LoginSegue"]) {
        MageRootViewController *rootViewController = [segue destinationViewController];
		rootViewController.managedObjectContext = self.managedObjectContext;
    }
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
    
    NSUUID *uid;
    #if TARGET_IPHONE_SIMULATOR
        uid = [[NSUUID alloc]initWithUUIDString:@"0cbdbd05-e99d-46b3-badd-505a31f5911f"];
    #else
        uid = [[UIDevice currentDevice] identifierForVendor];
    #endif
	NSString *uidString = uid.UUIDString;
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
		NSURL *url = [NSURL URLWithString:_serverField.text];
		_authentication = [Authentication authenticationWithType:LOCAL url:url inManagedObjectContext:_managedObjectContext];
		_authentication.delegate = self;
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setURL:url forKey:@"serverUrl"];
    } else {
        [_serverField setEnabled:YES];
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

- (IBAction)characterTypedInLoginFields:(id)sender {
    if (([[_usernameField text] length] != 0) && ([[_passwordField text] length] != 0)) {
        [_usernameField setReturnKeyType:UIReturnKeyGo];
        [_passwordField setReturnKeyType:UIReturnKeyGo];
        [sender reloadInputViews];
    } else {
        [_usernameField setReturnKeyType:UIReturnKeyNext];
        [_passwordField setReturnKeyType:UIReturnKeyNext];
        [sender reloadInputViews];
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
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

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated {
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
	NSURL *url = [defaults URLForKey:@"serverUrl"];
	NSString *urlText = url != nil ? [url absoluteString] : @"";
	
    [_usernameField setText:@""];
    [_passwordField setText:@""];
    [_serverField setText:urlText];
    [_passwordField setDelegate:self];
	
	_authentication = [Authentication
					   authenticationWithType:LOCAL url:[NSURL URLWithString:_serverField.text]
					   inManagedObjectContext:self.managedObjectContext];
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
        [self characterTypedInLoginFields:textField];
	}
    
    return NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
//	[self resignAndLogin:textField];
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
