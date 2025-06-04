//
//  LoginGovLoginView.m
//  MAGE
//
//  Created by Dan Barela on 4/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocalLoginView.h"
#import <PureLayout/PureLayout.h>
#import "MAGE-Swift.h"
@import MaterialComponents;
#import "AuthenticationTheming.h"

@interface LocalLoginView() <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet MDCFilledTextField *usernameField;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupDescription;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *signupContainerView;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;

//@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) id<AuthenticationTheming> theme;
@end

@implementation LocalLoginView

- (void) applyTheme:(id<AuthenticationTheming>)authenticationTheme {
    if (authenticationTheme == nil) return;
    self.theme = authenticationTheme;
//    [self.usernameField applyThemeWithScheme:authenticationTheme];
//    [self.passwordField applyThemeWithScheme:authenticationTheme];
    
    self.usernameField.leadingView.tintColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.leadingView.tintColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
    
    self.showPasswordLabel.textColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.signupDescription.textColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
    
//    self.showPassword.onTintColor = self.theme.primaryColorVariant;
//    [self.loginButton applyContainedThemeWithScheme:self.theme];
//    [self.signupButton applyTextThemeWithScheme:self.theme];
//    [self.signupButton setTitleColor:[self.theme.primaryColorVariant colorWithAlphaComponent:0.6] forState:UIControlStateNormal];
}

- (id) init {
    self = [self viewFromNib];
    return self;
}

- (id)viewFromNib {
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"local-authView" owner:self options:nil];
    UIView *view = [nibViews objectAtIndex:0];
    return view;
}

- (void) didMoveToSuperview {
    [self.signupButton setTitle:@"Sign Up Here" forState:UIControlStateNormal];
    [self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
    UIImageView *meImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"person.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.usernameField setLeadingView:meImage];
    self.usernameField.leadingViewMode = UITextFieldViewModeAlways;
    self.usernameField.accessibilityLabel = @"Username";
    self.usernameField.placeholder = @"Username";
    self.usernameField.label.text = @"Username";
    [self.usernameField sizeToFit];
    self.passwordField.accessibilityLabel = @"Password";
    UIImageView *keyImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.passwordField setLeadingView:keyImage];
    self.passwordField.leadingViewMode = UITextFieldViewModeAlways;
    self.passwordField.placeholder = @"Password";
    self.passwordField.label.text = @"Password";
    [self.passwordField sizeToFit];
    [self.usernameField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    [self.passwordField setDelegate:self];
    if (self.user) {
        self.usernameField.enabled = NO;
        self.usernameField.text = self.user.username;
        self.signupContainerView.hidden = YES;
    }

    [self applyTheme:self.theme];
}

- (BOOL) changeTextViewFocus: (id)sender {
    if ([[self.usernameField text] isEqualToString:@""]) {
        [self.usernameField becomeFirstResponder];
        return YES;
    } else if ([[self.passwordField text] isEqualToString:@""]) {
        [self.passwordField becomeFirstResponder];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    if (textField == self.passwordField) {
        [self signInTapped:textField];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {    
    // if we override this we need to check if its \n
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (IBAction)showPasswordSwitchAction:(id)sender {
    [self.passwordField setSecureTextEntry:!self.passwordField.secureTextEntry];
    self.passwordField.clearsOnBeginEditing = NO;
}

//  When we are done editing on the keyboard
- (IBAction)resignAndLogin:(id) sender {
    if (![self changeTextViewFocus: sender]) {
        [sender resignFirstResponder];
        [self verifyLogin];
    }
}

- (IBAction)signInTapped:(id)sender {
    if (![self changeTextViewFocus: sender]) {
        [sender resignFirstResponder];
        if ([self.usernameField isFirstResponder]) {
            [self.usernameField resignFirstResponder];
        } else if([self.passwordField isFirstResponder]) {
            [self.passwordField resignFirstResponder];
        }
        
        [self verifyLogin];
    }
}

- (void) endLogin {
    [self.loginButton setEnabled:YES];
    [self.activityIndicator stopAnimating];
    [self.usernameField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    [self.showPassword setEnabled:YES];
}

- (void) startLogin {
    [self.loginButton setEnabled:NO];
    [self.activityIndicator startAnimating];
    [self.usernameField setEnabled:NO];
    [self.passwordField setEnabled:NO];
    [self.showPassword setEnabled:NO];
}

- (void) verifyLogin {
    [self startLogin];
    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
    NSString *uidString = deviceUUID.UUIDString;
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey: @"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.usernameField.text, @"username",
                                self.passwordField.text, @"password",
                                self.strategy, @"strategy",
                                uidString, @"uid",
                                [NSString stringWithFormat:@"%@-%@", appVersion, buildNumber], @"appVersion",
                                nil];
    __weak __typeof__(self) weakSelf = self;
    [self.delegate loginWithParameters:parameters withAuthenticationStrategy:[self.strategy objectForKey:@"identifier"] complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf resetLogin:YES];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf resetLogin:NO];
        } else if (authenticationStatus == UNABLE_TO_AUTHENTICATE) {
            [weakSelf resetLogin:NO];
        }
        
        [weakSelf endLogin];
    }];
}

- (void) resetLogin: (BOOL) clear {
    
    if (clear) {
        [self.usernameField setText:@""];
        [self.passwordField setText:@""];
    }
}

- (IBAction)signupTapped:(id)sender {
    [self.delegate createAccount];
}

@end

