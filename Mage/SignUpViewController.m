//
//  SignUpViewController.m
//  Mage
//
//  Created by Billy Newman on 8/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SignUpViewController.h"
#import "UINextField.h"
#import "HttpManager.h"

@interface SignUpViewController ()
    @property (weak, nonatomic) UITextField *activeField;
    @property (weak, nonatomic) IBOutlet UIView *contentView;
@end

@implementation SignUpViewController

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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *url = [defaults URLForKey:@"serverUrl"];
	NSString *urlText = url != nil ? [url absoluteString] : @"";
    [_serverUrl setText:urlText];
}

-(void) viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[UINextField class]]) {
        [[(UINextField *)textField nextField] becomeFirstResponder];
    }
    
    return YES;
    
}

- (IBAction)toggleUrlField:(id)sender {
    UIButton * button = (UIButton *)sender;
    if (_serverUrl.enabled) {
        [_serverUrl setEnabled:NO];
        button.selected = NO;
    } else {
        // TODO make /api request here before allowing lock
        
        [_serverUrl setEnabled:YES];
        button.selected = YES;
    }
}


- (void)textFieldDidBeginEditing:(UITextField *) textField {
    self.activeField = textField;
}

- (IBAction)textFieldDidEndEditing:(UITextField *) textField {
    self.activeField = nil;
}

- (void) keyboardDidShow:(NSNotification *) notification {
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect fromView:nil];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, _activeField.frame.origin) ) {
        [_scrollView scrollRectToVisible:_activeField.frame animated:YES];
    }
}

- (void) keyboardWillBeHidden:(NSNotification *) notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}

- (IBAction) onSignup:(id) sender {
    if ([_username.text length] == 0) {
        [self showDialogForRequiredField:@"username"];
    } else if ([_firstName.text length] == 0) {
        [self showDialogForRequiredField:@"First Name"];
    } else if ([_lastName.text length] == 0) {
        [self showDialogForRequiredField:@"Last Name"];
    } else if ([_serverUrl.text length] == 0) {
        [self showDialogForRequiredField:@"Server URL"];
    } else if ([_password.text length] == 0) {
        [self showDialogForRequiredField:@"password"];
    } else if (![_password.text isEqualToString:_passwordConfirm.text]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"Passwords do not match"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        // All fields validated
        NSDictionary *parameters = @{
            @"username": [_username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"firstname": [_firstName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"lastname": [_lastName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"email": [_email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"password": [_password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"passwordconfirm": [_passwordConfirm.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
        };
        
        
        [self signupWithParameters:parameters url:[_serverUrl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
}

- (void) showDialogForRequiredField:(NSString *) field {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Missing required field"
                          message:[NSString stringWithFormat:@"'%@' is required.", field]
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
	
	[alert show];
}

- (void) signupWithParameters:(NSDictionary *) parameters url:(NSString *) baseUrl {
    NSString *url = [NSString stringWithFormat:@"%@/%@", baseUrl, @"api/users"];
    [[HttpManager singleton].manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
		NSString *username = [response objectForKey:@"username"];
        NSString *firstName = [response objectForKey:@"firstname"];
		NSString *lastName = [response objectForKey:@"lastname"];
		
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"User Creation Success"
                              message:[NSString stringWithFormat:@"%@ %@ (%@) has been successfully created.  An administrator must approve your account before you can login", firstName, lastName, username]
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"User Creation Failed"
                              message:[operation responseString]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    }];
}

- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self performSegueWithIdentifier:@"unwindToInitialViewSegue" sender:self];
    }
}


@end
