//
//  LoginGovLoginView.m
//  MAGE
//
//  Created by Dan Barela on 4/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocalLoginView.h"
#import "Theme+UIResponder.h"
#import "DeviceUUID.h"

@import SkyFloatingLabelTextField;
@import HexColors;

@interface LocalLoginView() <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *usernameField;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupDescription;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *signupContainerView;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;
@property (strong, nonatomic) UIFont *passwordFont;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation LocalLoginView

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.usernameField.textColor = self.scheme.colorScheme.primaryColor;
    self.usernameField.selectedLineColor = self.scheme.colorScheme.primaryColor;
    self.usernameField.selectedTitleColor = self.scheme.colorScheme.primaryColor;
    self.usernameField.placeholderColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.disabledColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.lineColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.titleColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.usernameField.errorColor = self.scheme.colorScheme.errorColor;
    self.usernameField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.usernameField.iconText = @"\U0000f007";
    
    self.passwordField.textColor = self.scheme.colorScheme.primaryColor;
    self.passwordField.selectedLineColor = self.scheme.colorScheme.primaryColor;
    self.passwordField.selectedTitleColor = self.scheme.colorScheme.primaryColor;
    self.passwordField.placeholderColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.disabledColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.lineColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.titleColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.errorColor = self.scheme.colorScheme.errorColor;
    self.passwordField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.passwordField.iconText = @"\U0000f084";
    
    self.loginButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.showPasswordLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.signupDescription.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    [self.signupButton setTitleColor:self.scheme.colorScheme.primaryColor forState:UIControlStateNormal];
    self.showPassword.onTintColor = self.scheme.colorScheme.primaryColorVariant;
}

- (void) themeDidChange:(MageTheme)theme {

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
    self.passwordFont = self.passwordField.font;
    [self.usernameField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    [self.passwordField setDelegate:self];
    if (self.user) {
        self.usernameField.enabled = NO;
        self.usernameField.text = self.user.username;
        self.signupContainerView.hidden = YES;
    }

    [self applyThemeWithContainerScheme:self.scheme];
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
    NSLog(@"login parameters %@", parameters);
    __weak __typeof__(self) weakSelf = self;
    [self.delegate loginWithParameters:parameters withAuthenticationType: SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
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
}

- (IBAction)signupTapped:(id)sender {
    [self.delegate createAccount];
}

@end

