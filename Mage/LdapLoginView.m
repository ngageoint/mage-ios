//
//  LdapLoginView.m
//  MAGE
//
//  Created by William Newman on 6/18/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LdapLoginView.h"
#import "Theme+UIResponder.h"
#import "DeviceUUID.h"
#import "AuthenticationButton.h"

@import SkyFloatingLabelTextField;
@import HexColors;

@interface LdapLoginView() <UITextFieldDelegate, AuthenticationButtonDelegate>

@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *usernameField;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;
@property (weak, nonatomic) IBOutlet AuthenticationButton *authenticationButton;
@property (strong, nonatomic) UIFont *passwordFont;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation LdapLoginView

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    self.usernameField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.usernameField.selectedLineColor = self.scheme.colorScheme.primaryColorVariant;
    self.usernameField.selectedTitleColor = self.scheme.colorScheme.primaryColorVariant;
    self.usernameField.placeholderColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.disabledColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.lineColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.titleColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.errorColor = self.scheme.colorScheme.errorColor;
    self.usernameField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.usernameField.iconText = @"\U0000f007";
    
    self.passwordField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.passwordField.selectedLineColor = self.scheme.colorScheme.primaryColorVariant;
    self.passwordField.selectedTitleColor = self.scheme.colorScheme.primaryColorVariant;
    self.passwordField.placeholderColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.disabledColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.lineColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.titleColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.errorColor = self.scheme.colorScheme.errorColor;
    self.passwordField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.passwordField.iconText = @"\U0000f084";
    
    self.showPasswordLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
}

- (void) didMoveToSuperview {
    self.authenticationButton.strategy = self.strategy;
    self.authenticationButton.delegate = self;
    
    self.passwordFont = self.passwordField.font;
    [self.usernameField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    [self.passwordField setDelegate:self];
    if (self.user) {
        self.usernameField.enabled = NO;
        self.usernameField.text = self.user.username;
    }
    self.statusView.hidden = YES;
    
    NSDictionary *strategy = [self.strategy objectForKey:@"strategy"];
    
    NSString *title = [strategy objectForKey:@"title"];
    self.usernameField.placeholder = [NSString stringWithFormat:@"%@ Username", title];
    self.passwordField.placeholder = [NSString stringWithFormat:@"%@ Password", title];
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
        [self onAuthenticationButtonTapped:textField];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *updatedString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // if we override this we need to check if its \n
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
    } else {
        textField.text = updatedString;
    }
    
    self.usernameField.textColor = self.passwordField.textColor = [UIColor primaryText];
    
    return NO;
}

- (IBAction)showPasswordSwitchAction:(id)sender {
    [self.passwordField setSecureTextEntry:!self.passwordField.secureTextEntry];
    self.passwordField.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.passwordField.font = nil;
    self.passwordField.font = [UIFont systemFontOfSize:14];
}

//  When we are done editing on the keyboard
- (IBAction)resignAndLogin:(id) sender {
    if (![self changeTextViewFocus: sender]) {
        [sender resignFirstResponder];
        [self verifyLogin];
    }
}

- (void) onAuthenticationButtonTapped:(id) sender {
    if (![self changeTextViewFocus: sender]) {
        //        [sender resignFirstResponder];
        if ([self.usernameField isFirstResponder]) {
            [self.usernameField resignFirstResponder];
        } else if([self.passwordField isFirstResponder]) {
            [self.passwordField resignFirstResponder];
        }
        
        [self verifyLogin];
    }
}

- (void) endLogin {
//    [self.loginView setEnabled:YES];
    [self.activityIndicator stopAnimating];
    [self.usernameField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    [self.showPassword setEnabled:YES];
}

- (void) startLogin {
//    [self.loginButton setEnabled:NO];
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
    [self.delegate loginWithParameters:parameters withAuthenticationType:LDAP complete:^(AuthenticationStatus authenticationStatus, NSString *message) {
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
    self.usernameField.errorMessage = nil;
    self.passwordField.errorMessage = nil;
    
    if (clear) {
        [self.usernameField setText:@""];
        [self.passwordField setText:@""];
    }
    
    self.statusView.hidden = YES;
}

@end
