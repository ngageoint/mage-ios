//
//  LocalLoginView.m
//  MAGE
//
//  Created by Dan Barela on 4/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocalLoginView.h"
#import <PureLayout/PureLayout.h>
#import "MAGE-Swift.h"

@interface LocalLoginView () <UITextFieldDelegate>

// MARK: - IBOutlets
@property (weak, nonatomic) IBOutlet ThemedTextField *usernameField;
@property (weak, nonatomic) IBOutlet ThemedTextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupDescription;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIView *signupContainerView;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;

// MARK: - Root view outlet (must be wired to the File’s Owner view)
@property (weak, nonatomic) IBOutlet UIView *view;

@property (strong, nonatomic) id<AppContainerScheming> scheme;

@end

@implementation LocalLoginView

#pragma mark - Nib Loading (Static)

+ (instancetype)loadFromNib {
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"local-authView" owner:nil options:nil];
    for (id view in nibViews) {
        if ([view isKindOfClass:[self class]]) {
            return view;
        }
    }
    return nil;
}

#pragma mark - Theming

- (void)applyThemeWithScheme:(id<AppContainerScheming>)containerScheme {
    if (containerScheme == nil) return;
    self.scheme = containerScheme;

    self.showPasswordLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.signupDescription.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.showPassword.onTintColor = self.scheme.colorScheme.primaryColorVariant;
    [self.signupButton setTitleColor:[self.scheme.colorScheme.primaryColorVariant colorWithAlphaComponent:0.6] forState:UIControlStateNormal];
}

#pragma mark - View Lifecycle

- (void)didMoveToSuperview {
    [self.signupButton setTitle:@"Sign Up Here" forState:UIControlStateNormal];
    [self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];

    UIImageView *meImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"person.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.usernameField setLeftView:meImage];
    self.usernameField.leftViewMode = UITextFieldViewModeAlways;
    self.usernameField.accessibilityLabel = @"Username";
    self.usernameField.placeholder = @"Username";
    self.usernameField.text = @"Username";
    [self.usernameField sizeToFit];

    self.passwordField.accessibilityLabel = @"Password";
    UIImageView *keyImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.passwordField setLeftView:keyImage];
    self.passwordField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordField.placeholder = @"Password";
    self.passwordField.text = @"Password";
    [self.passwordField sizeToFit];

    self.usernameField.enabled = YES;
    self.passwordField.enabled = YES;
    self.passwordField.delegate = self;

    if (self.user) {
        self.usernameField.enabled = NO;
        self.usernameField.text = self.user.username;
        self.signupContainerView.hidden = YES;
    }

    self.backgroundColor = UIColor.yellowColor;
}

#pragma mark - Login Logic

- (BOOL)changeTextViewFocus:(id)sender {
    if ([[self.usernameField text] isEqualToString:@""]) {
        [self.usernameField becomeFirstResponder];
        return YES;
    } else if ([[self.passwordField text] isEqualToString:@""]) {
        [self.passwordField becomeFirstResponder];
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.passwordField) {
        [self signInTapped:textField];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (IBAction)showPasswordSwitchAction:(id)sender {
    self.passwordField.secureTextEntry = !self.passwordField.secureTextEntry;
    self.passwordField.clearsOnBeginEditing = NO;
}

- (IBAction)resignAndLogin:(id)sender {
    if (![self changeTextViewFocus:sender]) {
        [sender resignFirstResponder];
        [self verifyLogin];
    }
}

- (IBAction)signInTapped:(id)sender {
    if (![self changeTextViewFocus:sender]) {
        [sender resignFirstResponder];
        if ([self.usernameField isFirstResponder]) {
            [self.usernameField resignFirstResponder];
        } else if ([self.passwordField isFirstResponder]) {
            [self.passwordField resignFirstResponder];
        }
        [self verifyLogin];
    }
}

- (void)startLogin {
    self.loginButton.enabled = NO;
    self.usernameField.enabled = NO;
    self.passwordField.enabled = NO;
    self.showPassword.enabled = NO;
}

- (void)endLogin {
    self.loginButton.enabled = YES;
    self.usernameField.enabled = YES;
    self.passwordField.enabled = YES;
    self.showPassword.enabled = YES;
}

- (void)verifyLogin {
    [self startLogin];

    NSString *uidString = [DeviceUUID retrieveDeviceUUID].UUIDString;
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

    NSDictionary *parameters = @{
        @"username": self.usernameField.text ?: @"",
        @"password": self.passwordField.text ?: @"",
        @"strategy": self.strategy ?: @"",
        @"uid": uidString,
        @"appVersion": [NSString stringWithFormat:@"%@-%@", appVersion, buildNumber]
    };

    __weak typeof(self) weakSelf = self;
    [self.delegate loginWithParameters:parameters
             withAuthenticationStrategy:self.strategy[@"identifier"]
                               complete:^(AuthenticationStatus status, NSString *errorString) {
        if (status == AUTHENTICATION_SUCCESS || status == REGISTRATION_SUCCESS) {
            [weakSelf resetLogin:YES];
        } else {
            [weakSelf resetLogin:NO];
        }
        [weakSelf endLogin];
    }];
}

- (void)resetLogin:(BOOL)clear {
    if (clear) {
        self.usernameField.text = @"";
        self.passwordField.text = @"";
    }
}

- (IBAction)signupTapped:(id)sender {
    [self.delegate createAccount];
}

@end

